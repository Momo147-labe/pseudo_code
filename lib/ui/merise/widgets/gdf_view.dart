import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../providers/merise_provider.dart';
import '../../../theme.dart';
import '../../../merise/mcd_models.dart';

class GdfView extends StatefulWidget {
  final AppTheme theme;
  const GdfView({super.key, required this.theme});

  @override
  State<GdfView> createState() => _GdfViewState();
}

class _GdfViewState extends State<GdfView> {
  final List<String> _selectedSources = [];
  final List<String> _selectedTargets = [];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeriseProvider>();
    final mcd = provider.mcd;
    final isDark =
        widget.theme != AppTheme.light && widget.theme != AppTheme.papier;
    final scale = provider.textScaleFactor;

    // Get all unique attributes from MCD
    final Set<String> allAttributes = {};
    for (final entity in mcd.entities) {
      for (final attr in entity.attributes) {
        allAttributes.add(attr.name);
      }
    }
    for (final relation in mcd.relations) {
      for (final attr in relation.attributes) {
        allAttributes.add(attr.name);
      }
    }
    final sortedAttributes = allAttributes.toList()..sort();

    final isMobile = MediaQuery.of(context).size.width < 768;

    final editorPanel = Container(
      width: isMobile ? double.infinity : 350 * scale,
      height: isMobile ? 400 : null,
      decoration: BoxDecoration(
        border: Border(
          right: !isMobile
              ? BorderSide(color: isDark ? Colors.white10 : Colors.black12)
              : BorderSide.none,
          bottom: isMobile
              ? BorderSide(color: isDark ? Colors.white10 : Colors.black12)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Dépendances Fonctionnelles",
              style: TextStyle(
                fontSize: (isMobile ? 16 : 18) * scale,
                fontWeight: FontWeight.bold,
                color: ThemeColors.textMain(widget.theme),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildAddDfSection(sortedAttributes, scale, provider),
                const Divider(height: 32),
                Text(
                  "Liste des dépendances",
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.textMain(
                      widget.theme,
                    ).withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                ...provider.functionalDependencies.map(
                  (df) => _buildDfItem(df, scale, provider),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final graphPanel = Expanded(
      child: _GdfGraph(
        dependencies: provider.functionalDependencies,
        attributes: sortedAttributes,
        theme: widget.theme,
        scale: scale,
      ),
    );

    return Container(
      color: ThemeColors.editorBg(widget.theme),
      child: isMobile
          ? Column(children: [editorPanel, graphPanel])
          : Row(children: [editorPanel, graphPanel]),
    );
  }

  Widget _buildAddDfSection(
    List<String> attributes,
    double scale,
    MeriseProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ajouter une DF",
          style: TextStyle(
            fontSize: 14 * scale,
            fontWeight: FontWeight.w600,
            color: ThemeColors.textMain(widget.theme),
          ),
        ),
        const SizedBox(height: 12),
        _buildAttributeSelector(
          "Sources (Déterminants)",
          attributes,
          _selectedSources,
          scale,
        ),
        const SizedBox(height: 8),
        Center(
          child: Icon(
            Icons.arrow_downward,
            color: Colors.blue.withValues(alpha: 0.5),
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        _buildAttributeSelector(
          "Cibles (Dépendants)",
          attributes,
          _selectedTargets,
          scale,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                (_selectedSources.isNotEmpty && _selectedTargets.isNotEmpty)
                ? () {
                    provider.addFunctionalDependency(
                      List.from(_selectedSources),
                      List.from(_selectedTargets),
                    );
                    setState(() {
                      _selectedSources.clear();
                      _selectedTargets.clear();
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text("Ajouter la DF"),
          ),
        ),
      ],
    );
  }

  Widget _buildAttributeSelector(
    String label,
    List<String> allAttr,
    List<String> selection,
    double scale,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11 * scale,
            color: ThemeColors.textMain(widget.theme).withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: widget.theme == AppTheme.dracula
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              ...selection.map(
                (attr) => Chip(
                  label: Text(attr, style: const TextStyle(fontSize: 10)),
                  onDeleted: () => setState(() => selection.remove(attr)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: Colors.blue,
                ),
                onSelected: (val) {
                  if (!selection.contains(val)) {
                    setState(() => selection.add(val));
                  }
                },
                itemBuilder: (context) => allAttr
                    .map((a) => PopupMenuItem(value: a, child: Text(a)))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDfItem(
    McdFunctionalDependency df,
    double scale,
    MeriseProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.theme == AppTheme.dracula
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 4,
                  children: [
                    Text(
                      df.sourceAttributes.join(", "),
                      style: TextStyle(
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Colors.grey,
                    ),
                    Text(
                      df.targetAttributes.join(", "),
                      style: TextStyle(
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.textMain(widget.theme),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red,
                ),
                onPressed: () => provider.deleteFunctionalDependency(df.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GdfGraph extends StatelessWidget {
  final List<McdFunctionalDependency> dependencies;
  final List<String> attributes;
  final AppTheme theme;
  final double scale;

  const _GdfGraph({
    required this.dependencies,
    required this.attributes,
    required this.theme,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Simple layout: attributes on a circle
        final Map<String, Offset> positions = {};
        final center = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight / 2,
        );
        final radius =
            math.min(constraints.maxWidth, constraints.maxHeight) * 0.35;

        for (int i = 0; i < attributes.length; i++) {
          final angle = (i * 2 * math.pi) / attributes.length;
          positions[attributes[i]] = Offset(
            center.dx + radius * math.cos(angle),
            center.dy + radius * math.sin(angle),
          );
        }

        return Stack(
          children: [
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _GdfPainter(
                dependencies: dependencies,
                positions: positions,
                theme: theme,
              ),
            ),
            ...attributes.map((attr) {
              final pos = positions[attr]!;
              return Positioned(
                left: pos.dx - 40 * scale,
                top: pos.dy - 15 * scale,
                child: Container(
                  width: 80 * scale,
                  height: 30 * scale,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ThemeColors.sidebarBg(theme),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    attr,
                    style: TextStyle(
                      fontSize: 10 * scale,
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.textMain(theme),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _GdfPainter extends CustomPainter {
  final List<McdFunctionalDependency> dependencies;
  final Map<String, Offset> positions;
  final AppTheme theme;

  _GdfPainter({
    required this.dependencies,
    required this.positions,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final df in dependencies) {
      // For simplicity, we draw lines from each source to each target
      for (final src in df.sourceAttributes) {
        for (final tgt in df.targetAttributes) {
          if (positions.containsKey(src) && positions.containsKey(tgt)) {
            final start = positions[src]!;
            final end = positions[tgt]!;

            _drawArrowLine(canvas, start, end, paint);
          }
        }
      }
    }
  }

  void _drawArrowLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    if (start == end)
      return; // Prevent division by zero if source and target are the same

    final direction = end - start;
    final distance = direction.distance;

    // Safely calculate unit direction
    if (distance <= 0) return;

    final unitDirection = direction / distance;
    final p1 = start + unitDirection * 40; // Offset from center of source
    final p2 = end - unitDirection * 40; // Offset from center of target

    // Ensure points are valid before drawing
    if (p1.dx.isNaN || p1.dy.isNaN || p2.dx.isNaN || p2.dy.isNaN) return;

    canvas.drawLine(p1, p2, paint);

    // Draw arrow head
    final angle = math.atan2(direction.dy, direction.dx);
    const arrowSize = 8.0;
    final path = Path()
      ..moveTo(p2.dx, p2.dy)
      ..lineTo(
        p2.dx - arrowSize * math.cos(angle - math.pi / 6),
        p2.dy - arrowSize * math.sin(angle - math.pi / 6),
      )
      ..lineTo(
        p2.dx - arrowSize * math.cos(angle + math.pi / 6),
        p2.dy - arrowSize * math.sin(angle + math.pi / 6),
      )
      ..close();

    final headPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, headPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
