class LintIssue {
  final int line;
  final String message;
  final LintType type;

  LintIssue({required this.line, required this.message, required this.type});
}

enum LintType { warning, error }

class Linter {
  static List<LintIssue> analyser(String code) {
    if (code.isEmpty) return [];
    final List<LintIssue> issues = [];
    final lines = code.split('\n');

    // 1. Extract all declared variables
    final Map<String, int> declarations = {}; // name -> line index
    bool dansVariables = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim().toLowerCase();

      // 1.1 Detection of constants
      if (line.startsWith('const ')) {
        final matches = RegExp(r'const\s+([a-zA-Z_]\w*)').allMatches(line);
        for (final m in matches) {
          declarations[m.group(1)!] = i + 1;
        }
      }

      // 1.2 Detection of procedure/function parameters
      if (line.startsWith('procedure ') || line.startsWith('fonction ')) {
        final paramsMatch = RegExp(r'\((.*?)\)').firstMatch(line);
        if (paramsMatch != null) {
          final params = paramsMatch.group(1)!.split(',');
          for (final p in params) {
            final parts = p.trim().split(':');
            if (parts.isNotEmpty) {
              final name = parts[0].trim();
              if (name.isNotEmpty) declarations[name] = i + 1;
            }
          }
        }
        // Also register the procedure/function name itself
        final nameMatch = RegExp(
          r'(?:procedure|fonction)\s+([a-zA-Z_]\w*)',
        ).firstMatch(line);
        if (nameMatch != null) declarations[nameMatch.group(1)!] = i + 1;
      }

      if (line == 'variables') {
        dansVariables = true;
        continue;
      }
      if (line == 'début' || line == 'debut') {
        dansVariables = false;
        continue;
      }

      if (dansVariables && line.contains(':')) {
        final parts = line.split(':');
        final names = parts[0].split(',').map((e) => e.trim());
        for (final name in names) {
          if (name.isNotEmpty) {
            declarations[name.toLowerCase()] = i + 1;
          }
        }
      }
    }

    // 2. Search for usages
    final Set<String> usages = {};
    bool dansDebut = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim().toLowerCase();
      if (line == 'début' || line == 'debut') {
        dansDebut = true;
        continue;
      }
      if (line == 'fin') {
        dansDebut = false;
        continue;
      }

      if (dansDebut) {
        // We avoid flagging fields (object.field) by ignoring words preceded by a dot
        // Simple heuristic: we replace ".something" with whitespace
        final cleanedLine = lines[i].replaceAll(RegExp(r'\.\w+'), ' ');

        final words = RegExp(r'\b[a-zA-Z_]\w*\b').allMatches(cleanedLine);
        for (final match in words) {
          final word = match.group(0)!.toLowerCase();
          if (declarations.containsKey(word)) {
            usages.add(word);
          }
        }
      }
    }

    // 3. Find anomalies
    declarations.forEach((name, line) {
      if (!usages.contains(name)) {
        issues.add(
          LintIssue(
            line: line,
            message: "Variable '$name' déclarée mais jamais utilisée.",
            type: LintType.warning,
          ),
        );
      }
    });

    // 4. Find undeclared variables (used but not in declarations)
    // We filter out common keywords that might be caught by the regex
    final commonKeywords = {
      'lire',
      'écrire',
      'ecrire',
      'si',
      'alors',
      'sinon',
      'finsi',
      'tantque',
      'faire',
      'fintantque',
      'pour',
      'allant',
      'de',
      'à',
      'a',
      'finpour',
      'vrai',
      'faux',
      'entier',
      'réel',
      'reel',
      'chaîne',
      'chaine',
      'booléen',
      'booleen',
    };

    bool inDebut = false;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim().toLowerCase();
      if (line == 'début' || line == 'debut') {
        inDebut = true;
        continue;
      }
      if (line == 'fin') {
        inDebut = false;
        continue;
      }

      if (inDebut) {
        // Ignore words following a dot to avoid flagging fields as undeclared variables
        final cleanedLine = lines[i].replaceAll(RegExp(r'\.\w+'), ' ');

        final words = RegExp(r'\b[a-zA-Z_]\w*\b').allMatches(cleanedLine);
        for (final match in words) {
          final word = match.group(0)!.toLowerCase();
          if (!declarations.containsKey(word) &&
              !commonKeywords.contains(word)) {
            // Check if it's already an issue to avoid duplicates on same line
            if (!issues.any(
              (iss) => iss.line == i + 1 && iss.message.contains("'$word'"),
            )) {
              issues.add(
                LintIssue(
                  line: i + 1,
                  message: "Variable '$word' utilisée mais non déclarée.",
                  type: LintType.error,
                ),
              );
            }
          }
        }
      }
    }

    return issues;
  }
}
