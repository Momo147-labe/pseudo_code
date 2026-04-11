import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../providers/merise_provider.dart';
import '../../../merise/mcd_models.dart';
import '../../../theme.dart';

class GrapheDfView extends StatefulWidget {
  final AppTheme theme;
  final bool isMobile;

  const GrapheDfView({super.key, required this.theme, this.isMobile = false});

  @override
  State<GrapheDfView> createState() => _GrapheDfViewState();
}

class _GrapheDfViewState extends State<GrapheDfView> {
  final TransformationController _controller = TransformationController();
  final Map<String, Offset> _positions = {};
  List<_DfInfo> _dfs = [];
  Map<String, _NodePos> _nodeMetadata = {};
  String? _draggedId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshData();
  }

  void _refreshData() {
    final provider = context.read<MeriseProvider>();
    final mcd = provider.mcd;

    _dfs = _deriveDFs(mcd);

    // Garder les positions existantes, initialiser les nouvelles
    final initialLayout = _computeInitialLayout(mcd, _dfs);
    for (final entry in initialLayout.entries) {
      if (!_positions.containsKey(entry.key)) {
        _positions[entry.key] = entry.value.pos;
      }
      _nodeMetadata[entry.key] = entry.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Container(
      color: ThemeColors.editorBg(theme),
      child: Stack(
        children: [
          InteractiveViewer(
            transformationController: _controller,
            boundaryMargin: const EdgeInsets.all(1000),
            minScale: 0.1,
            maxScale: 2.0,
            child: Stack(
              children: [
                // Fond pour CustomPaint
                SizedBox(
                  width: 3000,
                  height: 3000,
                  child: CustomPaint(
                    painter: _GrapheDfPainter(
                      nodes: _positions,
                      metadata: _nodeMetadata,
                      dfs: _dfs,
                      theme: theme,
                    ),
                  ),
                ),
                // Noeuds interactifs
                ..._positions.entries.map((entry) {
                  final id = entry.key;
                  final pos = entry.value;
                  final meta = _nodeMetadata[id]!;

                  if (meta.isComposite) {
                    return _buildCompositeJunction(id, pos, theme);
                  }

                  return _buildDraggableNode(id, pos, meta.label, theme);
                }),
              ],
            ),
          ),
          _buildLegend(theme),
        ],
      ),
    );
  }

  Widget _buildDraggableNode(
    String id,
    Offset pos,
    String label,
    AppTheme theme,
  ) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    final textColor = isDark ? Colors.white : Colors.black;

    return Positioned(
      left: pos.dx - 50,
      top: pos.dy - 15,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _draggedId = id),
        onPanUpdate: (details) {
          setState(() {
            _positions[id] =
                _positions[id]! +
                details.delta / _controller.value.getMaxScaleOnAxis();
          });
        },
        onPanEnd: (_) => setState(() => _draggedId = null),
        child: Container(
          width: 100,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: _draggedId == id
                ? Colors.blue.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              decoration: id.contains("_pk_") ? TextDecoration.underline : null,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildCompositeJunction(String id, Offset pos, AppTheme theme) {
    return Positioned(
      left: pos.dx - 8,
      top: pos.dy - 8,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _positions[id] =
                _positions[id]! +
                details.delta / _controller.value.getMaxScaleOnAxis();
          });
        },
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue, width: 2),
            color: ThemeColors.editorBg(theme),
          ),
        ),
      ),
    );
  }

  List<_DfInfo> _deriveDFs(Mcd mcd) {
    final results = <_DfInfo>[];

    // 1. DFs Internes (PK -> Attributs)
    for (final entity in mcd.entities) {
      final pk = entity.attributes.where((a) => a.isPrimaryKey).toList();
      final nonPk = entity.attributes.where((a) => !a.isPrimaryKey).toList();

      if (pk.isNotEmpty) {
        for (final attr in nonPk) {
          results.add(
            _DfInfo(
              sourceId: "node_${entity.id}_pk",
              targetId: "node_${entity.id}_${attr.name}",
              label: attr.name,
            ),
          );
        }
      }
    }

    // 2. DFs Externes (Relations 1,1 -> FK migration)
    for (final relation in mcd.relations) {
      final links = mcd.links
          .where((l) => l.relationId == relation.id)
          .toList();

      final sourcePkNodeIds = <String>[];
      for (final link in links) {
        sourcePkNodeIds.add("node_${link.entityId}_pk");
      }

      if (relation.attributes.isNotEmpty) {
        final junctionId = "junction_${relation.id}";
        // PKs -> Cercle
        for (final sid in sourcePkNodeIds) {
          results.add(
            _DfInfo(
              sourceId: sid,
              targetId: junctionId,
              isPartofComposite: true,
            ),
          );
        }
        // Cercle -> Attributs de la relation
        for (final attr in relation.attributes) {
          results.add(
            _DfInfo(
              sourceId: junctionId,
              targetId: "node_rel_${relation.id}_${attr.name}",
            ),
          );
        }
      } else {
        // Relation sans attributs mais avec une patte (1,1) -> Migration FK
        final oneOneLink = links
            .where((l) => l.cardinalities == "1,1")
            .firstOrNull;
        if (oneOneLink != null) {
          // Trouver l'AUTRE entité
          final otherLink = links.where((l) => l != oneOneLink).firstOrNull;
          if (otherLink != null) {
            // DF: PK(1,1) -> PK(Other)
            results.add(
              _DfInfo(
                sourceId: "node_${oneOneLink.entityId}_pk",
                targetId: "node_${otherLink.entityId}_pk",
                isFK: true,
              ),
            );
          }
        }
      }
    }

    return results;
  }

  Map<String, _NodePos> _computeInitialLayout(Mcd mcd, List<_DfInfo> dfs) {
    final Map<String, _NodePos> meta = {};
    double currentY = 100;
    double currentX = 200;
    const double spacingX = 250;
    const double spacingY = 150;

    // 1. Noeuds d'entités
    for (final entity in mcd.entities) {
      final pk = entity.attributes.where((a) => a.isPrimaryKey).firstOrNull;
      if (pk != null) {
        meta["node_${entity.id}_pk"] = _NodePos(
          label: pk.name,
          pos: Offset(currentX, currentY),
        );
      }

      final nonPk = entity.attributes.where((a) => !a.isPrimaryKey).toList();
      for (int i = 0; i < nonPk.length; i++) {
        meta["node_${entity.id}_${nonPk[i].name}"] = _NodePos(
          label: nonPk[i].name,
          pos: Offset(
            currentX + (i % 2 == 0 ? -80 : 80),
            currentY + spacingY + (i ~/ 2) * 40,
          ),
        );
      }
      currentX += spacingX;
    }

    // 2. Noeuds de relations
    for (final rel in mcd.relations) {
      if (rel.attributes.isNotEmpty) {
        final junctionId = "junction_${rel.id}";
        meta[junctionId] = _NodePos(
          label: "",
          pos: Offset(currentX, currentY + 100),
          isComposite: true,
        );

        for (int i = 0; i < rel.attributes.length; i++) {
          meta["node_rel_${rel.id}_${rel.attributes[i].name}"] = _NodePos(
            label: rel.attributes[i].name,
            pos: Offset(
              currentX + (i % 2 == 0 ? -80 : 80),
              currentY + 250 + (i ~/ 2) * 40,
            ),
          );
        }
        currentX += spacingX;
      }
    }

    return meta;
  }

  Widget _buildLegend(AppTheme theme) {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ThemeColors.sidebarBg(theme).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Légende :", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.arrow_forward, size: 16),
                SizedBox(width: 8),
                Text("Dépendance Fonctionnelle (DF)"),
              ],
            ),
            Row(
              children: [
                Icon(Icons.circle_outlined, size: 16),
                SizedBox(width: 8),
                Text("Concatenation (Clé composée)"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DfInfo {
  final String sourceId;
  final String targetId;
  final String? label;
  final bool isPartofComposite;
  final bool isFK;

  _DfInfo({
    required this.sourceId,
    required this.targetId,
    this.label,
    this.isPartofComposite = false,
    this.isFK = false,
  });
}

class _NodePos {
  final String label;
  final Offset pos;
  final bool isComposite;

  _NodePos({required this.label, required this.pos, this.isComposite = false});
}

class _GrapheDfPainter extends CustomPainter {
  final Map<String, Offset> nodes;
  final Map<String, _NodePos> metadata;
  final List<_DfInfo> dfs;
  final AppTheme theme;

  _GrapheDfPainter({
    required this.nodes,
    required this.metadata,
    required this.dfs,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E88E5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Dessiner les liens
    for (final df in dfs) {
      final start = nodes[df.sourceId];
      final end = nodes[df.targetId];

      if (start != null && end != null) {
        if (df.isPartofComposite) {
          // Pas de flèche pour les parties de composite, juste une ligne vers le cercle
          canvas.drawLine(start, end, paint);
        } else {
          _drawArrow(canvas, start, end, paint, isDashed: df.isFK);
        }
      }
    }
  }

  void _drawArrow(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint, {
    bool isDashed = false,
  }) {
    // Arrow head
    final double angle = (p2 - p1).direction;
    const double arrowSize = 8;

    // Dessiner la ligne (on l'arrête un peu avant p2 pour voir la flèche)
    final endPoint = p2 - Offset.fromDirection(angle, 5);

    if (isDashed) {
      paint.color = Colors.blueGrey;
    } else {
      paint.color = const Color(0xFF1E88E5);
    }

    canvas.drawLine(p1, endPoint, paint);

    final p3 = p2 - Offset.fromDirection(angle, arrowSize).rotate(math.pi / 6);
    final p4 = p2 - Offset.fromDirection(angle, arrowSize).rotate(-math.pi / 6);

    canvas.drawPath(
      Path()
        ..moveTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..lineTo(p4.dx, p4.dy)
        ..close(),
      paint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

extension on Offset {
  Offset rotate(double angle) {
    return Offset(
      dx * math.cos(angle) - dy * math.sin(angle),
      dx * math.sin(angle) + dy * math.cos(angle),
    );
  }
}
