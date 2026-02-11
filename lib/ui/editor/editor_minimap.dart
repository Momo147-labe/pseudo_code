import 'package:flutter/material.dart';
import '../../theme.dart';

class EditorMinimap extends StatelessWidget {
  final ScrollController scrollController;
  final TextSpan textSpan;
  final AppTheme theme;

  const EditorMinimap({
    super.key,
    required this.scrollController,
    required this.textSpan,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
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
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text.rich(textSpan),
          ),
        ),
      ),
    );
  }
}
