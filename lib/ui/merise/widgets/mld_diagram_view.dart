import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../merise/mld_transformer.dart';
import '../../../merise/mcd_models.dart';
import '../../../providers/merise_provider.dart';
import '../../../theme.dart';

class MldDiagramView extends StatefulWidget {
  final AppTheme theme;
  final bool isMobile;

  const MldDiagramView({super.key, required this.theme, this.isMobile = false});

  @override
  State<MldDiagramView> createState() => _MldDiagramViewState();
}

class _MldDiagramViewState extends State<MldDiagramView> {
  double _initialZoom = 1.0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeriseProvider>();
    final mcd = provider.mcd;
    final mld = MldTransformer.transform(mcd);
    final zoom = provider.zoom;
    final scale = provider.textScaleFactor;
    final panOffset = provider.panOffset;

    // Fond gris clair comme sur l'image
    final bgColor = widget.theme == AppTheme.light
        ? const Color(0xFFF0F0F0)
        : ThemeColors.editorBg(widget.theme);

    return Container(
      color: bgColor,
      child: GestureDetector(
        onScaleStart: (details) {
          _initialZoom = provider.zoom;
        },
        onScaleUpdate: (details) {
          if (details.pointerCount == 2) {
            provider.setZoom(_initialZoom * details.scale);
          } else if (details.pointerCount == 1 && !provider.isDraggingElement) {
            provider.updatePanOffset(details.focalPointDelta / zoom);
          }
        },
        onTap: () => provider.selectItem(null),
        child: ClipRect(
          child: Stack(
            children: [
              // Calque des flèches
              Positioned.fill(
                child: Transform.translate(
                  offset: panOffset * zoom,
                  child: CustomPaint(
                    painter: _MldArrowPainter(
                      mld: mld,
                      mcd: mcd,
                      zoom: zoom,
                      scale: scale,
                      isDark: widget.theme != AppTheme.light,
                    ),
                  ),
                ),
              ),

              // Calque des tables
              Positioned.fill(
                child: Transform.translate(
                  offset: panOffset * zoom,
                  child: Stack(
                    children: mld.tables.map((table) {
                      final pos = _getTablePosition(table, mcd);
                      return Positioned(
                        left: pos.dx * zoom,
                        top: pos.dy * zoom,
                        child: _MldTableWidget(
                          table: table,
                          theme: widget.theme,
                          zoom: zoom,
                          scale: scale,
                          provider: provider,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Offset _getTablePosition(MldTable table, Mcd mcd) {
    if (table.sourceId != null) {
      // Rechercher dans les entités
      final entity = mcd.entities.where((e) => e.id == table.sourceId).toList();
      if (entity.isNotEmpty) return entity.first.position;

      // Rechercher dans les relations
      final relation = mcd.relations
          .where((r) => r.id == table.sourceId)
          .toList();
      if (relation.isNotEmpty) return relation.first.position;
    }
    // Fallback par défaut si pas trouvé
    return Offset.zero;
  }
}

class _MldTableWidget extends StatefulWidget {
  final MldTable table;
  final AppTheme theme;
  final double zoom;
  final double scale;
  final MeriseProvider provider;

  const _MldTableWidget({
    required this.table,
    required this.theme,
    required this.zoom,
    required this.scale,
    required this.provider,
  });

  @override
  State<_MldTableWidget> createState() => _MldTableWidgetState();
}

class _MldTableWidgetState extends State<_MldTableWidget> {
  Offset? _dragStartGlobal;
  Offset? _initialPos;
  bool _isDragging = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final table = widget.table;
    final provider = widget.provider;
    final zoom = widget.zoom;
    final scale = widget.scale;
    final theme = widget.theme;
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;

    final width = 180.0 * zoom * scale;

    // Style inspiré de l'image
    final headerColor = isDark
        ? (_isDragging || _isHovered
              ? const Color(0xFF444444)
              : const Color(0xFF333333))
        : (_isDragging || _isHovered
              ? const Color(0xFFA0A0A0)
              : const Color(0xFFB0B0B0));
    final bodyColor = isDark
        ? const Color(0xFF252525)
        : const Color(0xFFD9D9D9);
    final borderColor = isDark
        ? (_isDragging || _isHovered ? Colors.blueAccent : Colors.white24)
        : (_isDragging || _isHovered ? Colors.blue[800]! : Colors.black45);
    final textColor = isDark ? Colors.white : Colors.black;

    return MouseRegion(
      cursor: _isDragging
          ? SystemMouseCursors.grabbing
          : SystemMouseCursors.grab,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onPanStart: (details) {
          if (table.sourceId != null) {
            provider.setDraggingElement(true);
            setState(() => _isDragging = true);
            _dragStartGlobal = details.globalPosition;

            // Trouver la position initiale
            final mcd = provider.mcd;
            final entity = mcd.entities
                .where((e) => e.id == table.sourceId)
                .toList();
            if (entity.isNotEmpty) {
              _initialPos = entity.first.position;
            } else {
              final relation = mcd.relations
                  .where((r) => r.id == table.sourceId)
                  .toList();
              if (relation.isNotEmpty) _initialPos = relation.first.position;
            }
          }
        },
        onPanUpdate: (details) {
          if (_isDragging &&
              _dragStartGlobal != null &&
              _initialPos != null &&
              table.sourceId != null) {
            final delta = (details.globalPosition - _dragStartGlobal!) / zoom;
            final newPos = _initialPos! + delta;

            if (table.sourceId!.startsWith('e')) {
              provider.updateEntityPosition(
                table.sourceId!,
                newPos,
                snap: false,
              );
            } else {
              provider.updateRelationPosition(
                table.sourceId!,
                newPos,
                snap: false,
              );
            }
          }
        },
        onPanEnd: (_) {
          if (_isDragging && table.sourceId != null) {
            provider.setDraggingElement(false);
            setState(() => _isDragging = false);

            // Snapper la position à la fin
            final mcd = provider.mcd;
            Offset finalPos = Offset.zero;
            if (table.sourceId!.startsWith('e')) {
              finalPos = mcd.entities
                  .firstWhere((e) => e.id == table.sourceId)
                  .position;
              provider.updateEntityPosition(
                table.sourceId!,
                finalPos,
                isFinal: true,
                snap: true,
              );
            } else {
              finalPos = mcd.relations
                  .firstWhere((r) => r.id == table.sourceId)
                  .position;
              provider.updateRelationPosition(
                table.sourceId!,
                finalPos,
                isFinal: true,
                snap: true,
              );
            }

            _dragStartGlobal = null;
            _initialPos = null;
          }
        },
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: bodyColor,
            border: Border.all(
              color: borderColor,
              width: (_isDragging || _isHovered ? 1.5 : 1.0) * zoom,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isDragging ? 0.2 : 0.1),
                blurRadius: (_isDragging ? 8 : 4) * zoom,
                offset: Offset(2 * zoom, 2 * zoom),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header (Nom de la table)
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: 8 * zoom * scale,
                  horizontal: 10 * zoom * scale,
                ),
                decoration: BoxDecoration(
                  color: headerColor,
                  border: Border(
                    bottom: BorderSide(color: borderColor, width: 1.0 * zoom),
                  ),
                ),
                child: Text(
                  table.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13 * zoom * scale,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),

              // Colonnes
              Padding(
                padding: EdgeInsets.all(8 * zoom * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: table.columns.map((col) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 2 * zoom * scale),
                      child: Text(
                        col.name,
                        style: TextStyle(
                          fontSize: 12 * zoom * scale,
                          color: col.isForeignKey
                              ? Colors.blue[800]
                              : textColor,
                          fontWeight: col.isPrimaryKey
                              ? FontWeight.bold
                              : FontWeight.normal,
                          decoration: col.isPrimaryKey
                              ? TextDecoration.underline
                              : null,
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

class _MldArrowPainter extends CustomPainter {
  final Mld mld;
  final Mcd mcd;
  final double zoom;
  final double scale;
  final bool isDark;

  _MldArrowPainter({
    required this.mld,
    required this.mcd,
    required this.zoom,
    required this.scale,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.blue[300]! : Colors.blue[900]!
      ..strokeWidth = 1.5 * zoom
      ..style = PaintingStyle.stroke;

    final arrowPaint = Paint()
      ..color = isDark ? Colors.blue[300]! : Colors.blue[900]!
      ..style = PaintingStyle.fill;

    const tableWidth = 180.0;

    for (final table in mld.tables) {
      if (table.foreignKeys.isEmpty) continue;

      final startPos = _getTablePosition(table, mcd);
      final startSize = Size(
        tableWidth * scale,
        (35 + table.columns.length * 20) * scale,
      );

      for (final fk in table.foreignKeys) {
        final targetTable = mld.tables
            .where((t) => t.name == fk.referencedTable)
            .toList();
        if (targetTable.isEmpty) continue;

        final endPos = _getTablePosition(targetTable.first, mcd);
        final endSize = Size(
          tableWidth * scale,
          (35 + targetTable.first.columns.length * 20) * scale,
        );

        // Calculer les points d'ancrage
        final start = _getRectIntersection(
          startPos * zoom,
          startSize * zoom,
          endPos * zoom + Offset(tableWidth * scale * zoom / 2, 20 * zoom),
        );
        final end = _getRectIntersection(
          endPos * zoom,
          endSize * zoom,
          startPos * zoom + Offset(tableWidth * scale * zoom / 2, 20 * zoom),
        );

        _drawArrow(canvas, start, end, paint, arrowPaint);
      }
    }
  }

  void _drawArrow(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint linePaint,
    Paint arrowPaint,
  ) {
    // Dessiner la ligne
    canvas.drawLine(start, end, linePaint);

    // Dessiner la pointe de la flèche
    final d = end - start;
    final angle = math.atan2(d.dy, d.dx);
    const arrowSize = 10.0;

    final p1 = Offset(
      end.dx - arrowSize * zoom * math.cos(angle - math.pi / 6),
      end.dy - arrowSize * zoom * math.sin(angle - math.pi / 6),
    );
    final p2 = Offset(
      end.dx - arrowSize * zoom * math.cos(angle + math.pi / 6),
      end.dy - arrowSize * zoom * math.sin(angle + math.pi / 6),
    );

    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();

    canvas.drawPath(path, arrowPaint);
  }

  Offset _getTablePosition(MldTable table, Mcd mcd) {
    if (table.sourceId != null) {
      final entity = mcd.entities.where((e) => e.id == table.sourceId).toList();
      if (entity.isNotEmpty) return entity.first.position;

      final relation = mcd.relations
          .where((r) => r.id == table.sourceId)
          .toList();
      if (relation.isNotEmpty) return relation.first.position;
    }
    return Offset.zero;
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
      return Offset(
        center.dx + (dx > 0 ? halfWidth : -halfWidth),
        center.dy + dy * halfWidth / absDx,
      );
    } else {
      return Offset(
        center.dx + dx * halfHeight / absDy,
        center.dy + (dy > 0 ? halfHeight : -halfHeight),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MldArrowPainter oldDelegate) =>
      oldDelegate.mld != mld ||
      oldDelegate.zoom != zoom ||
      oldDelegate.scale != scale;
}
