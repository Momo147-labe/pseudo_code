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

    // 1. Extract all declared identifiers (Variables, Constantes, Types, Fonctions)
    final Map<String, int> declarations = {}; // name -> line index
    bool dansVariables = false;

    for (int i = 0; i < lines.length; i++) {
      String lineFull = lines[i];
      // Ignorer les commentaires pour l'analyse des identifiants
      String line = lineFull.split('//')[0].trim();
      String lineLower = line.toLowerCase();

      if (line.isEmpty) continue;

      // 1.1 Détection des constantes (Gestion du multi-constantes sur une ligne)
      if (lineLower.startsWith('const ')) {
        final content = line.substring(6);
        final parts = content.split(',');
        for (final p in parts) {
          final m = RegExp(r'([a-zA-Z_]\w*)').firstMatch(p);
          if (m != null) {
            declarations[m.group(1)!.toLowerCase()] = i + 1;
          }
        }
      }

      // 1.2 Détection des types et structures
      if (lineLower.startsWith('type ')) {
        final m = RegExp(
          r'type\s+([a-zA-Z_]\w*)',
          caseSensitive: false,
        ).firstMatch(line);
        if (m != null) {
          declarations[m.group(1)!.toLowerCase()] = i + 1;
        }
        // Un début de type/structure ferme le bloc Variables s'il était ouvert
        dansVariables = false;
      }

      // 1.3 Détection des sous-programmes
      if (lineLower.startsWith('procedure ') ||
          lineLower.startsWith('fonction ')) {
        // Un début de SP ferme le bloc Variables s'il était ouvert
        dansVariables = false;

        final paramsMatch = RegExp(r'\((.*?)\)').firstMatch(line);
        if (paramsMatch != null) {
          final params = paramsMatch.group(1)!.split(',');
          for (final p in params) {
            final parts = p.trim().split(':');
            if (parts.isNotEmpty) {
              final name = parts[0].trim();
              if (name.isNotEmpty) declarations[name.toLowerCase()] = i + 1;
            }
          }
        }
        // Enregistrer le nom de la procédure/fonction elle-même
        final nameMatch = RegExp(
          r'(?:procedure|fonction)\s+([a-zA-Z_]\w*)',
          caseSensitive: false,
        ).firstMatch(line);
        if (nameMatch != null) {
          declarations[nameMatch.group(1)!.toLowerCase()] = i + 1;
        }
      }

      if (lineLower == 'variables') {
        dansVariables = true;
        continue;
      }
      if (lineLower == 'début' || lineLower == 'debut') {
        dansVariables = false;
        continue;
      }

      if (dansVariables && line.contains(':')) {
        final parts = line.split(':');
        final names = parts[0].split(',').map((e) => e.trim());
        for (final name in names) {
          if (name.isNotEmpty) {
            final lowerName = name.toLowerCase();
            if (declarations.containsKey(lowerName)) {
              issues.add(
                LintIssue(
                  line: i + 1,
                  message: "La variable '$name' est déjà déclarée.",
                  type: LintType.error,
                  ruleId: 'duplicate_declaration',
                  documentation:
                      "Une variable ne peut être déclarée qu'une seule fois dans le même bloc de variables.",
                ),
              );
            } else {
              declarations[lowerName] = i + 1;
            }
          }
        }
      }
    }

    // 2. Recherche des utilisations
    final Set<String> usages = {};
    bool dansDebut = false;

    // Regex supportant les accents (Français courant)
    final wordRegex = RegExp(r'[a-zA-Z_à-ÿÀ-ß][a-zA-Z0-9_à-ÿÀ-ß]*');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].split('//')[0].trim();
      String lineLower = line.toLowerCase();

      if (lineLower == 'début' || lineLower == 'debut') {
        dansDebut = true;
        continue;
      }
      if (lineLower == 'fin') {
        dansDebut = false;
        continue;
      }

      // On traque aussi les usages dans les signatures et le corps des variables (types personnalisés)
      String cleanedLine = line.replaceAll(RegExp(r'".*?"'), ' ');
      cleanedLine = cleanedLine.replaceAll(RegExp(r'\.\w+'), ' ');

      final matches = wordRegex.allMatches(cleanedLine);
      for (final match in matches) {
        final word = match.group(0)!.toLowerCase();
        if (declarations.containsKey(word)) {
          usages.add(word);
        }
      }
    }

    // 3. Trouver les anomalies (Inutilisées)
    declarations.forEach((name, line) {
      if (!usages.contains(name)) {
        issues.add(
          LintIssue(
            line: line,
            message:
                "Variable ou identifiant '$name' déclaré mais jamais utilisé.",
            type: LintType.warning,
          ),
        );
      }
    });

    // 4. Trouver les variables non déclarées
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
      'pas',
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

    dansDebut = false;
    dansVariables = false;
    bool dansStructure = false;

    for (int i = 0; i < lines.length; i++) {
      String lineFull = lines[i];
      String line = lineFull.split('//')[0].trim();
      String lineLower = line.toLowerCase();

      if (lineLower == 'variables') {
        dansVariables = true;
        continue;
      }
      if (lineLower == 'début' || lineLower == 'debut') {
        dansDebut = true;
        dansVariables = false;
        continue;
      }
      if (lineLower == 'fin') {
        dansDebut = false;
        continue;
      }
      if (lineLower.contains('structure') && lineLower.startsWith('type')) {
        dansStructure = true;
      }
      if (lineLower == 'finstructure') {
        dansStructure = false;
        continue;
      }

      // Fermeture auto du bloc variables sur structure/SP
      if (lineLower.startsWith('type ') ||
          lineLower.startsWith('fonction ') ||
          lineLower.startsWith('procedure ')) {
        dansVariables = false;
      }

      // On ne flag pas les identifiants déclarés ou les mots-clés
      // On ignore aussi l'intérieur des structures (ce sont des déclarations de champs)
      if ((dansDebut || dansVariables || lineLower.contains(':')) &&
          !dansStructure) {
        String cleanedLine = line.replaceAll(RegExp(r'".*?"'), ' ');
        cleanedLine = cleanedLine.replaceAll(RegExp(r'\.\w+'), ' ');

        final matches = wordRegex.allMatches(cleanedLine);
        for (final match in matches) {
          final word = match.group(0)!.toLowerCase();
          if (!declarations.containsKey(word) &&
              !commonKeywords.contains(word)) {
            if (!issues.any(
              (iss) => iss.line == i + 1 && iss.message.contains("'$word'"),
            )) {
              issues.add(
                LintIssue(
                  line: i + 1,
                  message: "Identifiant '$word' utilisé mais non déclaré.",
                  type: LintType.error,
                  ruleId: 'undeclared_variable',
                ),
              );
            }
          }
        }
      }

      // 5. Validation syntaxique des noms dans les déclarations
      if (dansVariables && line.contains(':')) {
        final parts = line.split(':');
        final names = parts[0].split(',').map((e) => e.trim());
        for (final name in names) {
          if (name.isNotEmpty) {
            if (RegExp(r'[^a-zA-Z0-9_]').hasMatch(name)) {
              issues.add(
                LintIssue(
                  line: i + 1,
                  message:
                      "Le nom de variable '$name' contient des caractères invalides.",
                  type: LintType.error,
                  ruleId: 'invalid_identifier_chars',
                ),
              );
            } else if (RegExp(r'^\d').hasMatch(name)) {
              issues.add(
                LintIssue(
                  line: i + 1,
                  message:
                      "Le nom de variable '$name' ne peut pas commencer par un chiffre.",
                  type: LintType.error,
                  ruleId: 'invalid_identifier_start',
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
