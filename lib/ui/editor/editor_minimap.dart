import 'package:flutter/material.dart';
import 'package:pseudo_code/interpreteur/linter.dart';
import '../../theme.dart';

class EditorMinimap extends StatelessWidget {
  final ScrollController scrollController;
  final TextSpan textSpan;
  final AppTheme theme;
  final List<LintIssue> lintIssues;
  final int? executionErrorLine;

  const EditorMinimap({
    super.key,
    required this.scrollController,
    required this.textSpan,
    required this.theme,
    this.lintIssues = const [],
    this.executionErrorLine,
  });

  @override
  Widget build(BuildContext context) {
    // Calcul de la hauteur de ligne dans la minimap
    // fontSize 3 * height 1.5 = 4.5
    const double minimapLineHeight = 4.5;
    const double minimapTopPadding = 12.0;

    return Container(
      width: 60,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        color: ThemeColors.editorBg(theme).withValues(alpha: 0.5),
      ),
      child: IgnorePointer(
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: minimapTopPadding,
                ),
                child: Text.rich(textSpan),
              ),
            ),
            // Indicateurs d'erreurs
            _buildErrorIndicators(minimapLineHeight, minimapTopPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorIndicators(double lineHeight, double topPadding) {
    final Set<int> errorLines = {};
    for (var issue in lintIssues) {
      if (issue.type == LintType.error) {
        errorLines.add(issue.line);
      }
    }
    if (executionErrorLine != null) {
      errorLines.add(executionErrorLine!);
    }

    if (errorLines.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final double scrollOffset = scrollController.hasClients
            ? scrollController.offset
            : 0.0;

        return Stack(
          children: errorLines.map((line) {
            final double top =
                (line - 1) * lineHeight + topPadding - scrollOffset;

            // On ne dessine que si c'est visible (approximatif pour performance)
            if (top < -10 || top > 1000) return const SizedBox.shrink();

            return Positioned(
              top: top + 1, // Petit ajustement centrage vertical
              right: 2,
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red,
                      blurRadius: 2,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
