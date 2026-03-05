import 'mots_cles.dart';

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
  bool isUsed;
  IdentifierInfo({required this.line, this.type, this.isUsed = false});
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
        if (scopeStack[k].containsKey(lower)) {
          // On marque comme utilisé si on cherche à savoir s'il est déclaré (usage possible)
          // Mais attention, l'analyse d'usage réelle se fait plus bas.
          return true;
        }
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

    void markAsUsed(String name) {
      final lower = name.toLowerCase();
      for (int k = scopeStack.length - 1; k >= 0; k--) {
        if (scopeStack[k].containsKey(lower)) {
          scopeStack[k][lower]!.isUsed = true;
          return;
        }
      }
    }

    void markTypeAsUsed(String? type) {
      if (type == null) return;
      final t = type.trim().toLowerCase();
      // Gérer "tableau[...] de Type"
      if (t.contains(' de ')) {
        final parts = t.split(' de ');
        if (parts.length > 1) {
          markTypeAsUsed(parts.last.trim());
        }
        return;
      }
      // Gérer "tableau de Type"
      if (t.startsWith('tableau ')) {
        final sub = t.substring(8).trim();
        markTypeAsUsed(sub);
        return;
      }
      markAsUsed(t);
    }

    void checkUnusedVariables(Map<String, IdentifierInfo> scope) {
      scope.forEach((name, info) {
        // On ignore les noms de fonctions/procédures dans le scope global pour éviter le bruit
        // et les types s'ils sont enregistrés là.
        if (!info.isUsed && !MotsCles.estUnMotCle(name)) {
          issues.add(
            LintIssue(
              line: info.line,
              message: "La variable '$name' est déclarée mais jamais utilisée.",
              type: LintType.warning,
              ruleId: 'unused_variable',
            ),
          );
        }
      });
    }

    bool unreachable = false;
    int controlBlockDepth =
        0; // Pour éviter les faux positifs de code mort dans des branches

    bool isDeclaredInCurrentScope(String name) {
      return scopeStack.last.containsKey(name.toLowerCase());
    }

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
                markTypeAsUsed(type);
              }
            }
          }
        }
        dansVariables = false;
        continue;
      }

      if (lineLower == 'finfonction' || lineLower == 'finprocedure') {
        if (scopeStack.length > 1) {
          checkUnusedVariables(scopeStack.last);
          scopeStack.removeLast();
        }
        dansVariables = false;
        unreachable = false;
        controlBlockDepth = 0;
        continue;
      }

      if (unreachable) {
        issues.add(
          LintIssue(
            line: i + 1,
            message: "Code inaccessible détecté après 'retourner'.",
            type: LintType.warning,
            ruleId: 'unreachable_code',
          ),
        );
      }

      if (lineLower.startsWith('retourner')) {
        // On signale le code mort uniquement si on est au niveau supérieur du bloc
        if (controlBlockDepth == 0) unreachable = true;
      }

      // Mise à jour de la profondeur des blocs de contrôle
      if (RegExp(r'^si\s+.*\salors$', caseSensitive: false).hasMatch(line) &&
          !lineLower.startsWith('sinon')) {
        controlBlockDepth++;
      }
      if (lineLower.startsWith('finsi') || lineLower.startsWith('fin si')) {
        controlBlockDepth = (controlBlockDepth - 1).clamp(0, 9999);
      }
      if (lineLower.startsWith('tantque ') && lineLower.endsWith('faire')) {
        controlBlockDepth++;
      }
      if (lineLower.startsWith('fintantque')) {
        controlBlockDepth = (controlBlockDepth - 1).clamp(0, 9999);
      }
      if (RegExp(r'^pour\s+', caseSensitive: false).hasMatch(line)) {
        controlBlockDepth++;
      }
      if (lineLower.startsWith('finpour') || lineLower.startsWith('fpour')) {
        controlBlockDepth = (controlBlockDepth - 1).clamp(0, 9999);
      }
      if (lineLower == 'repeter') controlBlockDepth++;
      if (lineLower.startsWith('jusqua')) {
        controlBlockDepth = (controlBlockDepth - 1).clamp(0, 9999);
      }
      if (RegExp(r'^selon\s+', caseSensitive: false).hasMatch(line)) {
        controlBlockDepth++;
      }
      if (lineLower.startsWith('finselon')) {
        controlBlockDepth = (controlBlockDepth - 1).clamp(0, 9999);
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
            } else {
              // type T = info -> marquer info comme utilisé
              markTypeAsUsed(typeDef);
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
          final type = parts.length > 1 ? parts[1].trim() : null;
          markTypeAsUsed(type);
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
              markTypeAsUsed(type);

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

        // On ne supprime plus le contenu des crochets : les variables d'index
        // (ex: j dans v[j]) doivent également être vérifiées et marquées utilisées.
        // La logique 'estAccesChampIndependant' gère déjà les accès .champ.

        // On récupère tous les mots, y compris ceux avec des points (accès champs)
        final matches = RegExp(
          r'[a-zA-Z_à-ÿÀ-ß][a-zA-Z0-9_à-ÿÀ-ß]*(\.[a-zA-Z_à-ÿÀ-ß][a-zA-Z0-9_à-ÿÀ-ß]*)*',
        ).allMatches(cleanedLine);

        for (final match in matches) {
          final fullName = match.group(0);
          if (fullName == null) continue;

          // Si l'identifiant est précédé d'un point (ex: tab[i].champ) ou d'un crochet fermant (ex: tab[i]),
          // c'est un accès champ et non une base variable à vérifier ici.
          bool estAccesChampIndependant = false;
          int lookBack = match.start - 1;
          while (lookBack >= 0 && cleanedLine[lookBack].trim().isEmpty) {
            lookBack--;
          }
          if (lookBack >= 0 &&
              (cleanedLine[lookBack] == '.' || cleanedLine[lookBack] == ']')) {
            estAccesChampIndependant = true;
          }

          final parts = fullName.split('.');
          final baseName = parts[0].toLowerCase();

          // Vérifier la base (variable ou mot-clé)
          if (!estAccesChampIndependant &&
              !isDeclared(baseName) &&
              !MotsCles.estUnMotCle(baseName)) {
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

          if (isDeclared(baseName)) {
            markAsUsed(baseName);
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

        // --- 5. Vérification Stricte des Types (Addition mixte) ---
        if (line.contains('+')) {
          final plusParts = line.split('+');
          if (plusParts.length >= 2) {
            String? typePrec;
            for (var part in plusParts) {
              final trimmedPart = part.trim();
              String? currentType;
              if (trimmedPart.startsWith('"'))
                currentType = "chaine";
              else if (RegExp(r'^\d').hasMatch(trimmedPart))
                currentType = "nombre";
              else {
                final match = RegExp(r'[a-zA-Z_]\w*').firstMatch(trimmedPart);
                if (match != null) {
                  final info = getInfo(match.group(0)!);
                  currentType =
                      (info?.type == 'entier' ||
                          info?.type == 'reel' ||
                          info?.type == 'réel')
                      ? "nombre"
                      : info?.type;
                }
              }

              if (typePrec != null &&
                  currentType != null &&
                  typePrec != currentType) {
                if ((typePrec == "chaine" && currentType == "nombre") ||
                    (typePrec == "nombre" && currentType == "chaine")) {
                  issues.add(
                    LintIssue(
                      line: i + 1,
                      message:
                          "Opération mixte risquée : addition d'un nombre et d'une chaîne.",
                      type: LintType.warning,
                      ruleId: 'mixed_type_addition',
                    ),
                  );
                  break;
                }
              }
              if (currentType != null) typePrec = currentType;
            }
          }
        }
      }
    }

    // Vérification finale du scope global
    checkUnusedVariables(scopeStack.first);

    return issues;
  }
}
