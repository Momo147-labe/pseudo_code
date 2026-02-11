import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pseudo_code/providers/graph_provider.dart';
import 'package:pseudo_code/providers/theme_provider.dart';
import 'package:pseudo_code/theme.dart';
import 'package:pseudo_code/models/graph/graph_models.dart';
import 'package:pseudo_code/services/graph/dijkstra_service.dart';

class GraphCanvas extends StatefulWidget {
  const GraphCanvas({super.key});

  @override
  State<GraphCanvas> createState() => GraphCanvasState();
}

class GraphCanvasState extends State<GraphCanvas> {
  final TransformationController _transformationController =
      TransformationController();
  String? _connectingNodeId;
  Offset? _connectionEnd;
  String? _draggedNodeId;
  Offset? _longPressStartPos;
  MouseCursor _currentCursor = SystemMouseCursors.grab;
  final GlobalKey _canvasKey = GlobalKey(); // [NEW] Pour l'export PNG

  // Lasso Selection
  Offset? _lassoStart;
  Offset? _lassoEnd;

  GraphProvider? _graphProvider; // [NEW FIELD]

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _graphProvider = context.read<GraphProvider>();
      _graphProvider?.addListener(_onProviderChanged);
    });
  }

  @override
  void dispose() {
    _graphProvider?.removeListener(_onProviderChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    final provider = context.read<GraphProvider>();
    if (provider.resetViewRequested) {
      _transformationController.value = Matrix4.identity();
      provider.consumeResetView();
    }
    if (provider.zoomRequest != 0) {
      final double factor = provider.zoomRequest;
      final Matrix4 current = _transformationController.value;
      _transformationController.value =
          current * Matrix4.diagonal3Values(factor, factor, 1.0);
      provider.consumeZoomRequest();
    }
  }

  Future<void> exportToPNG() async {
    try {
      final boundary =
          _canvasKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Sauvegarder le graphe en PNG',
        fileName: 'graphe.png',
        type: FileType.custom,
        allowedExtensions: ['png'],
      );

      if (outputFile != null) {
        if (!outputFile.endsWith('.png')) outputFile += '.png';
        final file = File(outputFile);
        await file.writeAsBytes(pngBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Image exportée : $outputFile")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur d'export : $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GraphProvider>();
    final theme = context.watch<ThemeProvider>().currentTheme;

    return MouseRegion(
      cursor: _currentCursor,
      child: Stack(
        children: [
          DragTarget<String>(
            onAcceptWithDetails: (details) {
              if (details.data == 'new_node') {
                final RenderBox renderBox =
                    context.findRenderObject() as RenderBox;
                final localPos = renderBox.globalToLocal(details.offset);
                final scenePos = _transformationController.toScene(localPos);
                provider.addNode(scenePos);
              }
            },
            builder: (context, candidateData, rejectedData) {
              return InteractiveViewer(
                transformationController: _transformationController,
                boundaryMargin: const EdgeInsets.all(1000),
                minScale: 0.1,
                maxScale: 5.0,
                panEnabled: _lassoStart == null && _draggedNodeId == null,
                onInteractionStart: (details) {
                  if (_draggedNodeId == null && _lassoStart == null) {
                    setState(
                      () => _currentCursor = SystemMouseCursors.grabbing,
                    );
                  }
                },
                onInteractionEnd: (details) {
                  if (_currentCursor == SystemMouseCursors.grabbing) {
                    setState(() => _currentCursor = SystemMouseCursors.grab);
                  }
                },
                child: GestureDetector(
                  onTapDown: (details) {
                    final tappedNodeId = _getNodeAtPosition(
                      details.localPosition,
                      provider,
                    );

                    if (tappedNodeId != null) {
                      final isShift =
                          HardwareKeyboard.instance.logicalKeysPressed.contains(
                            LogicalKeyboardKey.shiftLeft,
                          ) ||
                          HardwareKeyboard.instance.logicalKeysPressed.contains(
                            LogicalKeyboardKey.shiftRight,
                          );
                      provider.selectNode(tappedNodeId, multi: isShift);
                    } else {
                      provider.selectNode(null);
                      setState(() {
                        _connectingNodeId = null;
                        _draggedNodeId = null;
                        _lassoStart = null;
                        _lassoEnd = null;
                      });
                    }
                  },
                  onDoubleTapDown: (details) {
                    final tappedNodeId = _getNodeAtPosition(
                      details.localPosition,
                      provider,
                    );
                    if (tappedNodeId != null) {
                      // Optionnel: action sur sommet (ex: renommer)
                      return;
                    }

                    final tappedEdgeId = _getEdgeAtPosition(
                      details.localPosition,
                      provider,
                    );
                    if (tappedEdgeId != null) {
                      final edge = provider.edges.firstWhere(
                        (e) => e.id == tappedEdgeId,
                      );
                      _showWeightDialog(context, edge, provider);
                      return;
                    }

                    // Le double-clic sur un espace vide ne crée plus de sommet
                  },
                  onPanStart: (details) {
                    final tappedNodeId = _getNodeAtPosition(
                      details.localPosition,
                      provider,
                    );
                    if (tappedNodeId != null) {
                      setState(() => _draggedNodeId = tappedNodeId);
                      provider.startNodeDrag(tappedNodeId);
                    } else {
                      final isShift =
                          HardwareKeyboard.instance.logicalKeysPressed.contains(
                            LogicalKeyboardKey.shiftLeft,
                          ) ||
                          HardwareKeyboard.instance.logicalKeysPressed.contains(
                            LogicalKeyboardKey.shiftRight,
                          );

                      if (isShift) {
                        setState(() {
                          _lassoStart = details.localPosition;
                          _lassoEnd = details.localPosition;
                        });
                      }
                    }
                  },
                  onPanUpdate: (details) {
                    if (_draggedNodeId != null) {
                      final scale = _transformationController.value
                          .getMaxScaleOnAxis();
                      final sceneDelta = details.delta / scale;

                      if (provider.selectedNodeIds.contains(_draggedNodeId)) {
                        provider.updateSelectionPosition(sceneDelta);
                      } else {
                        provider.selectNode(_draggedNodeId);
                        final scenePos = _transformationController.toScene(
                          details.localPosition,
                        );
                        provider.updateNodePosition(_draggedNodeId!, scenePos);
                      }
                    } else if (_lassoStart != null) {
                      setState(() {
                        _lassoEnd = details.localPosition;
                      });
                      final rect = Rect.fromPoints(_lassoStart!, _lassoEnd!);
                      provider.selectNodesInRect(rect);
                    }
                  },
                  onPanEnd: (details) {
                    if (_draggedNodeId != null) {
                      provider.endNodeDrag();
                    }
                    setState(() {
                      _draggedNodeId = null;
                      _lassoStart = null;
                      _lassoEnd = null;
                    });
                  },

                  onLongPressStart: (details) {
                    final tappedNodeId = _getNodeAtPosition(
                      details.localPosition,
                      provider,
                    );
                    if (tappedNodeId != null) {
                      setState(() {
                        _connectingNodeId = tappedNodeId;
                        _connectionEnd = details.localPosition;
                        _longPressStartPos = details.localPosition;
                      });
                    }
                  },
                  onLongPressMoveUpdate: (details) {
                    if (_connectingNodeId != null) {
                      setState(() => _connectionEnd = details.localPosition);
                    }
                  },
                  onLongPressEnd: (details) {
                    if (_connectingNodeId != null) {
                      final targetNodeId = _getNodeAtPosition(
                        details.localPosition,
                        provider,
                      );
                      if (targetNodeId != null &&
                          targetNodeId != _connectingNodeId) {
                        provider.addEdge(
                          _connectingNodeId!,
                          targetNodeId,
                          directed: provider.isDirected,
                        );
                      } else if (_longPressStartPos != null &&
                          (details.localPosition - _longPressStartPos!)
                                  .distance <
                              15) {
                        _showNodeMenu(
                          context,
                          details.globalPosition,
                          _connectingNodeId!,
                          provider,
                        );
                      }
                      setState(() {
                        _connectingNodeId = null;
                        _connectionEnd = null;
                        _longPressStartPos = null;
                      });
                    }
                  },
                  onSecondaryTapDown: (details) {
                    final tappedNodeId = _getNodeAtPosition(
                      details.localPosition,
                      provider,
                    );
                    if (tappedNodeId != null) {
                      _showNodeMenu(
                        context,
                        details.globalPosition,
                        tappedNodeId,
                        provider,
                      );
                      return;
                    }

                    final tappedEdgeId = _getEdgeAtPosition(
                      details.localPosition,
                      provider,
                    );
                    if (tappedEdgeId != null) {
                      _showEdgeMenu(
                        context,
                        details.globalPosition,
                        tappedEdgeId,
                        provider,
                      );
                    }
                  },
                  child: RepaintBoundary(
                    key: _canvasKey,
                    child: Container(
                      width: 5000,
                      height: 5000,
                      color: Colors.transparent,
                      child: CustomPaint(
                        painter: GraphPainter(
                          nodes: provider.nodes,
                          edges: provider.edges,
                          selectedNodeIds: provider.selectedNodeIds,
                          connectingNodeId: _connectingNodeId,
                          visitedNodes: provider.visitedNodes,
                          activeEdgeId: provider.activeEdgeId,
                          theme: theme,
                          connectionEnd: _connectionEnd,
                          lassoRect: _lassoStart != null && _lassoEnd != null
                              ? Rect.fromPoints(_lassoStart!, _lassoEnd!)
                              : null,
                          showGrid: provider.snapToGrid,
                          startNodeId: provider.startNodeId,
                          endNodeId: provider.endNodeId,
                          dijkstraResult: provider.dijkstraResult,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: _MiniMap(provider: provider, theme: theme),
          ),
        ],
      ),
    );
  }

  String? _getNodeAtPosition(Offset pos, GraphProvider provider) {
    for (final node in provider.nodes) {
      if ((node.position - pos).distance < 25) {
        return node.id;
      }
    }
    return null;
  }

  String? _getEdgeAtPosition(Offset pos, GraphProvider provider) {
    for (final edge in provider.edges) {
      final from = provider.nodes
          .firstWhere((n) => n.id == edge.fromId)
          .position;
      final to = provider.nodes.firstWhere((n) => n.id == edge.toId).position;

      // Distance point à segment
      final double distance = _distanceToSegment(pos, from, to);
      if (distance < 10) {
        return edge.id;
      }
    }
    return null;
  }

  double _distanceToSegment(Offset p, Offset v, Offset w) {
    final l2 = (v - w).distanceSquared;
    if (l2 == 0) return (p - v).distance;
    final t =
        ((p.dx - v.dx) * (w.dx - v.dx) + (p.dy - v.dy) * (w.dy - v.dy)) / l2;
    if (t < 0) return (p - v).distance;
    if (t > 1) return (p - w).distance;
    return (p - Offset(v.dx + t * (w.dx - v.dx), v.dy + t * (w.dy - v.dy)))
        .distance;
  }

  void _showNodeMenu(
    BuildContext context,
    Offset position,
    String nodeId,
    GraphProvider provider,
  ) {
    final node = provider.nodes.firstWhere((n) => n.id == nodeId);
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'start',
          child: Row(
            children: [
              const Icon(Icons.play_circle_fill, size: 18, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                node.id == provider.startNodeId
                    ? "Retirer Départ"
                    : "Définir comme Départ",
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'end',
          child: Row(
            children: [
              const Icon(Icons.stop_circle, size: 18, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                node.id == provider.endNodeId
                    ? "Retirer Arrivée"
                    : "Définir comme Arrivée",
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              const Icon(Icons.edit, size: 18),
              const SizedBox(width: 8),
              Text("Renommer (${node.label})"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'bfs',
          child: Row(
            children: [
              Icon(Icons.play_arrow, size: 18, color: Colors.green),
              SizedBox(width: 8),
              Text("Lancer BFS"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text("Supprimer"),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'start') {
        provider.setStartNode(node.id == provider.startNodeId ? null : nodeId);
      } else if (value == 'end') {
        provider.setEndNode(node.id == provider.endNodeId ? null : nodeId);
      } else if (value == 'bfs') {
        provider.runBFS(nodeId);
      } else if (value == 'delete') {
        provider.removeNode(nodeId);
      } else if (value == 'rename') {
        _showRenameDialog(context, node, provider);
      }
    });
  }

  void _showEdgeMenu(
    BuildContext context,
    Offset position,
    String edgeId,
    GraphProvider provider,
  ) {
    final edge = provider.edges.firstWhere((e) => e.id == edgeId);
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'weight',
          child: Row(
            children: [
              const Icon(Icons.line_weight, size: 18),
              const SizedBox(width: 8),
              Text("Changer poids (${edge.weight})"),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'direction',
          child: Row(
            children: [
              const Icon(Icons.swap_calls, size: 18),
              const SizedBox(width: 8),
              Text(edge.directed ? "Rendre bi-directionnel" : "Rendre orienté"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text("Supprimer"),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'weight') {
        _showWeightDialog(context, edge, provider);
      } else if (value == 'direction') {
        provider.toggleEdgeDirection(edgeId);
      } else if (value == 'delete') {
        provider.removeEdge(edgeId);
      }
    });
  }

  void _showRenameDialog(
    BuildContext context,
    GraphNode node,
    GraphProvider provider,
  ) {
    final controller = TextEditingController(text: node.label);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Renommer le sommet"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: "Nouveau nom"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              provider.updateNodeLabel(node.id, controller.text);
              Navigator.pop(context);
            },
            child: const Text("Valider"),
          ),
        ],
      ),
    );
  }

  void _showWeightDialog(
    BuildContext context,
    GraphEdge edge,
    GraphProvider provider,
  ) {
    final controller = TextEditingController(text: edge.weight.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Changer le poids"),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Poids"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              final weight = double.tryParse(controller.text);
              if (weight != null) {
                provider.updateEdgeWeight(edge.id, weight);
              }
              Navigator.pop(context);
            },
            child: const Text("Valider"),
          ),
        ],
      ),
    );
  }
}

class GraphPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final Set<String> selectedNodeIds;
  final String? connectingNodeId;
  final Set<String> visitedNodes;
  final String? activeEdgeId;
  final AppTheme theme;
  final Offset? connectionEnd;
  final Rect? lassoRect;
  final bool showGrid;
  final String? startNodeId;
  final String? endNodeId;
  final DijkstraResult? dijkstraResult;

  GraphPainter({
    required this.nodes,
    required this.edges,
    required this.selectedNodeIds,
    this.connectingNodeId,
    required this.visitedNodes,
    this.activeEdgeId,
    required this.theme,
    this.connectionEnd,
    this.lassoRect,
    this.showGrid = false,
    this.startNodeId,
    this.endNodeId,
    this.dijkstraResult,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) {
      _drawGrid(canvas, size);
    }

    final edgePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final activeEdgePaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final dijkstraPathPaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final visitedNodePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    final selectedNodePaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final connectingPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Dessiner l'aperçu de connexion en cours
    if (connectingNodeId != null && connectionEnd != null) {
      final startNode = nodes.firstWhere((n) => n.id == connectingNodeId);
      canvas.drawLine(
        startNode.position,
        connectionEnd!,
        connectingPaint
          ..strokeWidth = 1.5
          ..color = Colors.green.withValues(alpha: 0.5),
      );
    }

    // Dessiner les arêtes
    for (final edge in edges) {
      final fromNode = nodes.cast<GraphNode?>().firstWhere(
        (n) => n?.id == edge.fromId,
        orElse: () => null,
      );
      final toNode = nodes.cast<GraphNode?>().firstWhere(
        (n) => n?.id == edge.toId,
        orElse: () => null,
      );
      if (fromNode != null && toNode != null) {
        if (fromNode.id == toNode.id) {
          // Cas d'une boucle sur soi-même (Self-loop)
          // Check if this edge is in Dijkstra path
          final isInDijkstraPath = _isEdgeInDijkstraPath(
            edge,
            fromNode,
            toNode,
          );
          final paint = isInDijkstraPath
              ? dijkstraPathPaint
              : (edge.id == activeEdgeId ? activeEdgePaint : edgePaint);
          final center = fromNode.position;
          const radius = 25.0;
          // Dessiner un cercle tangent au sommet
          canvas.drawArc(
            Rect.fromCircle(
              center: center + const Offset(radius, -radius),
              radius: radius,
            ),
            0,
            2 * math.pi,
            false,
            paint,
          );

          // Flèche pour la boucle
          if (edge.directed) {
            final arrowPos = center + const Offset(radius * 2, -radius);
            _drawArrowHead(
              canvas,
              center + const Offset(radius * 2, 0),
              arrowPos,
              paint,
            );
          }

          // Poids pour la boucle
          if (edge.weight != 1.0) {
            _drawText(
              canvas,
              center + const Offset(radius * 2.5, -radius * 2.5),
              edge.weight.toInt().toString(),
              10,
              theme == AppTheme.dark ? Colors.white70 : Colors.black87,
              isBold: true,
            );
          }
        } else {
          // Check if this edge is in Dijkstra path
          final isInDijkstraPath = _isEdgeInDijkstraPath(
            edge,
            fromNode,
            toNode,
          );
          final paint = isInDijkstraPath
              ? dijkstraPathPaint
              : (edge.id == activeEdgeId ? activeEdgePaint : edgePaint);

          // Calculer les points d'ancrage à la bordure du cercle pour ne pas chevaucher
          final direction = toNode.position - fromNode.position;
          final distance = direction.distance;
          final unitDirection = direction / distance;

          final start = fromNode.position + unitDirection * 20;
          final end = toNode.position - unitDirection * 20;

          canvas.drawLine(start, end, paint);

          // Dessiner la flèche si orienté
          if (edge.directed) {
            _drawArrowHead(canvas, start, end, paint);
          }

          // Dessiner le poids
          if (edge.weight != 1.0) {
            _drawEdgeWeight(canvas, start, end, edge.weight);
          }
        }
      }
    }

    // Dessiner les sommets
    for (final node in nodes) {
      final isVisited = visitedNodes.contains(node.id);

      // Ombre portée
      canvas.drawCircle(
        node.position + const Offset(2, 2),
        20,
        Paint()
          ..color = Colors.black26
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      canvas.drawCircle(
        node.position,
        20,
        isVisited ? visitedNodePaint : (nodePaint..color = node.color),
      );

      // Highlight Dijkstra path nodes
      final isInDijkstraPath =
          dijkstraResult?.shortestPath?.contains(node.id) ?? false;
      if (isInDijkstraPath) {
        canvas.drawCircle(
          node.position,
          23,
          Paint()
            ..color = Colors.greenAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }

      if (selectedNodeIds.contains(node.id)) {
        canvas.drawCircle(node.position, 22, selectedNodePaint);
      }

      if (node.id == startNodeId) {
        canvas.drawCircle(
          node.position,
          24,
          Paint()
            ..color = Colors.green
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke,
        );
      }

      if (node.id == endNodeId) {
        canvas.drawCircle(
          node.position,
          26,
          Paint()
            ..color = Colors.red
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke,
        );
      }

      if (node.id == connectingNodeId) {
        // Cercle pulsant ou simple vert
        canvas.drawCircle(node.position, 22, connectingPaint);
      }

      // Dessiner le label
      _drawText(canvas, node.position, node.label, 12, Colors.white);
    }

    // Dessiner le Lasso
    if (lassoRect != null) {
      canvas.drawRect(
        lassoRect!,
        Paint()
          ..color = Colors.blue.withValues(alpha: 0.1)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        lassoRect!,
        Paint()
          ..color = Colors.blue.withValues(alpha: 0.5)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = theme == AppTheme.dark
          ? Colors.white.withValues(alpha: 0.15)
          : Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;

    const double step = 40.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double arrowSize = 12.0;
    const double arrowAngle = 0.5; // radians

    final double dX = end.dx - start.dx;
    final double dY = end.dy - start.dy;
    final double angle = math.atan2(dY, dX);

    final Offset p1 = end - Offset.fromDirection(angle + arrowAngle, arrowSize);
    final Offset p2 = end - Offset.fromDirection(angle - arrowAngle, arrowSize);

    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill,
    );
  }

  void _drawEdgeWeight(Canvas canvas, Offset start, Offset end, double weight) {
    final middle = (start + end) / 2;
    // Décalage pour ne pas être sur la ligne
    final direction = end - start;
    final normal = Offset(-direction.dy, direction.dx).unit;
    final textPos = middle + normal * 15;

    _drawText(
      canvas,
      textPos,
      weight.toInt().toString(),
      10,
      theme == AppTheme.dark ? Colors.white70 : Colors.black87,
      isBold: true,
    );
  }

  void _drawText(
    Canvas canvas,
    Offset position,
    String text,
    double fontSize,
    Color color, {
    bool isBold = false,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  /// Check if an edge is part of the Dijkstra shortest path
  bool _isEdgeInDijkstraPath(
    GraphEdge edge,
    GraphNode fromNode,
    GraphNode toNode,
  ) {
    if (dijkstraResult?.shortestPath == null) return false;

    final path = dijkstraResult!.shortestPath!;
    if (path.length < 2) return false;

    // Check if this edge connects two consecutive nodes in the path
    for (int i = 0; i < path.length - 1; i++) {
      final current = path[i];
      final next = path[i + 1];

      // Check both directions in case of undirected edge
      if ((edge.fromId == current && edge.toId == next) ||
          (!edge.directed && edge.fromId == next && edge.toId == current)) {
        return true;
      }
    }

    return false;
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) => true;
}

class _MiniMap extends StatelessWidget {
  final GraphProvider provider;
  final AppTheme theme;

  const _MiniMap({required this.provider, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(
          painter: _MiniMapPainter(
            nodes: provider.nodes,
            edges: provider.edges,
            theme: theme,
          ),
        ),
      ),
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final AppTheme theme;

  _MiniMapPainter({
    required this.nodes,
    required this.edges,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    // Calculer les bornes du graphe pour l'ajuster
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;

    for (final node in nodes) {
      minX = math.min(minX, node.position.dx);
      minY = math.min(minY, node.position.dy);
      maxX = math.max(maxX, node.position.dx);
      maxY = math.max(maxY, node.position.dy);
    }

    final graphWidth = (maxX - minX).abs() + 100;
    final graphHeight = (maxY - minY).abs() + 100;
    final scale = math.min(size.width / graphWidth, size.height / graphHeight);

    canvas.save();
    canvas.scale(scale);
    canvas.translate(-minX + 50, -minY + 50);

    final edgePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (final edge in edges) {
      final from = nodes.firstWhere((n) => n.id == edge.fromId).position;
      final to = nodes.firstWhere((n) => n.id == edge.toId).position;
      canvas.drawLine(from, to, edgePaint);
    }

    final nodePaint = Paint()..color = Colors.blue.withValues(alpha: 0.6);
    for (final node in nodes) {
      canvas.drawCircle(node.position, 15, nodePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

extension UnitOffset on Offset {
  Offset get unit => distance == 0 ? Offset.zero : this / distance;
}
