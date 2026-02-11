import 'package:flutter/material.dart';
import '../../theme.dart';

class EditorGutter extends StatelessWidget {
  final int lineCount;
  final ScrollController scrollController;
  final bool isMobile;
  final AppTheme theme;
  final Set<int> breakpoints;
  final int? currentHighlightLine;
  final int? errorLine;
  final Set<int> addedLines;
  final Set<int> deletedLines;
  final double fontSize;
  final Function(int) onToggleBreakpoint;
  final Function(int) onToggleFold;
  final bool Function(int) isLineVisible;
  final Set<int> foldableLines;
  final Map<int, bool> foldedLines;

  const EditorGutter({
    super.key,
    required this.lineCount,
    required this.scrollController,
    required this.isMobile,
    required this.theme,
    required this.breakpoints,
    required this.currentHighlightLine,
    required this.errorLine,
    required this.addedLines,
    required this.deletedLines,
    required this.fontSize,
    required this.onToggleBreakpoint,
    required this.onToggleFold,
    required this.isLineVisible,
    required this.foldableLines,
    required this.foldedLines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isMobile ? 30 : 45,
      padding: const EdgeInsets.only(top: 12),
      color: ThemeColors.sidebarBg(theme),
      child: ListView.builder(
        controller: scrollController,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: lineCount,
        itemBuilder: (context, i) {
          final lineNum = i + 1;
          if (!isLineVisible(lineNum)) {
            return const SizedBox.shrink();
          }

          final hasBreakpoint = breakpoints.contains(lineNum);
          final isCurrentLine = currentHighlightLine == lineNum;
          final hasError = errorLine == lineNum;
          final isAdded = addedLines.contains(lineNum);
          final isDeleted = deletedLines.contains(lineNum);

          return InkWell(
            onTap: () => onToggleBreakpoint(lineNum),
            child: Container(
              height: fontSize * 1.5,
              color: isAdded
                  ? Colors.green.withValues(alpha: 0.1)
                  : (isDeleted ? Colors.red.withValues(alpha: 0.1) : null),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    alignment: Alignment.center,
                    child: isAdded
                        ? const Text(
                            "+",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : (isDeleted
                              ? const Text(
                                  "-",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : (hasError
                                    ? const Icon(
                                        Icons.error_outline,
                                        size: 10,
                                        color: Colors.redAccent,
                                      )
                                    : (hasBreakpoint
                                          ? Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                            )
                                          : (foldableLines.contains(lineNum) &&
                                                    !isMobile
                                                ? InkWell(
                                                    onTap: () =>
                                                        onToggleFold(lineNum),
                                                    child: Icon(
                                                      foldedLines[lineNum] ==
                                                              true
                                                          ? Icons.chevron_right
                                                          : Icons.expand_more,
                                                      size: 14,
                                                      color: Colors.white38,
                                                    ),
                                                  )
                                                : null)))),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$lineNum',
                        style: TextStyle(
                          color: isCurrentLine
                              ? Colors.white
                              : (isAdded
                                    ? Colors.green
                                    : (isDeleted
                                          ? Colors.red
                                          : ThemeColors.textMain(
                                              theme,
                                            ).withValues(alpha: 0.3))),
                          fontSize: 12,
                          fontFamily: 'JetBrainsMono',
                          fontWeight: (isCurrentLine || isAdded || isDeleted)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
