import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../../../providers/merise_provider.dart';
import '../../../merise/mcd_models.dart';
import '../../../theme.dart';

class MeriseCanvasView extends StatefulWidget {
  final AppTheme theme;
  final bool isMobile;
  const MeriseCanvasView({
    super.key,
    required this.theme,
    this.isMobile = false,
  });

  @override
  State<MeriseCanvasView> createState() => _MeriseCanvasViewState();
}

class _MeriseCanvasViewState extends State<MeriseCanvasView> {
  final GlobalKey _canvasKey = GlobalKey();
  Offset? _selectionStart;
  Offset? _selectionEnd;
  double _initialZoom = 1.0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeriseProvider>();
    final mcd = provider.mcd;
    final zoom = provider.zoom;
    final scale = provider.textScaleFactor;
    final isDark =
        widget.theme != AppTheme.light && widget.theme != AppTheme.papier;

    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        final rb = context.findRenderObject() as RenderBox;
        final localPos = rb.globalToLocal(details.offset);
        if (details.data == 'new_entity') {
          provider.createEntity(localPos);
        } else if (details.data == 'new_relation') {
          provider.createRelation(localPos);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return RepaintBoundary(
          key: _canvasKey,
          child: Container(
            color: ThemeColors.editorBg(widget.theme),
            child: Listener(
              onPointerMove: (event) {
                if (provider.isLinkMode && provider.linkSourceId != null) {
                  final rb = context.findRenderObject() as RenderBox;
                  provider.updateTempLink(rb.globalToLocal(event.position));
                }
              },
              child: ClipRect(
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Grille de fond
                    CustomPaint(
                      painter: _GridPainter(
                        zoom: zoom,
                        theme: widget.theme,
                        panOffset: provider.panOffset,
                      ),
                      size: Size.infinite,
                    ),

                    // Détecteur de fond pour le déplacement et la sélection
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => provider.selectItem(null),
                        onSecondaryTap: () => provider.selectItem(null),
                        onScaleStart: (details) {
                          _initialZoom = provider.zoom;
                          final isShift =
                              HardwareKeyboard.instance.isShiftPressed;
                          if (isShift || provider.isLinkMode) {
                            final rb = context.findRenderObject() as RenderBox;
                            setState(() {
                              _selectionStart = rb.globalToLocal(
                                details.focalPoint,
                              );
                              _selectionEnd = _selectionStart;
                            });
                          }
                        },
                        onScaleUpdate: (details) {
                          if (_selectionStart != null) {
                            final rb = context.findRenderObject() as RenderBox;
                            setState(() {
                              _selectionEnd = rb.globalToLocal(
                                details.focalPoint,
                              );
                            });
                          } else if (details.pointerCount == 2) {
                            // Pinch to zoom
                            provider.setZoom(_initialZoom * details.scale);
                          } else if (details.pointerCount == 1 &&
                              !provider.isLinkMode &&
                              !provider.isDraggingElement) {
                            // Pan using delta from details
                            provider.updatePanOffset(
                              details.focalPointDelta / zoom,
                            );
                          }
                        },
                        onScaleEnd: (details) {
                          if (_selectionStart != null) {
                            _applySelectionRectangle(provider);
                            setState(() {
                              _selectionStart = null;
                              _selectionEnd = null;
                            });
                          }
                        },
                      ),
                    ),

                    // Conteneur transformé pour les éléments
                    Positioned.fill(
                      child: Transform.translate(
                        offset: provider.panOffset * zoom,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Les Liens (Tracés sous les entités) avec Ancres Intelligentes
                            ...mcd.links
                                .where((link) {
                                  final entityExists = mcd.entities.any(
                                    (e) => e.id == link.entityId,
                                  );
                                  final relationExists = mcd.relations.any(
                                    (r) => r.id == link.relationId,
                                  );
                                  return entityExists && relationExists;
                                })
                                .map((link) {
                                  final entity = mcd.entities.firstWhere(
                                    (e) => e.id == link.entityId,
                                  );
                                  final relation = mcd.relations.firstWhere(
                                    (r) => r.id == link.relationId,
                                  );

                                  // Calculer les dimensions réelles
                                  final entWidth = 150 * zoom * scale;
                                  final entHeight =
                                      (40 + entity.attributes.length * 20) *
                                      zoom *
                                      scale;

                                  final relSize = 45 * zoom * scale;

                                  final eCenter =
                                      entity.position * zoom +
                                      Offset(entWidth / 2, entHeight / 2);
                                  final rCenter =
                                      relation.position * zoom +
                                      Offset(relSize / 2, relSize / 2);

                                  // Points d'ancrage intelligents sur les bords
                                  final start = _getRectIntersection(
                                    entity.position * zoom,
                                    Size(entWidth, entHeight),
                                    rCenter,
                                  );
                                  final end = _getCircleIntersection(
                                    relation.position * zoom,
                                    relSize / 2,
                                    eCenter,
                                  );

                                  return CustomPaint(
                                    painter: _LinkPainter(
                                      offset1: start,
                                      offset2: end,
                                      strokeColor: isDark
                                          ? Colors.white.withValues(alpha: 0.3)
                                          : Colors.black.withValues(
                                              alpha: 0.38,
                                            ),
                                      zoom: zoom,
                                      cardinalities: link.cardinalities,
                                      scale: scale,
                                      textColor: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  );
                                }),

                            // Ligne temporaire en mode lien
                            if (provider.isLinkMode &&
                                provider.linkSourceId != null &&
                                provider.tempLinkEnd != null)
                              _buildTempLink(provider, mcd, zoom, scale),

                            // Les Associations (Relations)
                            ...mcd.relations.map((rel) {
                              return Positioned(
                                left: rel.position.dx * zoom,
                                top: rel.position.dy * zoom,
                                child: _RelationWidget(
                                  relation: rel,
                                  theme: widget.theme,
                                  provider: provider,
                                  isSelected: provider.isSelected(rel.id),
                                  zoom: zoom,
                                  isLinkMode: provider.isLinkMode,
                                  onTap: () => provider.selectItem(rel),
                                ),
                              );
                            }),

                            // Les Entités
                            ...mcd.entities.map((entity) {
                              return Positioned(
                                left: entity.position.dx * zoom,
                                top: entity.position.dy * zoom,
                                child: _EntityWidget(
                                  entity: entity,
                                  theme: widget.theme,
                                  primaryColor: const Color(0xFF1E88E5),
                                  isSelected: provider.isSelected(entity.id),
                                  zoom: zoom,
                                  isLinkMode: provider.isLinkMode,
                                  provider: provider,
                                  onTap: () => provider.selectItem(entity),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    // Minimap (Bottom Left)
                    Positioned(
                      left: 20,
                      bottom: 20,
                      child: IgnorePointer(
                        ignoring: false,
                        child: _Minimap(
                          mcd: mcd,
                          theme: widget.theme,
                          provider: provider,
                        ),
                      ),
                    ),

                    // Barre d'outils flottante (Bottom Right)
                    if (!widget.isMobile)
                      Positioned(
                        right: 20,
                        bottom: 20,
                        child: IgnorePointer(
                          ignoring: false,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: ThemeColors.sidebarBg(widget.theme),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                ),
                              ],
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Column(
                              children: [
                                _ToolbarButton(
                                  Icons.auto_awesome_motion,
                                  widget.theme,
                                  tooltip: "Auto-Layout",
                                  onTap: () => provider.autoLayout(),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      _ToolbarButton(
                                        Icons.add,
                                        widget.theme,
                                        tooltip: "Zoom +",
                                        onTap: () =>
                                            provider.setZoom(zoom + 0.1),
                                      ),
                                      _ToolbarButton(
                                        Icons.remove,
                                        widget.theme,
                                        tooltip: "Zoom -",
                                        onTap: () =>
                                            provider.setZoom(zoom - 0.1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _ToolbarButton(
                                  Icons.center_focus_strong,
                                  widget.theme,
                                  tooltip: "Reset Vue",
                                  onTap: () {
                                    provider.setZoom(1.0);
                                    provider.resetPanOffset();
                                  },
                                ),
                                _ToolbarButton(
                                  Icons.filter_center_focus,
                                  widget.theme,
                                  tooltip: "Centrer tout",
                                  onTap: () {
                                    final rb =
                                        context.findRenderObject()
                                            as RenderBox?;
                                    if (rb != null) {
                                      provider.autoCenter(rb.size);
                                    }
                                  },
                                ),
                                const Divider(
                                  height: 8,
                                  indent: 8,
                                  endIndent: 8,
                                ),
                                _ToolbarButton(
                                  Icons.camera_alt_outlined,
                                  widget.theme,
                                  tooltip: "Exporter Image",
                                  onTap: _exportToImage,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Barre d'alignement (Desktop uniquement, multi-sélection)
                    if (!widget.isMobile && provider.selectedIds.length >= 2)
                      Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          ignoring:
                              true, // Parent Positioned should ignore hits
                          child: Center(
                            child: IgnorePointer(
                              ignoring: false, // Child toolbar catches hits
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: ThemeColors.sidebarBg(
                                    widget.theme,
                                  ).withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blueAccent.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _AlignmentButton(
                                      icon: Icons.align_horizontal_left,
                                      tooltip: "Aligner à gauche",
                                      onTap: () =>
                                          provider.alignSelection('left'),
                                      theme: widget.theme,
                                    ),
                                    _AlignmentButton(
                                      icon: Icons.align_vertical_top,
                                      tooltip: "Aligner en haut",
                                      onTap: () =>
                                          provider.alignSelection('top'),
                                      theme: widget.theme,
                                    ),
                                    _AlignmentButton(
                                      icon: Icons.align_horizontal_right,
                                      tooltip: "Aligner à droite",
                                      onTap: () =>
                                          provider.alignSelection('right'),
                                      theme: widget.theme,
                                    ),
                                    _AlignmentButton(
                                      icon: Icons.align_vertical_bottom,
                                      tooltip: "Aligner en bas",
                                      onTap: () =>
                                          provider.alignSelection('bottom'),
                                      theme: widget.theme,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Lasso de sélection (Ajouter le panOffset)
                    if (_selectionStart != null && _selectionEnd != null)
                      Positioned.fromRect(
                        rect: Rect.fromPoints(_selectionStart!, _selectionEnd!),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportToImage() async {
    try {
      final boundary =
          _canvasKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      // final pngBytes = byteData.buffer.asUint8List(); // Unused

      // On pourrait enregistrer le fichier ici, mais pour l'instant on notifie l'utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Capture d'écran prête (Simulation)"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur export: $e")));
      }
    }
  }

  void _applySelectionRectangle(MeriseProvider provider) {
    if (_selectionStart == null || _selectionEnd == null) return;
    final zoom = provider.zoom;
    final panOffset = provider.panOffset;

    // Ajuster le rectangle de sélection pour l'espace local (sans zoom/pan)
    final rawRect = Rect.fromPoints(_selectionStart!, _selectionEnd!);
    final rect = Rect.fromLTWH(
      (rawRect.left / zoom) - panOffset.dx,
      (rawRect.top / zoom) - panOffset.dy,
      rawRect.width / zoom,
      rawRect.height / zoom,
    );

    bool additive = HardwareKeyboard.instance.isShiftPressed;
    if (!additive) provider.clearSelection();

    for (final e in provider.entities) {
      final scale = provider.textScaleFactor;
      final eRect =
          e.position &
          Size(150 * scale, (40 + e.attributes.length * 20) * scale);
      if (rect.overlaps(eRect)) {
        provider.selectItem(e, additive: true);
      }
    }
    for (final r in provider.relations) {
      final scale = provider.textScaleFactor;
      final height =
          (r.attributes.isEmpty ? 45 : 45 + r.attributes.length * 20) * scale;
      final rRect =
          r.position &
          Size(height > 45 * scale ? 140 * scale : 45 * scale, height);
      if (rect.overlaps(rRect)) {
        provider.selectItem(r, additive: true);
      }
    }
  }

  Widget _buildTempLink(
    MeriseProvider provider,
    Mcd mcd,
    double zoom,
    double scale,
  ) {
    final sourceId = provider.linkSourceId!;
    Offset start = Offset.zero;

    final entity = mcd.entities.firstWhere(
      (e) => e.id == sourceId,
      orElse: () =>
          McdEntity(id: "", name: "", position: Offset.zero, attributes: []),
    );
    if (entity.id.isNotEmpty) {
      final entWidth = 150 * zoom * scale;
      final entHeight = (40 + entity.attributes.length * 20) * zoom * scale;
      start = _getRectIntersection(
        entity.position * zoom,
        Size(entWidth, entHeight),
        provider.tempLinkEnd!,
      );
    } else {
      final relation = mcd.relations.firstWhere((r) => r.id == sourceId);
      final relSize = 45 * zoom * scale;
      start = _getCircleIntersection(
        relation.position * zoom,
        relSize / 2,
        provider.tempLinkEnd!,
      );
    }

    return CustomPaint(
      painter: _LinkPainter(
        offset1: start,
        offset2: provider.tempLinkEnd!,
        strokeColor: const Color(0xFF1E88E5).withValues(alpha: 0.5),
        strokeWidth: 2.0,
        zoom: zoom,
      ),
    );
  }

  // Fonctions utilitaires pour le calcul des intersections (Ancres)
  Offset _getCircleIntersection(Offset pos, double radius, Offset target) {
    final center = pos + Offset(radius, radius);
    final angle = math.atan2(target.dy - center.dy, target.dx - center.dx);
    return center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
  }

  Offset _getRectIntersection(Offset pos, Size size, Offset target) {
    final center = pos + Offset(size.width / 2, size.height / 2);
    final dx = target.dx - center.dx;
    final dy = target.dy - center.dy;

    if (dx == 0 && dy == 0) return center;

    final absDx = dx.abs();
    final absDy = dy.abs();
    final halfWidth = size.width / 2;
    final halfHeight = size.height / 2;

    if (absDx * halfHeight > absDy * halfWidth) {
      // Intersection avec le bord gauche ou droit
      return Offset(
        center.dx + (dx > 0 ? halfWidth : -halfWidth),
        center.dy + dy * halfWidth / absDx,
      );
    } else {
      // Intersection avec le bord haut ou bas
      return Offset(
        center.dx + dx * halfHeight / absDy,
        center.dy + (dy > 0 ? halfHeight : -halfHeight),
      );
    }
  }
}

class _GridPainter extends CustomPainter {
  final double zoom;
  final AppTheme theme;
  final Offset panOffset;
  _GridPainter({
    required this.zoom,
    required this.theme,
    required this.panOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    final step = 20.0 * zoom;

    // Décalage de la grille
    final currentPan = panOffset;
    final offsetX = (currentPan.dx * zoom) % step;
    final offsetY = (currentPan.dy * zoom) % step;

    for (double x = offsetX; x < size.width; x += step) {
      for (double y = offsetY; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.zoom != zoom ||
      oldDelegate.theme != theme ||
      oldDelegate.panOffset != panOffset;
}

class _LinkPainter extends CustomPainter {
  final Offset offset1;
  final Offset offset2;
  final Color strokeColor;
  final double strokeWidth;
  final double zoom;
  final String? cardinalities;
  final double scale;
  final Color textColor;

  _LinkPainter({
    required this.offset1,
    required this.offset2,
    required this.strokeColor,
    this.strokeWidth = 1.5,
    required this.zoom,
    this.cardinalities,
    this.scale = 1.0,
    this.textColor = Colors.black,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth * zoom;
    canvas.drawLine(offset1, offset2, paint);

    if (cardinalities != null && cardinalities!.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: "($cardinalities)",
          style: TextStyle(
            color: textColor,
            fontSize: 9 * zoom * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Positionner le texte un peu après le point de départ (côté entité)
      // On calcule le vecteur unitaire de la ligne
      final dx = offset2.dx - offset1.dx;
      final dy = offset2.dy - offset1.dy;
      final distance = math.sqrt(dx * dx + dy * dy);

      if (distance > 10) {
        final ux = dx / distance;
        final uy = dy / distance;

        // On place le texte à environ 15-20 pixels du bord de l'entité
        // et on le décale légèrement perpendiculairement pour ne pas être sur la ligne
        final textOffset = Offset(
          offset1.dx + ux * 15 * zoom,
          offset1.dy + uy * 15 * zoom,
        );

        // Décalage perpendiculaire
        final px = -uy;
        final py = ux;

        canvas.save();
        canvas.translate(
          textOffset.dx + px * 8 * zoom,
          textOffset.dy + py * 8 * zoom,
        );
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Minimap extends StatelessWidget {
  final Mcd mcd;
  final AppTheme theme;
  final MeriseProvider provider;
  const _Minimap({
    required this.mcd,
    required this.theme,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    return GestureDetector(
      onTapDown: (details) {
        final rb = context.findRenderObject() as RenderBox;
        final localPos = rb.globalToLocal(details.globalPosition);

        // Calculer les limites (comme dans le painter)
        double minX = double.infinity;
        double minY = double.infinity;
        double maxX = -double.infinity;
        double maxY = -double.infinity;

        if (mcd.entities.isEmpty && mcd.relations.isEmpty) return;

        for (final e in mcd.entities) {
          minX = math.min(minX, e.position.dx);
          minY = math.min(minY, e.position.dy);
          maxX = math.max(maxX, e.position.dx + 150);
          maxY = math.max(maxY, e.position.dy + 100);
        }
        for (final r in mcd.relations) {
          minX = math.min(minX, r.position.dx);
          minY = math.min(minY, r.position.dy);
          maxX = math.max(maxX, r.position.dx + 45);
          maxY = math.max(maxY, r.position.dy + 45);
        }

        final worldWidth = math.max(100.0, maxX - minX + 100);
        final worldHeight = math.max(100.0, maxY - minY + 100);
        final paintWidth = 150.0;
        final paintHeight = 100.0;

        final scale = math.min(
          paintWidth / worldWidth,
          paintHeight / worldHeight,
        );

        // worldX = (localX - inset) / scale + minX
        final worldX = (localPos.dx - 10) / scale + minX;
        final worldY = (localPos.dy - 10) / scale + minY;

        // Récupérer la taille du viewport du canvas
        final canvasRb = context.findAncestorRenderObjectOfType<RenderBox>();
        if (canvasRb != null) {
          provider.jumpTo(Offset(worldX, worldY), canvasRb.size);
        }
      },
      child: Container(
        width: 150,
        height: 100,
        decoration: BoxDecoration(
          color: ThemeColors.sidebarBg(theme).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          painter: _MinimapPainter(mcd: mcd, theme: theme),
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  final Mcd mcd;
  final AppTheme theme;
  _MinimapPainter({required this.mcd, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    if (mcd.entities.isEmpty && mcd.relations.isEmpty) return;

    final isDark = theme != AppTheme.light && theme != AppTheme.papier;

    // Trouver les limites du schéma
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final e in mcd.entities) {
      minX = math.min(minX, e.position.dx);
      minY = math.min(minY, e.position.dy);
      maxX = math.max(maxX, e.position.dx + 150);
      maxY = math.max(maxY, e.position.dy + 100);
    }
    for (final r in mcd.relations) {
      minX = math.min(minX, r.position.dx);
      minY = math.min(minY, r.position.dy);
      maxX = math.max(maxX, r.position.dx + 45);
      maxY = math.max(maxY, r.position.dy + 45);
    }

    final worldWidth = math.max(100.0, maxX - minX + 100);
    final worldHeight = math.max(100.0, maxY - minY + 100);
    final scale = math.min(size.width / worldWidth, size.height / worldHeight);

    canvas.translate(10, 10);
    canvas.scale(scale);
    canvas.translate(-minX, -minY);

    final paint = Paint();

    // Dessiner les entités
    paint.color = const Color(0xFF1E88E5).withValues(alpha: 0.5);
    for (final e in mcd.entities) {
      canvas.drawRect(e.position & const Size(150, 80), paint);
    }

    // Dessiner les relations
    paint.color = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.3);
    for (final r in mcd.relations) {
      canvas.drawCircle(r.position + const Offset(22.5, 22.5), 22.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter oldDelegate) => true;
}

class _EntityWidget extends StatefulWidget {
  final McdEntity entity;
  final AppTheme theme;
  final Color primaryColor;
  final bool isSelected;
  final double zoom;
  final bool isLinkMode;
  final MeriseProvider provider;
  final VoidCallback onTap;

  const _EntityWidget({
    required this.entity,
    required this.theme,
    required this.primaryColor,
    required this.provider,
    required this.onTap,
    this.isSelected = false,
    this.zoom = 1.0,
    this.isLinkMode = false,
  });

  @override
  State<_EntityWidget> createState() => _EntityWidgetState();
}

class _EntityWidgetState extends State<_EntityWidget> {
  Offset? _dragStartGlobal;
  Offset? _initialEntityPos;
  bool _isHovered = false;
  bool _isDragging = false;

  void _showContextMenu(BuildContext context, Offset globalPos) {
    final provider = widget.provider;
    final entity = widget.entity;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<void>(
      context: context,
      position: RelativeRect.fromRect(
        globalPos & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          onTap: () => provider.selectItem(entity),
          child: const Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 12),
              Text("Éditer"),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {
            Future.delayed(Duration.zero, () {
              provider.addAttribute(entity.id);
              provider.selectItem(entity);
            });
          },
          child: const Row(
            children: [
              Icon(Icons.add, size: 18),
              SizedBox(width: 12),
              Text("Ajouter Attribut"),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () {
            Future.delayed(Duration.zero, () {
              provider.deleteEntity(entity.id);
            });
          },
          child: const Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 12),
              Text("Supprimer", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final scale = provider.textScaleFactor;
    final zoom = widget.zoom;
    final theme = widget.theme;
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    final primaryColor = widget.primaryColor;
    final entity = widget.entity;
    final isSelected = widget.isSelected;

    return MouseRegion(
      cursor: _isDragging
          ? SystemMouseCursors.grabbing
          : SystemMouseCursors.grab,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onPanStart: (details) {
          if (!widget.isLinkMode) {
            provider.setDraggingElement(true);
            setState(() => _isDragging = true);
            _dragStartGlobal = details.globalPosition;
            _initialEntityPos = entity.position;
          }
        },
        onPanUpdate: (details) {
          if (!widget.isLinkMode &&
              _dragStartGlobal != null &&
              _initialEntityPos != null) {
            final delta = (details.globalPosition - _dragStartGlobal!) / zoom;
            provider.updateEntityPosition(
              entity.id,
              _initialEntityPos! + delta,
              snap: false,
            );
          }
        },
        onPanEnd: (_) {
          if (!widget.isLinkMode) {
            provider.setDraggingElement(false);
            setState(() => _isDragging = false);
            provider.updateEntityPosition(
              entity.id,
              entity.position,
              isFinal: true,
              snap: true,
            );
            _dragStartGlobal = null;
            _initialEntityPos = null;
          }
        },
        onPanCancel: () {
          if (!widget.isLinkMode) {
            provider.setDraggingElement(false);
            setState(() => _isDragging = false);
            _dragStartGlobal = null;
            _initialEntityPos = null;
          }
        },
        onTap: () {
          if (widget.isLinkMode) {
            if (provider.linkSourceId == null) {
              provider.startLink(entity.id);
            } else {
              provider.completeLink(entity.id);
            }
          } else {
            final isShift = HardwareKeyboard.instance.isShiftPressed;
            if (isShift) {
              provider.toggleSelection(entity.id);
            } else {
              widget.onTap();
            }
          }
        },
        onDoubleTap: () {
          provider.selectItem(entity);
        },
        onSecondaryTapDown: (details) {
          provider.selectItem(entity);
          _showContextMenu(context, details.globalPosition);
        },
        onLongPress: () {
          if (!widget.isLinkMode) {
            provider.toggleSelection(entity.id);
          }
        },
        child: Container(
          width: 150 * zoom * scale,
          decoration: BoxDecoration(
            color: ThemeColors.sidebarBg(theme),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : (_isHovered
                        ? primaryColor.withValues(alpha: 0.5)
                        : (isDark
                              ? const Color(0xFFF8F7F5).withValues(alpha: 0.5)
                              : const Color(
                                  0xFF333333,
                                ).withValues(alpha: 0.5))),
              width: (isSelected || _isHovered ? 2.0 : 1.0) * zoom,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.3)
                    : (_isHovered
                          ? primaryColor.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1)),
                blurRadius: (isSelected || _isHovered) ? 8 * zoom : 4 * zoom,
                spreadRadius: isSelected ? 2 * zoom : 0,
                offset: isSelected ? Offset.zero : Offset(0, 2 * zoom),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * zoom,
                  vertical: 4 * zoom,
                ),
                decoration: BoxDecoration(
                  color: isSelected || _isHovered
                      ? primaryColor.withValues(alpha: 0.2)
                      : primaryColor.withValues(alpha: 0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entity.name,
                        style: TextStyle(
                          fontSize: 10 * zoom * scale,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: ThemeColors.textMain(theme),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      isSelected
                          ? Icons.edit
                          : (_isHovered
                                ? Icons.touch_app
                                : Icons.drag_indicator),
                      size: 10 * zoom * scale,
                      color: isSelected || _isHovered
                          ? primaryColor
                          : Colors.grey,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0 * zoom * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entity.attributes.map((attr) {
                    final isPK = attr.isPrimaryKey;
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 2 * zoom),
                      child: Container(
                        padding: EdgeInsets.only(bottom: isPK ? 2 * zoom : 0),
                        decoration: isPK
                            ? BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: isDark
                                        ? Colors.grey[600]!
                                        : Colors.grey[300]!,
                                    width: 0.5 * zoom,
                                  ),
                                ),
                              )
                            : null,
                        child: Row(
                          children: [
                            if (isPK)
                              Icon(
                                Icons.key,
                                size: 8 * zoom * scale,
                                color: primaryColor,
                              ),
                            if (isPK) SizedBox(width: 4 * zoom),
                            Expanded(
                              child: Text(
                                attr.name,
                                style: TextStyle(
                                  fontSize: 10 * zoom * scale,
                                  fontWeight: isPK
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: ThemeColors.textMain(
                                    theme,
                                  ).withValues(alpha: 0.8),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RelationWidget extends StatefulWidget {
  final McdRelation relation;
  final AppTheme theme;
  final bool isSelected;
  final double zoom;
  final bool isLinkMode;
  final MeriseProvider provider;
  final VoidCallback onTap;

  const _RelationWidget({
    required this.relation,
    required this.theme,
    required this.provider,
    required this.onTap,
    this.isSelected = false,
    this.zoom = 1.0,
    this.isLinkMode = false,
  });

  @override
  State<_RelationWidget> createState() => _RelationWidgetState();
}

class _RelationWidgetState extends State<_RelationWidget> {
  Offset? _dragStartGlobal;
  Offset? _initialRelationPos;
  bool _isHovered = false;
  bool _isDragging = false;

  void _showContextMenu(BuildContext context, Offset globalPos) {
    final provider = widget.provider;
    final relation = widget.relation;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<void>(
      context: context,
      position: RelativeRect.fromRect(
        globalPos & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          onTap: () => provider.selectItem(relation),
          child: const Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 12),
              Text("Éditer"),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {
            Future.delayed(Duration.zero, () {
              provider.addAttribute(relation.id);
              provider.selectItem(relation);
            });
          },
          child: const Row(
            children: [
              Icon(Icons.add, size: 18),
              SizedBox(width: 12),
              Text("Ajouter Attribut"),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () {
            Future.delayed(Duration.zero, () {
              provider.deleteRelation(relation.id);
            });
          },
          child: const Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 12),
              Text("Supprimer", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final zoom = widget.zoom;
    final theme = widget.theme;
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    final relation = widget.relation;
    final isSelected = widget.isSelected;
    final provider = widget.provider;
    final scale = provider.textScaleFactor;

    return MouseRegion(
      cursor: _isDragging
          ? SystemMouseCursors.grabbing
          : SystemMouseCursors.grab,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onPanStart: (details) {
          if (!widget.isLinkMode) {
            provider.setDraggingElement(true);
            setState(() => _isDragging = true);
            _dragStartGlobal = details.globalPosition;
            _initialRelationPos = relation.position;
          }
        },
        onPanUpdate: (details) {
          if (!widget.isLinkMode &&
              _dragStartGlobal != null &&
              _initialRelationPos != null) {
            final delta = (details.globalPosition - _dragStartGlobal!) / zoom;
            provider.updateRelationPosition(
              relation.id,
              _initialRelationPos! + delta,
              snap: false,
            );
          }
        },
        onPanEnd: (_) {
          if (!widget.isLinkMode) {
            provider.setDraggingElement(false);
            setState(() => _isDragging = false);
            provider.updateRelationPosition(
              relation.id,
              relation.position,
              isFinal: true,
              snap: true,
            );
            _dragStartGlobal = null;
            _initialRelationPos = null;
          }
        },
        onPanCancel: () {
          if (!widget.isLinkMode) {
            provider.setDraggingElement(false);
            setState(() => _isDragging = false);
            _dragStartGlobal = null;
            _initialRelationPos = null;
          }
        },
        onTap: () {
          if (widget.isLinkMode) {
            if (provider.linkSourceId == null) {
              provider.startLink(relation.id);
            } else {
              provider.completeLink(relation.id);
            }
          } else {
            final isShift = HardwareKeyboard.instance.isShiftPressed;
            if (isShift) {
              provider.toggleSelection(relation.id);
            } else {
              widget.onTap();
            }
          }
        },
        onDoubleTap: () {
          provider.selectItem(relation);
        },
        onSecondaryTapDown: (details) {
          provider.selectItem(relation);
          _showContextMenu(context, details.globalPosition);
        },
        onLongPress: () {
          if (!widget.isLinkMode) {
            provider.toggleSelection(relation.id);
          }
        },
        child: Container(
          width: (relation.attributes.isEmpty ? 45 : 140) * zoom * scale,
          decoration: BoxDecoration(
            color: ThemeColors.sidebarBg(theme),
            borderRadius: BorderRadius.circular(
              45 * zoom * scale,
            ), // Oval/Stadium shape
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1E88E5)
                  : (_isHovered
                        ? const Color(0xFF1E88E5).withValues(alpha: 0.5)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.black.withValues(alpha: 0.5))),
              width: (isSelected || _isHovered ? 2.0 : 1.0) * zoom,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF1E88E5).withValues(alpha: 0.3)
                    : (_isHovered
                          ? const Color(0xFF1E88E5).withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1)),
                blurRadius: (isSelected || _isHovered) ? 10 * zoom : 4 * zoom,
                spreadRadius: isSelected ? 2 * zoom : 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 45 * zoom * scale,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 4 * zoom * scale),
                child: Text(
                  relation.name,
                  style: TextStyle(
                    fontSize: 7 * zoom * scale,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.textMain(theme),
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              if (relation.attributes.isNotEmpty) ...[
                Divider(
                  height: 1,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0 * zoom * scale,
                    vertical: 8.0 * zoom * scale,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: relation.attributes.map((attr) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 1 * zoom),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (attr.isPrimaryKey)
                              Icon(
                                Icons.key,
                                size: 6 * zoom * scale,
                                color: const Color(0xFF1E88E5),
                              ),
                            if (attr.isPrimaryKey) SizedBox(width: 2 * zoom),
                            Text(
                              attr.name,
                              style: TextStyle(
                                fontSize: 7 * zoom * scale,
                                color: ThemeColors.textMain(
                                  theme,
                                ).withValues(alpha: 0.8),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final AppTheme theme;
  final String tooltip;
  final VoidCallback onTap;
  const _ToolbarButton(
    this.icon,
    this.theme, {
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlignmentButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final AppTheme theme;

  const _AlignmentButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20, color: ThemeColors.textMain(theme)),
      tooltip: tooltip,
      onPressed: onTap,
      splashRadius: 20,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}
