class LintFix {
  final String title;
  final String replacement;

  LintFix({required this.title, required this.replacement});
}

class LintIssue {
  final int line;
  final String message;
  final LintType type;
  final String? ruleId;
  final List<LintFix>? fixes;
  final String? documentation; // Documentation for the rule

  LintIssue({
    required this.line,
    required this.message,
    required this.type,
    this.ruleId,
    this.fixes,
    this.documentation,
  });
}

enum LintType { warning, error }

class Linter {
  static List<LintIssue> analyser(String code) {
    if (code.isEmpty) return [];
    final List<LintIssue> issues = [];
    final lines = code.split('\n');

    // 0. Global structural checks
    if (!lines.any((l) => l.trim().toLowerCase().startsWith('algorithme'))) {
      issues.add(
        LintIssue(
          line: 1,
          message: "Le mot-clé 'Algorithme' est manquant.",
          type: LintType.error,
          ruleId: 'missing_algorithme',
          documentation:
              "Un algorithme commence toujours par le mot-clé 'Algorithme' suivi de son nom. Exemple: Algorithme MonProgramme",
          fixes: [
            LintFix(
              title: "Ajouter 'Algorithme MonProgramme'",
              replacement: "Algorithme MonProgramme\n${lines[0]}",
            ),
          ],
        ),
      );
    }
    if (!lines.any((l) => l.trim().toLowerCase() == 'fin')) {
      issues.add(
        LintIssue(
          line: lines.length,
          message: "Le mot-clé 'Fin' est manquant.",
          type: LintType.error,
          ruleId: 'missing_fin',
          documentation:
              "Un algorithme doit se terminer par le mot-clé 'Fin' pour marquer la clôture du bloc d'instructions.",
          fixes: [
            LintFix(
              title: "Ajouter 'Fin' à la fin",
              replacement: "${lines.last}\nFin",
            ),
          ],
        ),
      );
    }

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
        // remove strings first
        String cleanedLine = lines[i].replaceAll(RegExp(r'".*?"'), ' ');
        // We avoid flagging fields (object.field) by ignoring words preceded by a dot
        // Simple heuristic: we replace ".something" with whitespace
        cleanedLine = cleanedLine.replaceAll(RegExp(r'\.\w+'), ' ');

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
      'afficher',
      'afficher_table',
      'afficher2d',
      'affichertabstructure',
      'effacer',
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
      'fpour',
      'repeter',
      'jusqua',
      'selon',
      'cas',
      'finselon',
      'fonction',
      'finfonction',
      'procedure',
      'finprocedure',
      'retourner',
      'vrai',
      'faux',
      'entier',
      'réel',
      'reel',
      'chaîne',
      'chaine',
      'booléen',
      'booleen',
      'tableau',
      'type',
      'structure',
      'finstructure',
      'algorithme',
      'variables',
      'début',
      'debut',
      'fin',
      'const',
      'racine_carree',
      'abs',
      'div',
      'mod',
      'et',
      'ou',
      'non',
    };

    bool inDebut = false;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim().toLowerCase();
      if (line == 'variables') {
        dansVariables = true;
        continue;
      }
      if (line == 'début' || line == 'debut') {
        inDebut = true;
        dansVariables = false;
        continue;
      }
      if (line == 'fin') {
        inDebut = false;
        continue;
      }

      if (inDebut) {
        // Ignore words inside strings
        String cleanedLine = lines[i].replaceAll(RegExp(r'".*?"'), ' ');
        // Ignore words following a dot to avoid flagging fields as undeclared variables
        cleanedLine = cleanedLine.replaceAll(RegExp(r'\.\w+'), ' ');

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
                  ruleId: 'undeclared_variable',
                  documentation:
                      "Toutes les variables doivent être déclarées dans la section 'Variables' avant d'être utilisées dans le corps du programme ('Début'...'Fin').",
                  fixes: [
                    LintFix(
                      title: "Déclarer '$word : entier'",
                      replacement:
                          "// Ajouter dans Variables -> $word : entier",
                    ),
                  ],
                ),
              );
            }
          }
        }
      }

      // 5. Syntax validation for declarations
      if (dansVariables && line.contains(':')) {
        final parts = lines[i].split(':');
        final namesStr = parts[0];
        final names = namesStr.split(',').map((e) => e.trim());

        for (final name in names) {
          if (name.isNotEmpty) {
            // A. Check for invalid characters (like @, $, etc.)
            if (RegExp(r'[^a-zA-Z0-9_]').hasMatch(name)) {
              final suggestion = name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
              issues.add(
                LintIssue(
                  line: i + 1,
                  message:
                      "Le nom de variable '$name' contient des caractères invalides.",
                  type: LintType.error,
                  ruleId: 'invalid_identifier_chars',
                  documentation:
                      "Les noms de variables ne peuvent contenir que des lettres, des chiffres et le caractère souligné (_). Les caractères spéciaux comme @, #, \$, % sont interdits.",
                  fixes: suggestion.isNotEmpty
                      ? [
                          LintFix(
                            title: "Nettoyer en '$suggestion'",
                            replacement: lines[i].replaceFirst(
                              name,
                              suggestion,
                            ),
                          ),
                        ]
                      : null,
                ),
              );
              continue; // Skip other checks if chars are invalid
            }

            // B. Check if name starts with a digit
            if (RegExp(r'^\d').hasMatch(name)) {
              final suggestion = name.replaceFirst(RegExp(r'^\d+'), '');
              issues.add(
                LintIssue(
                  line: i + 1,
                  message:
                      "Le nom de variable '$name' est invalide. Un identifiant ne peut pas commencer par un chiffre.",
                  type: LintType.error,
                  ruleId: 'invalid_identifier_start',
                  documentation:
                      "Les identifiants (noms de variables, fonctions, etc.) doivent commencer par une lettre ou un souligné (_). Ils ne peuvent pas commencer par un chiffre.",
                  fixes: suggestion.isNotEmpty
                      ? [
                          LintFix(
                            title: "Renommer en '$suggestion'",
                            replacement: lines[i].replaceFirst(
                              name,
                              suggestion,
                            ),
                          ),
                          LintFix(
                            title: "Ajouter un préfixe 'var_$name'",
                            replacement: lines[i].replaceFirst(
                              name,
                              'var_$name',
                            ),
                          ),
                        ]
                      : [
                          LintFix(
                            title: "Ajouter un préfixe 'v$name'",
                            replacement: lines[i].replaceFirst(name, 'v$name'),
                          ),
                        ],
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
