import '../interpreteur/mots_cles.dart';

class PseudoCodeFormateur {
  static String formater(String code) {
    if (code.isEmpty) return code;

    final List<String> lines = code.split('\n');
    final List<String> formattedLines = [];
    int indentLevel = 0;

    final blockStart = RegExp(
      r'^\s*(Si|Pour|TantQue|Fonction|Procédure|Structure|Algorithme|Variables|Selon|Repeter)\b',
      caseSensitive: false,
    );
    final blockEnd = RegExp(
      r'^\s*(FinSi|FinPour|FinTantQue|FinFonction|FinProcédure|FinStructure|Fin|FinSelon|JusquA|Début|Debut)\b',
      caseSensitive: false,
    );

    // Keywords that should be followed by indentation, but aren't blocks themselves in some contexts
    final indentNext = RegExp(
      r'\b(Alors|Faire|Début|Debut|Structure|Variables)\b$',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) {
        formattedLines.add("");
        continue;
      }

      // Pre-process: Logic for un-indenting the current line
      final lineLower = line.toLowerCase();

      bool isClosing = false;
      if (blockEnd.hasMatch(line)) {
        // Special case: 'Début' or 'Variables' might decrease the relative indent of what was before
        // but here we mostly care about 'Fin...'
        if (!lineLower.startsWith('début') &&
            !lineLower.startsWith('debut') &&
            !lineLower.startsWith('variables')) {
          indentLevel = (indentLevel - 1).clamp(0, 99);
          isClosing = true;
        } else if (lineLower.startsWith('début') ||
            lineLower.startsWith('debut')) {
          // 'Début' often ends 'Variables' block indentation
          // In some conventions 'Début' is at 0, in others same as 'Algorithme'
          // Let's assume 'Début' aligns with the block start.
          indentLevel = (indentLevel - 1).clamp(0, 99);
        }
      } else if (lineLower.startsWith('sinon') ||
          lineLower.startsWith('cas ')) {
        // sinon and cas are halfway through a block
        indentLevel = (indentLevel - 1).clamp(0, 99);
      }

      // Separate comment if exists
      final commentIndex = line.indexOf('//');
      String codePart = line;
      String commentPart = '';

      if (commentIndex != -1) {
        codePart = line.substring(0, commentIndex).trim();
        commentPart = line.substring(commentIndex);
      }

      // Apply keywords normalization and operator spacing
      codePart = _normalizeLine(codePart);
      line =
          codePart +
          (commentPart.isNotEmpty
              ? (codePart.isNotEmpty ? ' ' : '') + commentPart
              : '');

      // Add indentation
      formattedLines.add("  " * indentLevel + line);

      // Post-process: Logic for indenting the NEXT line
      if (blockStart.hasMatch(line) && !isClosing) {
        indentLevel++;
      } else if (indentNext.hasMatch(line)) {
        // If line ends with Alors/Faire/Début, indent next
        // But only if we didn't just indent via blockStart (prevent double indent)
        if (!blockStart.hasMatch(line)) {
          indentLevel++;
        }
      } else if (lineLower.startsWith('sinon') ||
          lineLower.startsWith('cas ')) {
        // Restore indent after sinon/cas for the content inside
        indentLevel++;
      }
    }

    return formattedLines.join('\n');
  }

  static String _normalizeLine(String line) {
    // 1. Keyword Normalization (PascalCase for blocks, lowercase for others)
    String result = line;

    // Normalize keywords
    final words = result.split(RegExp(r'(\s+|[(),])'));
    for (var word in words) {
      if (word.isEmpty) continue;
      if (MotsCles.estUnMotCle(word)) {
        // We want a standard casing. Let's go with the one defined in MotsCles or TitleCase
        final normalized = _standardizeCasing(word);
        if (normalized != word) {
          // Use regex with word boundaries to replace exactly this word
          result = result.replaceFirst(RegExp('\\b$word\\b'), normalized);
        }
      }
    }

    // 2. Operator Padding
    // Add spaces around operators if missing
    // Process multi-character operators first to avoid breaking them
    final operators = [
      '<-',
      '<>',
      '<=',
      '>=',
      r'\+',
      '-',
      r'\*',
      '/',
      '=(?!=)',
      '<(?![=-])',
      '>(?!=)',
    ];
    for (var op in operators) {
      // Look for operator NOT surrounded by spaces, but avoiding being inside strings
      // Simplified: regex for op without space before or after
      // We skip minus if it's potentially a negative number (e.g. "<- -5")
      if (op == '-') continue;

      result = result.replaceAllMapped(
        RegExp('(?<!\\s)$op(?!\\s)'),
        (m) => ' ${m.group(0)} ',
      );
      // Fix cases where only one side is missing space
      result = result.replaceAllMapped(
        RegExp('(?<!\\s)$op(\\s)'),
        (m) => ' ${m.group(0)}',
      );
      result = result.replaceAllMapped(
        RegExp('(\\s)$op(?!\\s)'),
        (m) => '${m.group(0)} ',
      );
    }

    // Specially handle minus to avoid breaking negative numbers but ensuring space around binary minus
    result = result.replaceAllMapped(
      RegExp(r'(\w)\s*-\s*(\w|\d)'),
      (m) => '${m.group(1)} - ${m.group(2)}',
    );

    return result;
  }

  static String _standardizeCasing(String word) {
    final lower = word.toLowerCase();
    // Prefer the first matching keyword from our lists for casing
    for (var kw in MotsCles.tous) {
      if (kw.toLowerCase() == lower) return kw;
    }
    return word;
  }
}
