import 'package:flutter/material.dart';

enum AppTheme { dark, light, dracula, oneDark, papier }

class ThemeColors {
  static Color editorBg(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return const Color(0xFFFFFFFF);
      case AppTheme.dracula:
        return const Color(0xFF282A36);
      case AppTheme.oneDark:
        return const Color(0xFF282C34);
      case AppTheme.papier:
        return const Color(0xFFFBF1C7);
      default:
        return const Color(0xFF1E1E1E);
    }
  }

  static Color sidebarBg(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return const Color(0xFFF3F3F3);
      case AppTheme.dracula:
        return const Color(0xFF191A21);
      case AppTheme.oneDark:
        return const Color(0xFF21252B);
      case AppTheme.papier:
        return const Color(0xFFEBDBB2);
      default:
        return const Color(0xFF252526);
    }
  }

  static Color activityBarBg(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return const Color(0xFF2C2C2C);
      case AppTheme.dracula:
        return const Color(0xFF21222C);
      case AppTheme.oneDark:
        return const Color(0xFF181A1F);
      case AppTheme.papier:
        return const Color(0xFFD5C4A1);
      default:
        return const Color(0xFF333333);
    }
  }

  static Color topbarBg(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return const Color(0xFFDDDDDD);
      case AppTheme.dracula:
        return const Color(0xFF21222C);
      case AppTheme.oneDark:
        return const Color(0xFF21252B);
      case AppTheme.papier:
        return const Color(0xFFD5C4A1);
      default:
        return const Color(0xFF2D2D2D);
    }
  }

  static Color textMain(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return const Color(0xFF333333);
      case AppTheme.dracula:
        return const Color(0xFFF8F8F2);
      case AppTheme.oneDark:
        return const Color(0xFFABB2BF);
      case AppTheme.papier:
        return const Color(0xFF3C3836);
      default:
        return const Color(0xFFCCCCCC);
    }
  }

  static Color textBright(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return Colors.black;
      case AppTheme.dracula:
        return const Color(0xFFF8F8F2);
      case AppTheme.oneDark:
        return Colors.white;
      case AppTheme.papier:
        return const Color(0xFF282828);
      default:
        return Colors.white;
    }
  }

  // Syntax Highlighting
  static Color syntaxKeyword(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return const Color(0xFFAF00DB);
      case AppTheme.dracula:
        return const Color(0xFFFF79C6);
      case AppTheme.oneDark:
        return const Color(0xFFC678DD);
      case AppTheme.papier:
        return const Color(0xFF9D0006);
      default:
        return const Color(0xFFC586C0);
    }
  }

  static Color syntaxType(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return const Color(0xFF267F99);
      case AppTheme.dracula:
        return const Color(0xFF8BE9FD);
      case AppTheme.oneDark:
        return const Color(0xFFE5C07B);
      case AppTheme.papier:
        return const Color(0xFF076678);
      default:
        return const Color(0xFF4EC9B0);
    }
  }

  static Color syntaxString(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return const Color(0xFFA31515);
      case AppTheme.dracula:
        return const Color(0xFFF1FA8C);
      case AppTheme.oneDark:
        return const Color(0xFF98C379);
      case AppTheme.papier:
        return const Color(0xFF79740E);
      default:
        return const Color(0xFFCE9178);
    }
  }

  static Color syntaxComment(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return const Color(0xFF008000);
      case AppTheme.dracula:
        return const Color(0xFF6272A4);
      case AppTheme.oneDark:
        return const Color(0xFF5C6370);
      case AppTheme.papier:
        return const Color(0xFF928374);
      default:
        return const Color(0xFF6A9955);
    }
  }

  static Color syntaxNumber(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return const Color(0xFF098658);
      case AppTheme.dracula:
        return const Color(0xFFBD93F9);
      case AppTheme.oneDark:
        return const Color(0xFFD19A66);
      case AppTheme.papier:
        return const Color(0xFF8F3F71);
      default:
        return const Color(0xFFB5CEA8);
    }
  }

  static Color syntaxVariable(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return const Color(0xFF795E26);
      case AppTheme.dracula:
        return const Color(0xFFF8F8F2);
      case AppTheme.oneDark:
        return const Color(0xFFE06C75);
      case AppTheme.papier:
        return const Color(0xFF076678);
      default:
        return const Color(0xFF9CDCFE);
    }
  }

  static Color syntaxStructure(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return const Color(0xFF795E26);
      case AppTheme.dracula:
        return const Color(0xFFBD93F9);
      case AppTheme.oneDark:
        return const Color(0xFF61AFEF);
      case AppTheme.papier:
        return const Color(0xFFB57614);
      default:
        return const Color(0xFFDCDCAA);
    }
  }

  static Color syntaxIO(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return const Color(0xFF0000FF);
      case AppTheme.dracula:
        return const Color(0xFF50FA7B);
      case AppTheme.oneDark:
        return const Color(0xFF56B6C2);
      case AppTheme.papier:
        return const Color(0xFF427B58);
      default:
        return const Color(0xFF4FC1FF);
    }
  }

  static const vscodeBlue = Color(0xFF007ACC);
  static const borderColor = Color(0xFF3C3C3C);
}
