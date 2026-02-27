import 'package:flutter/material.dart';

enum AppTheme { dark, light, dracula, oneDark, papier, aura, nord, genese }

class AppThemeData {
  final Color editorBg;
  final Color sidebarBg;
  final Color activityBarBg;
  final Color topbarBg;
  final Color textMain;
  final Color textBright;
  final Color syntaxKeyword;
  final Color syntaxType;
  final Color syntaxString;
  final Color syntaxComment;
  final Color syntaxNumber;
  final Color syntaxVariable;
  final Color syntaxStructure;
  final Color syntaxIO;

  const AppThemeData({
    required this.editorBg,
    required this.sidebarBg,
    required this.activityBarBg,
    required this.topbarBg,
    required this.textMain,
    required this.textBright,
    required this.syntaxKeyword,
    required this.syntaxType,
    required this.syntaxString,
    required this.syntaxComment,
    required this.syntaxNumber,
    required this.syntaxVariable,
    required this.syntaxStructure,
    required this.syntaxIO,
  });
}

class ThemeColors {
  static const animationDuration = Duration(milliseconds: 200);

  static final Map<AppTheme, AppThemeData> _themes = {
    AppTheme.dark: const AppThemeData(
      editorBg: Color(0xFF1E1E1E),
      sidebarBg: Color(0xFF252526),
      activityBarBg: Color(0xFF333333),
      topbarBg: Color(0xFF2D2D2D),
      textMain: Color(0xFFCCCCCC),
      textBright: Colors.white,
      syntaxKeyword: Color(0xFFC586C0),
      syntaxType: Color(0xFF4EC9B0),
      syntaxString: Color(0xFFCE9178),
      syntaxComment: Color(0xFF6A9955),
      syntaxNumber: Color(0xFFB5CEA8),
      syntaxVariable: Color(0xFF9CDCFE),
      syntaxStructure: Color(0xFFDCDCAA),
      syntaxIO: Color(0xFF4FC1FF),
    ),
    AppTheme.light: const AppThemeData(
      editorBg: Color(0xFFFFFFFF),
      sidebarBg: Color(0xFFF3F3F3),
      activityBarBg: Color(0xFF2C2C2C),
      topbarBg: Color(0xFFDDDDDD),
      textMain: Color(0xFF333333),
      textBright: Colors.black,
      syntaxKeyword: Color(0xFFAF00DB),
      syntaxType: Color(0xFF267F99),
      syntaxString: Color(0xFFA31515),
      syntaxComment: Color(0xFF008000),
      syntaxNumber: Color(0xFF098658),
      syntaxVariable: Color(0xFF795E26),
      syntaxStructure: Color(0xFF795E26),
      syntaxIO: Color(0xFF0000FF),
    ),
    AppTheme.dracula: const AppThemeData(
      editorBg: Color(0xFF282A36),
      sidebarBg: Color(0xFF191A21),
      activityBarBg: Color(0xFF21222C),
      topbarBg: Color(0xFF21222C),
      textMain: Color(0xFFF8F8F2),
      textBright: Color(0xFFF8F8F2),
      syntaxKeyword: Color(0xFFFF79C6),
      syntaxType: Color(0xFF8BE9FD),
      syntaxString: Color(0xFFF1FA8C),
      syntaxComment: Color(0xFF6272A4),
      syntaxNumber: Color(0xFFBD93F9),
      syntaxVariable: Color(0xFFF8F8F2),
      syntaxStructure: Color(0xFFBD93F9),
      syntaxIO: Color(0xFF50FA7B),
    ),
    AppTheme.oneDark: const AppThemeData(
      editorBg: Color(0xFF282C34),
      sidebarBg: Color(0xFF21252B),
      activityBarBg: Color(0xFF181A1F),
      topbarBg: Color(0xFF21252B),
      textMain: Color(0xFFABB2BF),
      textBright: Colors.white,
      syntaxKeyword: Color(0xFFC678DD),
      syntaxType: Color(0xFFE5C07B),
      syntaxString: Color(0xFF98C379),
      syntaxComment: Color(0xFF5C6370),
      syntaxNumber: Color(0xFFD19A66),
      syntaxVariable: Color(0xFFE06C75),
      syntaxStructure: Color(0xFF61AFEF),
      syntaxIO: Color(0xFF56B6C2),
    ),
    AppTheme.papier: const AppThemeData(
      editorBg: Color(0xFFFBF1C7),
      sidebarBg: Color(0xFFEBDBB2),
      activityBarBg: Color(0xFFD5C4A1),
      topbarBg: Color(0xFFD5C4A1),
      textMain: Color(0xFF3C3836),
      textBright: Color(0xFF282828),
      syntaxKeyword: Color(0xFF9D0006),
      syntaxType: Color(0xFF076678),
      syntaxString: Color(0xFF79740E),
      syntaxComment: Color(0xFF928374),
      syntaxNumber: Color(0xFF8F3F71),
      syntaxVariable: Color(0xFF076678),
      syntaxStructure: Color(0xFFB57614),
      syntaxIO: Color(0xFF427B58),
    ),
    AppTheme.aura: const AppThemeData(
      editorBg: Color(0xFF151515),
      sidebarBg: Color(0xFF111111),
      activityBarBg: Color(0xFF0C0C0C),
      topbarBg: Color(0xFF111111),
      textMain: Color(0xFFEDECEE),
      textBright: Colors.white,
      syntaxKeyword: Color(0xFFA277FF),
      syntaxType: Color(0xFF61FFCA),
      syntaxString: Color(0xFFFFCA85),
      syntaxComment: Color(0xFF6D6D6D),
      syntaxNumber: Color(0xFFF694FF),
      syntaxVariable: Color(0xFFEDECEE),
      syntaxStructure: Color(0xFF82E2FF),
      syntaxIO: Color(0xFF61FFCA),
    ),
    AppTheme.nord: const AppThemeData(
      editorBg: Color(0xFF2E3440),
      sidebarBg: Color(0xFF242933),
      activityBarBg: Color(0xFF2E3440),
      topbarBg: Color(0xFF242933),
      textMain: Color(0xFFD8DEE9),
      textBright: Color(0xFFECEFF4),
      syntaxKeyword: Color(0xFF81A1C1),
      syntaxType: Color(0xFF8FBCBB),
      syntaxString: Color(0xFFA3BE8C),
      syntaxComment: Color(0xFF4C566A),
      syntaxNumber: Color(0xFFB48EAD),
      syntaxVariable: Color(0xFFD8DEE9),
      syntaxStructure: Color(0xFF88C0D0),
      syntaxIO: Color(0xFF8FBCBB),
    ),
    AppTheme.genese: const AppThemeData(
      editorBg: Color(0xFF0B0E14),
      sidebarBg: Color(0xFF0F131A),
      activityBarBg: Color(0xFF0B0E14),
      topbarBg: Color(0xFF0F131A),
      textMain: Color(0xFF707A8C),
      textBright: Color(0xFFB3B1AD),
      syntaxKeyword: Color(0xFFFF8F40),
      syntaxType: Color(0xFF59C2FF),
      syntaxString: Color(0xFFC2D94C),
      syntaxComment: Color(0xFF5C6773),
      syntaxNumber: Color(0xFFFFB454),
      syntaxVariable: Color(0xFFB3B1AD),
      syntaxStructure: Color(0xFF39BAE6),
      syntaxIO: Color(0xFF95E6CB),
    ),
  };

  static AppThemeData _get(AppTheme theme) =>
      _themes[theme] ?? _themes[AppTheme.dark]!;

  static Color editorBg(AppTheme theme) => _get(theme).editorBg;
  static Color sidebarBg(AppTheme theme) => _get(theme).sidebarBg;
  static Color activityBarBg(AppTheme theme) => _get(theme).activityBarBg;
  static Color topbarBg(AppTheme theme) => _get(theme).topbarBg;
  static Color textMain(AppTheme theme) => _get(theme).textMain;
  static Color textBright(AppTheme theme) => _get(theme).textBright;
  static Color syntaxKeyword(AppTheme theme) => _get(theme).syntaxKeyword;
  static Color syntaxType(AppTheme theme) => _get(theme).syntaxType;
  static Color syntaxString(AppTheme theme) => _get(theme).syntaxString;
  static Color syntaxComment(AppTheme theme) => _get(theme).syntaxComment;
  static Color syntaxNumber(AppTheme theme) => _get(theme).syntaxNumber;
  static Color syntaxVariable(AppTheme theme) => _get(theme).syntaxVariable;
  static Color syntaxStructure(AppTheme theme) => _get(theme).syntaxStructure;
  static Color syntaxIO(AppTheme theme) => _get(theme).syntaxIO;

  static const vscodeBlue = Color(0xFF007ACC);
  static const borderColor = Color(0xFF3C3C3C);
}
