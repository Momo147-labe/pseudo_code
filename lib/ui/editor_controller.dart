import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/debug_provider.dart';
import '../providers/file_provider.dart';
import '../theme.dart';
import '../interpreteur/mots_cles.dart';

class CodeEditorController extends TextEditingController {
  final List<String> motsClesStructure = MotsCles.structure;
  final List<String> motsClesControle = MotsCles.controle;
  final List<String> motsClesIO = MotsCles.io;
  final List<String> motsClesMaths = MotsCles.maths;
  final List<String> types = MotsCles.types;
  int? _errorLine;
  int? _highlightLine;
  Set<int> _addedLines = {};
  Set<int> _deletedLines = {};
  Set<int> get addedLines => _addedLines;
  Set<int> get deletedLines => _deletedLines;

  set addedLines(Set<int> lines) {
    _addedLines = lines;
    notifyListeners();
  }

  set deletedLines(Set<int> lines) {
    _deletedLines = lines;
    notifyListeners();
  }

  set errorLine(int? line) {
    if (_errorLine != line) {
      _errorLine = line;
      notifyListeners();
    }
  }

  set highlightLine(int? line) {
    if (_highlightLine != line) {
      _highlightLine = line;
      notifyListeners();
    }
  }

  List<String> _extraireNomsSousProgrammes() {
    final List<String> noms = [];
    final reg = RegExp(
      r'(?:fonction|procedure|structure)\s+([a-zA-Z_]\w*)',
      caseSensitive: false,
    );
    for (final m in reg.allMatches(text)) {
      final nom = m.group(1);
      if (nom != null && !noms.contains(nom)) noms.add(nom);
    }
    return noms;
  }

  List<String> _extraireVariables() {
    final List<String> noms = [];
    // Recherche grossière dans le bloc Variables
    final reg = RegExp(
      r'^(\s*)([a-zA-Z_]\w*\s*(?:,\s*[a-zA-Z_]\w*\s*)*):',
      multiLine: true,
    );
    for (final m in reg.allMatches(text)) {
      final line = m.group(0)!;
      if (line.toLowerCase().contains('algorithme') ||
          line.toLowerCase().contains('type'))
        continue;
      final vars = m.group(2)!.split(',').map((e) => e.trim());
      for (final v in vars) {
        if (v.isNotEmpty && !noms.contains(v)) noms.add(v);
      }
    }
    return noms;
  }

  List<String> get motsCles {
    final List<String> liste = List.from(MotsCles.tous);
    liste.addAll(_extraireNomsSousProgrammes());
    liste.addAll(_extraireVariables());
    return liste.toSet().toList(); // Unicité
  }

  Set<int> _hiddenLines = {};

  set hiddenLines(Set<int> lines) {
    if (_hiddenLines.length != lines.length ||
        !_hiddenLines.containsAll(lines)) {
      _hiddenLines = lines;
      notifyListeners();
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final theme = context.read<ThemeProvider>().currentTheme;
    final debugProvider = context.read<DebugProvider>();
    final fileProvider = context.read<FileProvider>();

    final List<InlineSpan> spans = [];
    final String code = text;

    final errorLineIndex = debugProvider.errorLine;
    final highlightLineIndex = debugProvider.currentHighlightLine;

    // Construction dynamique du regex à partir de tous les mots-clés
    final allKeywordsPattern = MotsCles.tous.map(RegExp.escape).join('|');
    final regex = RegExp(
      '\\b($allKeywordsPattern)\\b|(\\d+\\.\\d+)|(\\d+)|("[^"]*")|(//.*)|([a-zA-Z_]\\w*)',
      caseSensitive: false,
    );

    int last = 0;

    // Bornes erreur
    int errorStart = -1, errorEnd = -1;
    if (errorLineIndex != null && errorLineIndex > 0) {
      final bounds = _getLineBounds(code, errorLineIndex);
      errorStart = bounds.$1;
      errorEnd = bounds.$2;
    }

    // Bornes surbrillance exécution
    int highlightStart = -1, highlightEnd = -1;
    if (highlightLineIndex != null && highlightLineIndex > 0) {
      final bounds = _getLineBounds(code, highlightLineIndex);
      highlightStart = bounds.$1;
      highlightEnd = bounds.$2;
    }

    // Cache line visibility to avoid repeated splits/searches
    final List<String> lines = code.split('\n');
    final List<int> lineStartOffsets = [];
    int currentOffset = 0;
    for (final line in lines) {
      lineStartOffsets.add(currentOffset);
      currentOffset += line.length + 1;
    }

    int getLineIndex(int offset) {
      int low = 0;
      int high = lineStartOffsets.length - 1;
      while (low <= high) {
        int mid = (low + high) ~/ 2;
        if (lineStartOffsets[mid] <= offset) {
          if (mid == lineStartOffsets.length - 1 ||
              lineStartOffsets[mid + 1] > offset) {
            return mid + 1;
          }
          low = mid + 1;
        } else {
          high = mid - 1;
        }
      }
      return 1;
    }

    TextStyle? getFoldedStyle(TextStyle? s, int lineIdx) {
      if (_hiddenLines.contains(lineIdx)) {
        return (s ?? const TextStyle()).copyWith(
          fontSize: 0,
          color: Colors.transparent,
          height:
              0.0001, // Near zero to avoid potential issues with exactly zero
        );
      }
      TextStyle style = (s ?? const TextStyle()).copyWith(height: 1.5);

      // Ajout des styles de Diff (Vert pour ajout, Rouge pour suppression)
      if (_addedLines.contains(lineIdx)) {
        style = style.copyWith(
          backgroundColor: Colors.green.withValues(alpha: 0.2),
        );
      } else if (_deletedLines.contains(lineIdx)) {
        style = style.copyWith(
          backgroundColor: Colors.red.withValues(alpha: 0.2),
        );
      }

      return style;
    }

    for (final match in regex.allMatches(code)) {
      if (match.start > last) {
        final textPart = code.substring(last, match.start);
        int currentPartOffset = last;

        // Split by lines to apply per-line hidden styles
        final partLines = textPart.split('\n');
        for (int i = 0; i < partLines.length; i++) {
          final lineSegment = partLines[i];
          final lineIdx = getLineIndex(currentPartOffset);
          final s = getFoldedStyle(style, lineIdx);

          // Apply error and highlight styles if needed
          TextStyle? segmentStyle = s;
          if (errorStart != -1 &&
              currentPartOffset >= errorStart &&
              currentPartOffset + lineSegment.length <= errorEnd) {
            segmentStyle = _applyErrorStyle(segmentStyle);
          }
          if (highlightStart != -1 &&
              currentPartOffset >= highlightStart &&
              currentPartOffset + lineSegment.length <= highlightEnd) {
            segmentStyle = _applyHighlightStyle(segmentStyle, theme);
          }

          spans.add(TextSpan(text: lineSegment, style: segmentStyle));

          if (i < partLines.length - 1) {
            // Newline character belongs to the line it follows
            final newlineIdx = getLineIndex(
              currentPartOffset + lineSegment.length,
            );
            spans.add(
              TextSpan(text: '\n', style: getFoldedStyle(style, newlineIdx)),
            );
            currentPartOffset += lineSegment.length + 1;
          }
        }
      }

      final token = match.group(0)!;
      final tokenLower = token.toLowerCase();

      Color color = style?.color ?? ThemeColors.textMain(theme);
      FontWeight fontWeight = FontWeight.normal;

      if (token.startsWith('//')) {
        color = ThemeColors.syntaxComment(theme);
      } else if (motsClesStructure.any((k) => k.toLowerCase() == tokenLower)) {
        color = ThemeColors.syntaxStructure(theme);
        fontWeight = FontWeight.bold;
      } else if (motsClesIO.any((k) => k.toLowerCase() == tokenLower)) {
        color = ThemeColors.syntaxIO(theme);
        fontWeight = FontWeight.bold;
      } else if (motsClesMaths.any((k) => k.toLowerCase() == tokenLower)) {
        color = ThemeColors.syntaxKeyword(theme);
        fontWeight = FontWeight.bold;
      } else if (motsClesControle.any((k) => k.toLowerCase() == tokenLower)) {
        color = ThemeColors.syntaxKeyword(theme);
        fontWeight = FontWeight.bold;
      } else if (types.any((k) => k.toLowerCase() == tokenLower)) {
        color = ThemeColors.syntaxType(theme);
        fontWeight = FontWeight.bold;
      } else if (RegExp(r'^\d+(\.\d+)?$').hasMatch(token)) {
        color = ThemeColors.syntaxNumber(theme);
      } else if (token.startsWith('"')) {
        color = ThemeColors.syntaxString(theme);
      } else if (MotsCles.constantes.any(
        (k) => k.toLowerCase() == tokenLower,
      )) {
        color = ThemeColors.syntaxNumber(theme);
        fontWeight = FontWeight.bold;
      } else if (RegExp(r'^[a-zA-Z_]\w*$').hasMatch(token)) {
        color = ThemeColors.syntaxVariable(theme);
      }

      final tokenLines = token.split('\n');
      int currentTokenOffset = match.start;

      for (int i = 0; i < tokenLines.length; i++) {
        final lineSegment = tokenLines[i];
        final lineIdx = getLineIndex(currentTokenOffset);

        TextStyle tokenStyle = (style ?? const TextStyle()).copyWith(
          color: color,
          fontWeight: fontWeight,
        );
        tokenStyle = getFoldedStyle(tokenStyle, lineIdx)!;

        // Erreur exécution
        if (errorStart != -1 &&
            currentTokenOffset >= errorStart &&
            currentTokenOffset + lineSegment.length <= errorEnd) {
          tokenStyle = _applyErrorStyle(tokenStyle);
        }

        // Highlight exécution
        if (highlightStart != -1 &&
            currentTokenOffset >= highlightStart &&
            currentTokenOffset + lineSegment.length <= highlightEnd) {
          tokenStyle = _applyHighlightStyle(tokenStyle, theme);
        }

        // Linter (Warnings)
        for (final issue in fileProvider.anomalies) {
          if (issue.line > 0) {
            final bounds = _getLineBounds(code, issue.line);
            if (currentTokenOffset >= bounds.$1 &&
                currentTokenOffset + lineSegment.length <= bounds.$2) {
              if (issue.message.contains("'")) {
                final parts = issue.message.split("'");
                if (parts.length > 1 &&
                    lineSegment.toLowerCase() == parts[1].toLowerCase()) {
                  tokenStyle = _applyLintStyle(tokenStyle);
                }
              }
            }
          }
        }

        spans.add(TextSpan(text: lineSegment, style: tokenStyle));

        if (i < tokenLines.length - 1) {
          final newlineIdx = getLineIndex(
            currentTokenOffset + lineSegment.length,
          );
          spans.add(
            TextSpan(text: '\n', style: getFoldedStyle(style, newlineIdx)),
          );
          currentTokenOffset += lineSegment.length + 1;
        }
      }
      last = match.end;
    }

    if (last < code.length) {
      final textPart = code.substring(last);
      final lineIdx = getLineIndex(last);
      spans.add(
        TextSpan(text: textPart, style: getFoldedStyle(style, lineIdx)),
      );
    }

    return TextSpan(style: style, children: spans);
  }

  (int, int) _getLineBounds(String code, int lineIndex) {
    final lines = code.split('\n');
    if (lineIndex <= 0 || lineIndex > lines.length) return (-1, -1);
    int currentPos = 0;
    for (int i = 0; i < lineIndex - 1; i++) {
      currentPos += lines[i].length + 1;
    }
    return (currentPos, currentPos + lines[lineIndex - 1].length);
  }

  TextStyle _applyErrorStyle(TextStyle? s) {
    return (s ?? const TextStyle()).copyWith(
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.wavy,
      decorationColor: Colors.red,
    );
  }

  TextStyle _applyHighlightStyle(TextStyle? s, AppTheme theme) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    return (s ?? const TextStyle()).copyWith(
      backgroundColor: Colors.blue.withValues(alpha: isDark ? 0.3 : 0.2),
    );
  }

  TextStyle _applyLintStyle(TextStyle? s) {
    return (s ?? const TextStyle()).copyWith(
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.wavy,
      decorationColor: Colors.orangeAccent,
    );
  }
}
