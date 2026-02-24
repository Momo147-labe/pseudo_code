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

class IdentifierInfo {
  final int line;
  final String? type;
  IdentifierInfo({required this.line, this.type});
}

class StructureDefInfo {
  final List<String> fields;
  StructureDefInfo({required this.fields});
}

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
              "Un algorithme doit se terminer par le mot-clé 'Fin' pour marquer l'achèvement du bloc d'instructions.",
          fixes: [
            LintFix(
              title: "Ajouter 'Fin' à la fin",
              replacement: "${lines.isNotEmpty ? lines.last : ''}\nFin",
            ),
          ],
        ),
      );
    }

    // 1. Dictionnaires de suivi
    final List<Map<String, IdentifierInfo>> scopeStack = [{}];
    final Map<String, StructureDefInfo> structures = {};
    bool dansVariables = false;
    bool dansStructureDef = false;
    String? currentStructureName;

    // Helper functions for scoping
    void declareInScope(String name, int line, {String? type}) {
      scopeStack.last[name.toLowerCase()] = IdentifierInfo(
        line: line,
        type: type,
      );
    }

    bool isDeclared(String name) {
      final lower = name.toLowerCase();
      for (int k = scopeStack.length - 1; k >= 0; k--) {
        if (scopeStack[k].containsKey(lower)) return true;
      }
      return false;
    }

    IdentifierInfo? getInfo(String name) {
      final lower = name.toLowerCase();
      for (int k = scopeStack.length - 1; k >= 0; k--) {
        if (scopeStack[k].containsKey(lower)) return scopeStack[k][lower];
      }
      return null;
    }

    bool isDeclaredInCurrentScope(String name) {
      return scopeStack.last.containsKey(name.toLowerCase());
    }

    final commonKeywords = {
      'lire',
      'écrire',
      'ecrire',
      'afficher',
      'afficher_table',
      'ecrire_table',
      'afficher2d',
      'ecrire2d',
      'affichertabstructure',
      'ecriretabstructure',
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
      'racine',
      'long',
      'maj',
      'minus',
      'abs',
      'hasard',
      'arrondi',
      'tronque',
      'en_entier',
      'en_reel',
      'en_chaine',
      'typevar',
      'est_numerique',
      'div',
      'mod',
      'et',
      'ou',
      'non',
      'car',
    };

    for (int i = 0; i < lines.length; i++) {
      String lineFull = lines[i];
      String line = lineFull.split('//')[0].trim();
      String lineLower = line.toLowerCase();
      if (line.isEmpty) continue;

      // --- 1. Gestion des Blocs ---
      if (lineLower.startsWith('fonction ') ||
          lineLower.startsWith('procedure ')) {
        final nameMatch = RegExp(
          r'(?:procedure|fonction)\s+([a-zA-Z_]\w*)',
          caseSensitive: false,
        ).firstMatch(line);
        if (nameMatch != null) {
          declareInScope(nameMatch.group(1)!, i + 1);
        }

        scopeStack.add({}); // Nouveau scope local

        final paramsMatch = RegExp(r'\((.*?)\)').firstMatch(line);
        if (paramsMatch != null) {
          final params = paramsMatch.group(1)!.split(',');
          for (final p in params) {
            final parts = p.trim().split(':');
            if (parts.isNotEmpty) {
              final name = parts[0].trim();
              final type = parts.length > 1 ? parts[1].trim() : null;
              if (name.isNotEmpty) {
                declareInScope(name, i + 1, type: type);
              }
            }
          }
        }
        dansVariables = false;
        continue;
      }

      if (lineLower == 'finfonction' || lineLower == 'finprocedure') {
        if (scopeStack.length > 1) {
          scopeStack.removeLast();
        }
        dansVariables = false;
        continue;
      }

      if (lineLower == 'variables') {
        dansVariables = true;
        continue;
      }
      if (lineLower == 'début' || lineLower == 'debut') {
        dansVariables = false;
        continue;
      }

      // --- 2. Détection des Types et Structures ---
      if (lineLower.startsWith('type ')) {
        final m = RegExp(
          r'type\s+([a-zA-Z_]\w*)\s*=\s*(.*)',
          caseSensitive: false,
        ).firstMatch(line);
        if (m != null) {
          final typeName = m.group(1);
          final typeDef = m.group(2)?.trim().toLowerCase();
          if (typeName != null) {
            declareInScope(typeName, i + 1);
            if (typeDef == 'structure') {
              dansStructureDef = true;
              currentStructureName = typeName.toLowerCase();
              structures[currentStructureName] = StructureDefInfo(fields: []);
            }
          }
        }
        dansVariables = false;
        continue;
      }
      if (lineLower == 'finstructure') {
        dansStructureDef = false;
        currentStructureName = null;
        continue;
      }

      // --- 3. Déclarations ---
      if (dansStructureDef && line.contains(':')) {
        final parts = line.split(':');
        final fields = parts[0].split(',').map((e) => e.trim());
        if (currentStructureName != null) {
          for (var f in fields) {
            if (f.isNotEmpty) {
              structures[currentStructureName]!.fields.add(f.toLowerCase());
            }
          }
        }
      } else if (dansVariables && line.contains(':')) {
        final parts = line.split(':');
        final names = parts[0].split(',').map((e) => e.trim());
        final type = parts.length > 1 ? parts[1].trim() : null;
        for (final name in names) {
          if (name.isNotEmpty) {
            if (isDeclaredInCurrentScope(name)) {
              issues.add(
                LintIssue(
                  line: i + 1,
                  message: "La variable '$name' est déjà déclarée.",
                  type: LintType.error,
                  ruleId: 'duplicate_declaration',
                ),
              );
            } else {
              declareInScope(name, i + 1, type: type);

              // Validation du nom
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
      } else if (lineLower.startsWith('const ')) {
        final content = line.substring(6);
        final parts = content.split(',');
        for (final p in parts) {
          final m = RegExp(r'([a-zA-Z_]\w*)\s*(?:<-|=)\s*(.*)').firstMatch(p);
          if (m != null) {
            final name = m.group(1);
            if (name != null) {
              declareInScope(name, i + 1);
            }
          }
        }
      }

      // --- 4. Analyse des usages et accès aux champs ---
      if (!dansVariables &&
          !dansStructureDef &&
          !lineLower.startsWith('const ') &&
          !lineLower.startsWith('algorithme') &&
          lineLower != 'debut' &&
          lineLower != 'début' &&
          lineLower != 'fin') {
        // Nettoyer la ligne pour ne pas analyser l'intérieur des chaînes
        String cleanedLine = line.replaceAll(RegExp(r'".*?"'), ' ');

        // On récupère tous les mots, y compris ceux avec des points (accès champs)
        final matches = RegExp(
          r'[a-zA-Z_à-ÿÀ-ß][a-zA-Z0-9_à-ÿÀ-ß]*(\.[a-zA-Z_à-ÿÀ-ß][a-zA-Z0-9_à-ÿÀ-ß]*)*',
        ).allMatches(cleanedLine);

        for (final match in matches) {
          final fullName = match.group(0);
          if (fullName == null) continue;

          // Si l'identifiant est précédé d'un point (ex: tab[i].champ),
          // c'est un accès champ et non une base variable à vérifier ici.
          bool estAccesChampIndependant = false;
          int lookBack = match.start - 1;
          while (lookBack >= 0 && cleanedLine[lookBack].trim().isEmpty) {
            lookBack--;
          }
          if (lookBack >= 0 && cleanedLine[lookBack] == '.') {
            estAccesChampIndependant = true;
          }

          final parts = fullName.split('.');
          final baseName = parts[0].toLowerCase();

          // Vérifier la base (variable ou mot-clé)
          if (!estAccesChampIndependant &&
              !isDeclared(baseName) &&
              !commonKeywords.contains(baseName)) {
            if (!issues.any(
              (iss) => iss.line == i + 1 && iss.message.contains("'$baseName'"),
            )) {
              issues.add(
                LintIssue(
                  line: i + 1,
                  message: "Identifiant '$baseName' utilisé mais non déclaré.",
                  type: LintType.error,
                  ruleId: 'undeclared_variable',
                ),
              );
            }
            continue;
          }

          // Si c'est un accès champ (ex: obj.champ), vérifier si possible
          if (parts.length > 1) {
            final info = getInfo(baseName);
            final type = info?.type;
            if (info != null && type != null) {
              final structName = type.toLowerCase();
              if (structures.containsKey(structName)) {
                final struct = structures[structName]!;
                final fieldName = parts[1].toLowerCase();
                if (!struct.fields.contains(fieldName)) {
                  issues.add(
                    LintIssue(
                      line: i + 1,
                      message:
                          "Le champ '$fieldName' n'existe pas dans la structure '$structName'.",
                      type: LintType.warning,
                      ruleId: 'invalid_field_access',
                    ),
                  );
                }
              }
            }
          }
        }
      }
    }

    return issues;
  }
}
