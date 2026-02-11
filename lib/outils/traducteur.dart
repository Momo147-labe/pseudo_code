import 'dart:core';
import '../interpreteur/utils.dart';

class Traducteur {
  static String traduire(String code, String langage) {
    if (code.isEmpty) return "";
    final lignes = code.split('\n');

    switch (langage.toLowerCase()) {
      case 'python':
        return _traduireEnPython(lignes);
      case 'c':
        return _traduireEnC(lignes);
      case 'javascript':
      case 'js':
        return _traduireEnJS(lignes);
      default:
        return code;
    }
  }

  static String _traduireEnPython(List<String> lignes) {
    StringBuffer sb = StringBuffer();
    int indentation = 0;
    bool dansVariables = false;

    // Analyse préliminaire pour les imports et les types
    bool utiliseMath = false;
    final Map<String, String> symboles = {};

    for (var l in lignes) {
      if (l.toLowerCase().contains('racine_carree') ||
          l.toLowerCase().contains('abs(') ||
          l.toLowerCase().contains('puissance(')) {
        utiliseMath = true;
      }

      // Extraction des symboles pour le typage
      if (l.contains(':')) {
        try {
          final parts = l.split(':');
          if (parts.length >= 2) {
            final nomsStr = parts[0]
                .replaceAll(
                  RegExp(r'^\s*(?:var\s+)?', caseSensitive: false),
                  '',
                )
                .trim();
            final type = parts[1]
                .trim()
                .split(RegExp(r'\s|;'))
                .first
                .toLowerCase();
            final noms = nomsStr.split(',').map((e) => e.trim());
            for (var n in noms) {
              if (n.isNotEmpty) symboles[n.toLowerCase()] = type;
            }
          }
        } catch (_) {}
      }
    }

    if (utiliseMath) sb.writeln("import math");

    for (var l in lignes) {
      String ligne = l.trim();
      String ligneLower = ligne.toLowerCase();

      if (ligne.isEmpty) {
        sb.writeln("");
        continue;
      }

      if (ligne.startsWith('//')) {
        sb.writeln("  " * indentation + "# ${ligne.substring(2).trim()}");
        continue;
      }

      if (ligneLower.startsWith('algorithme')) {
        final nom = ligne.split(' ').skip(1).join(' ').trim();
        sb.writeln("# --- Algorithme: $nom ---");
        continue;
      }

      if (ligneLower == 'variables') {
        dansVariables = true;
        continue;
      }

      if (ligneLower == 'debut' || ligneLower == 'début') {
        dansVariables = false;
        continue;
      }

      if (ligneLower == 'fin') break;

      // Gestion des types et structures
      if (ligneLower.startsWith('type ')) {
        sb.writeln(
          "  " * indentation +
              "# Type: $ligne (Les structures peuvent être implémentées avec des classes)",
        );
        continue;
      }

      if (ligneLower == 'finstructure') {
        continue;
      }

      // Gestion des constantes
      if (ligneLower.startsWith('const ')) {
        final match = RegExp(
          r'const\s+(.*)',
          caseSensitive: false,
        ).firstMatch(ligne);
        if (match != null) {
          final decl = match.group(1)!.trim();
          final parts = decl.split(RegExp(r'<-|←|='));
          if (parts.length == 2) {
            final nom = parts[0].trim();
            final valeur = parts[1].trim();
            sb.writeln("  " * indentation + "$nom = $valeur");
          }
        }
        continue;
      }

      if (dansVariables) {
        if (ligne.contains(':')) {
          final parts = ligne.split(':');
          final noms = parts[0]
              .split(',')
              .map((e) => e.trim())
              .where((n) => n.isNotEmpty);
          final type = parts[1].trim();

          // Initialisation des tableaux
          if (type.toLowerCase().startsWith('tableau')) {
            // Tentative d'extraction de la taille
            int taille = 10; // Défaut
            final matchTaille = RegExp(r'\[.*\.{2}(.*)\]').firstMatch(type);
            if (matchTaille != null) {
              taille = int.tryParse(matchTaille.group(1)!.trim()) ?? 10;
            }

            for (var n in noms) {
              sb.writeln(
                "  " * indentation + "$n = [0] * $taille  # Tableau de $type",
              );
            }
          } else {
            for (var n in noms) {
              sb.writeln("  " * indentation + "# var $n: $type");
            }
          }
        }
        continue;
      }

      // Instructions
      String pythonLigne = _convertirInstructionPython(ligne, symboles);

      // Gestion de l'indentation pour les fins de blocs
      if (ligneLower.startsWith('finsi') ||
          ligneLower.startsWith('fintantque') ||
          ligneLower.startsWith('finpour') ||
          ligneLower.startsWith('fpour') ||
          ligneLower.startsWith('finselon') ||
          ligneLower == 'finfonction' ||
          ligneLower == 'finprocedure') {
        indentation = (indentation - 1).clamp(0, 50);
        continue;
      }

      if (ligneLower == 'sinon' || ligneLower.startsWith('sinon si')) {
        indentation = (indentation - 1).clamp(0, 50);
        sb.writeln("  " * indentation + pythonLigne);
        indentation++;
        continue;
      }

      sb.writeln("  " * indentation + pythonLigne);

      // Augmenter l'indentation après les structures qui ouvrent un bloc
      if (ligneLower.endsWith('alors') ||
          ligneLower.endsWith('faire') ||
          ligneLower.startsWith('fonction') ||
          ligneLower.startsWith('procedure') ||
          ligneLower.startsWith('sinon') ||
          ligneLower.startsWith('cas ') ||
          ligneLower == 'autre') {
        indentation++;
      }
    }

    return sb.toString();
  }

  static String _convertirInstructionPython(
    String ligne, [
    Map<String, String>? symboles,
  ]) {
    String res = ligne;
    String cleanLine = ligne.trim().toLowerCase();

    // Affectation
    res = res.replaceAll('<-', '=');
    res = res.replaceAll('←', '=');

    // Affichage
    if (cleanLine.startsWith('afficher(') || cleanLine.startsWith('ecrire(')) {
      final isEcrire = cleanLine.startsWith('ecrire(');
      final match = RegExp(
        isEcrire ? r'ecrire\s*\((.*)\)' : r'afficher\s*\((.*)\)',
        caseSensitive: false,
      ).firstMatch(res);

      if (match != null) {
        final argsBruts = match.group(1)!;
        final args = InterpreteurUtils.splitArguments(argsBruts);

        if (args.isEmpty) {
          res = "print()";
        } else {
          final List<String> argsPython = [];
          for (final arg in args) {
            // Si c'est pas une chaîne, on convertit en str pour la concaténation sûre ou on laisse print gérer les arguments multiples (virgules)
            // Python print(a, b) met un espace. Pseudo-code 'Afficher(a, b)' concatène souvent ou met des espaces selon l'implémentation.
            // On va utiliser print(a, b, sep='') pour coller ou sep=' ' selon préférence.
            // Allons vers le mode arguments multiples de print par défaut
            argsPython.add(arg.trim());
          }
          res = "print(${argsPython.join(', ')})";
        }
      }
      return res;
    }

    // Lecture avec typage dynamique
    if (cleanLine.startsWith('lire(')) {
      final match = RegExp(
        r'lire\s*\((.*)\)',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final argsBruts = match.group(1)!;
        final args = InterpreteurUtils.splitArguments(argsBruts);

        if (args.isEmpty) {
          res = "input()";
        } else {
          final List<String> assignments = [];
          for (final arg in args) {
            final varName = arg.trim();
            final type = symboles?[varName.toLowerCase()] ?? '';

            String readCmd = "input()";
            if (type == 'entier') {
              readCmd = "int(input())";
            } else if (type == 'reel' || type == 'réel') {
              readCmd = "float(input())";
            }
            assignments.add("$varName = $readCmd");
          }
          res = assignments.join('\n');
        }
      }
      return res;
    }

    // Si ... Alors
    if (cleanLine.startsWith('si ')) {
      res = res.replaceFirst(RegExp(r'si\s+', caseSensitive: false), 'if ');
      res = res.replaceFirst(
        RegExp(r'\s+alors\s*$', caseSensitive: false),
        ':',
      );
      return res;
    }

    if (cleanLine == 'sinon') {
      return "else:";
    }

    if (cleanLine.startsWith('sinon si')) {
      res = res.replaceFirst(
        RegExp(r'sinon\s+si\s+', caseSensitive: false),
        'elif ',
      );
      res = res.replaceFirst(
        RegExp(r'\s+alors\s*$', caseSensitive: false),
        ':',
      );
      return res;
    }

    // Boucle TantQue
    if (cleanLine.startsWith('tantque ')) {
      res = res.replaceFirst(
        RegExp(r'tantque\s+', caseSensitive: false),
        'while ',
      );
      res = res.replaceFirst(
        RegExp(r'\s+faire\s*$', caseSensitive: false),
        ':',
      );
      return res;
    }

    // Boucle Pour
    final pourReg = RegExp(
      r'^pour\s+([a-zA-Z_]\w*)\s*(?:<-|de)\s+(.*)\s+(?:a|à)\s+(.*)\s+faire$',
      caseSensitive: false,
    );
    final pourMatch = pourReg.firstMatch(res);
    if (pourMatch != null) {
      final varName = pourMatch.group(1)!;
      final start = pourMatch.group(2)!.trim();
      final end = pourMatch.group(3)!.trim();
      res = "for $varName in range($start, $end + 1):";
      return res;
    }

    // Boucle Répéter...Jusqu'à
    if (cleanLine.startsWith('repeter')) {
      return "while True:";
    }

    if (cleanLine.startsWith('jusqua ')) {
      final match = RegExp(
        r'jusqua\s+(.*)',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final condition = match.group(1)!.trim();
        res = "if $condition: break";
      }
      return res;
    }

    // Selon...Cas (Python 3.10+)
    if (cleanLine.startsWith('selon ')) {
      final match = RegExp(
        r'selon\s+(.*)\s+faire',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final variable = match.group(1)!.trim();
        res = "match $variable:";
      }
      return res;
    }

    if (cleanLine.startsWith('cas ')) {
      final match = RegExp(
        r'cas\s+(.*)\s*:',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final val = match.group(1)!.trim();
        res = "case $val:";
      }
      return res;
    }

    if (cleanLine == 'autre' || cleanLine == 'sinon') {
      return "case _:";
    }

    // Fonctions / Procédures
    if (cleanLine.startsWith('fonction ') ||
        cleanLine.startsWith('procedure ')) {
      final match = RegExp(
        r'(?:fonction|procedure)\s+([a-zA-Z_]\w*)\s*\((.*)\)',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final nom = match.group(1)!;
        final params = match.group(2)!.trim();
        String paramsPy = "";
        if (params.isNotEmpty) {
          paramsPy = params
              .split(',')
              .map((p) => p.split(':')[0].trim())
              .join(', ');
        }
        res = "def $nom($paramsPy):";
      }
      return res;
    }

    if (cleanLine.startsWith('retourner ')) {
      res = res.replaceFirst(
        RegExp(r'retourner\s+', caseSensitive: false),
        'return ',
      );
      return res;
    }

    // Opérateurs logiques
    res = res.replaceAll(RegExp(r'\bET\b', caseSensitive: false), 'and');
    res = res.replaceAll(RegExp(r'\bet\b'), 'and');
    res = res.replaceAll(RegExp(r'\bOU\b', caseSensitive: false), 'or');
    res = res.replaceAll(RegExp(r'\bou\b'), 'or');
    res = res.replaceAll(RegExp(r'\bNON\b', caseSensitive: false), 'not');
    res = res.replaceAll(RegExp(r'\bnon\b'), 'not');

    // Opérateurs mathématiques
    res = res.replaceAll(RegExp(r'\bMOD\b', caseSensitive: false), '%');
    res = res.replaceAll(RegExp(r'\bmod\b'), '%');
    res = res.replaceAll(RegExp(r'\bDIV\b', caseSensitive: false), '//');
    res = res.replaceAll(RegExp(r'\bdiv\b'), '//');

    // Fonctions Math
    res = res.replaceAll(
      RegExp(r'\bracine_carree\b', caseSensitive: false),
      'math.sqrt',
    );
    res = res.replaceAll(RegExp(r'\bpuissance\b', caseSensitive: false), 'pow');

    // Constantes booléennes
    res = res.replaceAll(RegExp(r'\bVrai\b', caseSensitive: false), 'True');
    // Attention: 'vrai' minuscule peut être une partie de mot, mais \b protège
    res = res.replaceAll(RegExp(r'\bvrai\b'), 'True');
    res = res.replaceAll(RegExp(r'\bFaux\b', caseSensitive: false), 'False');
    res = res.replaceAll(RegExp(r'\bfaux\b'), 'False');

    return res;
  }

  static String _traduireEnC(List<String> lignes) {
    StringBuffer sb = StringBuffer();

    // Analyses préliminaires pour les headers
    bool utiliseIO = false;
    bool utiliseString = false;
    bool utiliseBool = false;
    bool utiliseMath = false;

    // Table des symboles pour le type-aware formatting (nom -> type)
    final Map<String, String> symboles = {};

    for (var l in lignes) {
      final lower = l.toLowerCase();
      if (lower.contains('afficher') ||
          lower.contains('ecrire') ||
          lower.contains('lire'))
        utiliseIO = true;
      // String.h n'est nécessaire que pour les manips de chaines (strcpy, strlen...),
      // pas juste pour l'affichage de littéraux.
      // Heuristique : présence de variables 'chaine' ou fonctions string (longueur...)
      if (lower.contains('chaine') || lower.contains('longueur('))
        utiliseString = true;

      if (lower.contains('booleen') ||
          lower.contains('vrai') ||
          lower.contains('faux'))
        utiliseBool = true;
      if (lower.contains('racine_carree') ||
          lower.contains('abs(') ||
          lower.contains('puissance(') ||
          lower.contains('pow('))
        utiliseMath = true;

      // Collecte rapide des variables pour la table des symboles (pass 1 simple)
      if (l.contains(':')) {
        try {
          final parts = l.split(':');
          if (parts.length >= 2) {
            final nomsStr = parts[0]
                .replaceAll(
                  RegExp(r'^\s*(?:var\s+)?', caseSensitive: false),
                  '',
                )
                .trim();
            final type = parts[1]
                .trim()
                .split(RegExp(r'\s|;'))
                .first
                .toLowerCase();
            final noms = nomsStr.split(',').map((e) => e.trim().toLowerCase());
            for (var n in noms) {
              if (n.isNotEmpty) symboles[n] = type;
            }
          }
        } catch (_) {}
      }
    }

    // Includes conditionnels
    if (utiliseIO) sb.writeln("#include <stdio.h>");
    sb.writeln("#include <stdlib.h>");
    if (utiliseString) sb.writeln("#include <string.h>");
    if (utiliseBool) sb.writeln("#include <stdbool.h>");
    if (utiliseMath) sb.writeln("#include <math.h>");
    sb.writeln("");

    // Buffers pour les différentes parties du code
    StringBuffer structBuffer = StringBuffer();
    StringBuffer funcProtoBuffer = StringBuffer();
    StringBuffer funcImplBuffer = StringBuffer();
    StringBuffer mainBuffer = StringBuffer();

    String sectionActuelle = 'main';

    int indentation = 1;
    bool dansVariablesMain = false;
    List<String> varsMainDeclarations = [];

    // Nom de la structure/fonction en cours de traitement
    String nomEnCours = "";

    // Analyse ligne par ligne
    for (var l in lignes) {
      String ligne = l.trim();
      String ligneLower = ligne.toLowerCase();

      if (ligne.isEmpty) continue;

      // Commentaires
      if (ligne.startsWith('//')) {
        if (sectionActuelle == 'main') {
          mainBuffer.writeln(
            "  " * indentation + "// ${ligne.substring(2).trim()}",
          );
        } else if (sectionActuelle == 'structure') {
          structBuffer.writeln("  // ${ligne.substring(2).trim()}");
        } else {
          funcImplBuffer.writeln("  // ${ligne.substring(2).trim()}");
        }
        continue;
      }

      // Début Algorithme (ignoré en C sauf commentaire)
      if (ligneLower.startsWith('algorithme')) {
        mainBuffer.writeln(
          "// --- Algorithme: ${ligne.substring(10).trim()} ---",
        );
        continue;
      }

      // Fin Algorithme (ignoré car main a son propre return 0)
      if (ligneLower == 'fin' ||
          ligneLower == 'fin algorithme' ||
          ligneLower == 'fin.') {
        continue;
      }

      // --- DETECTION DES STRUCTURES ---
      if (ligneLower.startsWith('type ') && ligneLower.contains('structure')) {
        sectionActuelle = 'structure';
        final parts = ligne.split('=');
        nomEnCours = parts[0]
            .substring(4)
            .trim(); // "Type Etudiant" -> "Etudiant"
        structBuffer.writeln("typedef struct {");
        continue;
      }

      if (ligneLower == 'finstructure') {
        structBuffer.writeln("} $nomEnCours;");
        structBuffer.writeln("");
        sectionActuelle = 'main';
        continue;
      }

      // --- DETECTION DES FONCTIONS / PROCEDURES ---
      if (ligneLower.startsWith('fonction ') ||
          ligneLower.startsWith('procedure ')) {
        sectionActuelle = 'fonction';
        indentation = 1; // Reset indentation pour le corps de la fonction

        bool estFonction = ligneLower.startsWith('fonction');
        String signature = "";

        // Parsing signature avec Regex pour plus de robustesse
        final funcReg = RegExp(
          r'(?:fonction|procedure)\s+([a-zA-Z_]\w*)\s*\((.*)\)(?:\s*:\s*(\w+))?',
          caseSensitive: false,
        );
        final match = funcReg.firstMatch(ligne);

        if (match != null) {
          String nom = match.group(1)!;
          String paramsStr = match.group(2)!;
          String returnTypeStr = match.group(3) ?? "";

          // Type de retour C
          String cReturnType = "void";
          if (estFonction) {
            cReturnType = _mapTypeC(returnTypeStr);
          }

          // Paramètres C
          List<String> cParams = [];
          if (paramsStr.trim().isNotEmpty) {
            List<String> paramsList = paramsStr.split(',');
            for (var p in paramsList) {
              // format: nom : type
              var pParts = p.split(':');
              if (pParts.length == 2) {
                String pName = pParts[0].trim();
                String pType = pParts[1].trim();
                String cType = _mapTypeC(pType);
                if (cType.contains('char[')) {
                  cParams.add("char* $pName"); // Pass strings as pointers
                } else {
                  cParams.add("$cType $pName");
                }
              } else {
                cParams.add("int ${p.trim()}"); // Fallback
              }
            }
          }

          signature = "$cReturnType $nom(${cParams.join(', ')})";
          funcProtoBuffer.writeln("$signature;");
          funcImplBuffer.writeln("$signature {");
        }
        continue;
      }

      if (ligneLower == 'finfonction' || ligneLower == 'finprocedure') {
        funcImplBuffer.writeln("}");
        funcImplBuffer.writeln("");
        sectionActuelle = 'main';
        indentation = 1; // Reset pour le main
        continue;
      }

      // --- LOGIQUE INTERNE (Structure, Fonction, Main) ---

      // 1. Contenu STRUCTURE
      if (sectionActuelle == 'structure') {
        // ex: nom : chaine
        if (ligne.contains(':')) {
          final parts = ligne.split(':');
          String champs = parts[0].trim();
          String type = parts[1].trim();
          if (type == 'chaine') {
            structBuffer.writeln("  char $champs[256];");
          } else if (type.startsWith('tableau')) {
            String size = "100";
            final m = RegExp(r'\[.*\.{2}(.*)\]').firstMatch(type);
            if (m != null) size = m.group(1)!.trim();
            structBuffer.writeln("  int $champs[$size];");
          } else {
            structBuffer.writeln("  ${_mapTypeC(type)} $champs;");
          }
        }
        continue;
      }

      // 2. Contenu FONCTION / PROCEDURE
      if (sectionActuelle == 'fonction') {
        if (ligneLower == 'variables' ||
            ligneLower == 'debut' ||
            ligneLower == 'début')
          continue;

        // Handle local variables declarations "name : type"
        if (ligne.contains(':') &&
            !ligneLower.startsWith('cas') &&
            !ligneLower.contains('=')) {
          final parts = ligne.split(':');
          final noms = parts[0].split(',');
          final type = parts[1].trim();
          String cType = _mapTypeC(type);
          for (var n in noms) {
            if (cType.contains('char[')) {
              funcImplBuffer.writeln("  char ${n.trim()}[256];");
            } else if (type.startsWith('tableau')) {
              String size = "100";
              final m = RegExp(r'\[.*\.{2}(.*)\]').firstMatch(type);
              if (m != null) size = m.group(1)!.trim();
              funcImplBuffer.writeln("  int ${n.trim()}[$size];");
            } else {
              funcImplBuffer.writeln("  $cType ${n.trim()};");
            }
          }
          continue;
        }

        _traiterCorps(
          ligne,
          ligneLower,
          funcImplBuffer,
          indentation: indentation,
          context: 'func',
          symboles: symboles,
        );
        // Gestion indentation manuelle ici car _traiterCorps est générique mais l'indentation doit être lue/écrite
        if (_estDebutBloc(ligneLower)) indentation++;
        if (_estFinBloc(ligneLower))
          indentation = (indentation - 1).clamp(1, 50);
        continue;
      }

      // 3. Contenu MAIN (Algorithme principal)
      if (sectionActuelle == 'main') {
        if (ligneLower == 'variables') {
          dansVariablesMain = true;
          continue;
        }
        if (ligneLower == 'debut' || ligneLower == 'début') {
          dansVariablesMain = false;
          // Écrire les variables accumulées au début du main (virtuellement)
          // On le fera lors de l'assemblage final du mainBuffer
          continue;
        }

        if (dansVariablesMain) {
          if (ligne.contains(':')) {
            final parts = ligne.split(':');
            final typeStr = parts[1].trim();
            final noms = parts[0].split(',');
            final cType = _mapTypeC(typeStr);

            for (var n in noms) {
              if (cType.contains('[') && cType.startsWith('char')) {
                // cas char[256] -> char nom[256]
                String base = "char";
                String dim = "[256]";
                varsMainDeclarations.add("  $base ${n.trim()}$dim;");
              } else if (cType.contains('[') && cType.startsWith('int')) {
                // cas int[N] -> int nom[N]
                String base = "int";
                String dim = "[100]";
                // Essayer de parser la taille réelle
                if (typeStr.startsWith('tableau')) {
                  // Regex pour capturer le contenu entre crochets: [ ... ]
                  final bracketMatch = RegExp(r'\[(.*)\]').firstMatch(typeStr);
                  if (bracketMatch != null) {
                    final content = bracketMatch.group(1)!.trim();
                    // Vérifier si 2D (présence de virgule)
                    if (content.contains(',')) {
                      final dims = content.split(',');
                      if (dims.length >= 2) {
                        // Gestion des plages "1..N" ou juste "N"
                        String d1 = _parseDim(dims[0]);
                        String d2 = _parseDim(dims[1]);
                        dim = "[$d1][$d2]";
                      }
                    } else {
                      // 1D
                      dim = "[${_parseDim(content)}]";
                    }
                  }
                }
                varsMainDeclarations.add("  $base ${n.trim()}$dim;");
              } else {
                varsMainDeclarations.add("  $cType ${n.trim()};");
              }
            }
          }
          continue;
        }

        // Instructions du main
        // Ajustement indentation avant écriture si fin de bloc
        if (_estFinBloc(ligneLower))
          indentation = (indentation - 1).clamp(1, 50);

        // Si c'est Else/Sinon, on désindente temporairement
        if (ligneLower.startsWith('sinon')) {
          indentation = (indentation - 1).clamp(1, 50);
          mainBuffer.writeln(
            "  " * indentation + _convertirInstructionC(ligne),
          );
          indentation++;
          continue;
        }

        // Fin de bloc déjà géré ? non, _convertirInstructionC renvoie '}'
        // On doit gérer l'indentation AVANT d'écrire pour la fermeture
        // C'est un peu tricky avec la logique précédente.
        // Simplification : on utilise une méthode unifiée pour le corps.

        mainBuffer.writeln(
          "  " * indentation + _convertirInstructionC(ligne, symboles),
        );

        if (_estDebutBloc(ligneLower)) indentation++;
        continue;
      }
    }

    // ASSEMBLAGE
    sb.write(structBuffer.toString());
    sb.writeln("");
    sb.write(funcProtoBuffer.toString());
    sb.writeln("");

    sb.writeln("int main() {");
    // Variables du main
    for (var v in varsMainDeclarations) {
      sb.writeln(v);
    }
    sb.writeln("");
    // Code du main
    sb.write(mainBuffer.toString());

    sb.writeln("  return 0;");
    sb.writeln("}");

    // Fonctions implémentation
    sb.writeln("");
    sb.write(funcImplBuffer.toString());

    return sb.toString();
  }

  static String _mapTypeC(String typePseudo) {
    String lower = typePseudo.toLowerCase();
    if (lower == 'entier') return "int";
    if (lower == 'reel' || lower == 'réel') return "float";
    if (lower == 'chaine') return "char[256]"; // Simplification
    if (lower == 'booleen') return "bool";
    // Si c'est un type structure déclaré, on le garde tel quel
    // (Suppose que le nom du type pseudo est le même que le nom de la struct C)
    return typePseudo; // ex: "Etudiant" -> "Etudiant"
  }

  static String _parseDim(String rawDim) {
    // Si c'est une plage "A..B", on retourne B
    if (rawDim.contains('..')) {
      final parts = rawDim.split('..');
      if (parts.length >= 2) {
        return parts[1].trim();
      }
    }
    return rawDim.trim();
  }

  static bool _estDebutBloc(String l) {
    return l.endsWith('alors') ||
        l.endsWith('faire') ||
        l.startsWith('cas ') ||
        l == 'sinon' ||
        l == 'autre';
  }

  static bool _estFinBloc(String l) {
    return l.startsWith('fin') ||
        l == 'sinon' ||
        l.startsWith('sinon si') ||
        l == 'jusqua' ||
        l == 'fpour';
  }

  // Helper pour traiter les instructions sans dupliquer la logique d'indentation (à améliorer)
  static void _traiterCorps(
    String ligne,
    String lower,
    StringBuffer buffer, {
    required int indentation,
    required String context,
    Map<String, String>? symboles,
  }) {
    if (_estFinBloc(lower)) {
      // La gestion de l'indentation est faite par l'appelant pour modifier la variable 'indentation'
      // Ici on écrit juste la ligne fermante avec l'indentation réduite
      buffer.writeln(
        "  " * (indentation - 1).clamp(1, 50) +
            _convertirInstructionC(ligne, symboles),
      );
    } else if (lower.startsWith('sinon')) {
      buffer.writeln(
        "  " * (indentation - 1).clamp(1, 50) +
            _convertirInstructionC(ligne, symboles),
      );
    } else {
      buffer.writeln(
        "  " * indentation + _convertirInstructionC(ligne, symboles),
      );
    }
  }

  static String _convertirInstructionC(
    String ligne, [
    Map<String, String>? symboles,
  ]) {
    String res = ligne;
    String ligneLower = ligne.trim().toLowerCase();

    // Affectation
    res = res.replaceAll('<-', '=');
    res = res.replaceAll('←', '=');

    // Affichage - Gérer plusieurs arguments avec printf
    if (ligneLower.startsWith('afficher(') ||
        ligneLower.startsWith('ecrire(')) {
      final isEcrire = ligneLower.startsWith('ecrire(');
      final match = RegExp(
        isEcrire ? r'ecrire\s*\((.*)\)' : r'afficher\s*\((.*)\)',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final argsBruts = match.group(1)!;
        final args = InterpreteurUtils.splitArguments(argsBruts);

        if (args.isEmpty) {
          res = "printf(\"\\n\");";
        } else {
          // Construire le format printf et les arguments
          final List<String> formats = [];
          final List<String> valeurs = [];

          for (final arg in args) {
            final a = arg.trim();
            if (a.startsWith('"') && a.endsWith('"')) {
              // Chaîne littérale
              formats.add("%s");
              valeurs.add(a);
            } else {
              // Expression - déterminer le type de format via la table des symboles
              String fmt = "%d"; // Par défaut entier
              if (symboles != null) {
                // Essayer de trouver le type de la variable principale dans l'expression
                // Simplification : on prend le premier mot comme var potentielle
                final firstWord = a
                    .split(RegExp(r'\W'))
                    .firstWhere((e) => e.isNotEmpty, orElse: () => "");
                final type = symboles[firstWord.toLowerCase()];

                if (type != null) {
                  if (type == 'reel' || type == 'réel')
                    fmt = "%f";
                  else if (type == 'chaine')
                    fmt = "%s";
                  else if (type == 'caractere')
                    fmt = "%c";
                }
              }
              // Heuristique simple si pas dans les symboles
              if (a.contains('.') && !a.startsWith('"')) fmt = "%f";

              formats.add(fmt);
              valeurs.add(a);
            }
          }

          final formatStr = formats.join(
            " ",
          ); // Espace entre les éléments par défaut
          final valeursStr = valeurs.join(", ");
          res = "printf(\"$formatStr\\n\", $valeursStr);";
        }
      }
      return res;
    }

    // Lecture - scanf pour chaque variable
    if (ligneLower.startsWith('lire(')) {
      final match = RegExp(
        r'lire\s*\((.*)\)',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final argsBruts = match.group(1)!;
        final args = InterpreteurUtils.splitArguments(argsBruts);

        if (args.isEmpty) {
          res = "// lire() sans argument";
        } else {
          final List<String> scans = [];
          for (final arg in args) {
            final varName = arg.trim();
            String fmt = "%d"; // Par défaut entier
            if (symboles != null) {
              final type = symboles[varName.toLowerCase()];
              if (type == 'reel' || type == 'réel')
                fmt = "%f";
              else if (type == 'chaine')
                fmt = "%s";
              else if (type == 'caractere')
                fmt = "%c";
            }
            if (fmt == "%s") {
              scans.add(
                "scanf(\"%s\", $varName);",
              ); // Pas de & pour les tableaux de char
            } else {
              scans.add("scanf(\"$fmt\", &$varName);");
            }
          }
          res = scans.join("\n");
        }
      }
      return res;
    }

    // Si ... Alors
    if (res.toLowerCase().startsWith('si ')) {
      res = res.replaceFirst(RegExp(r'si\s+', caseSensitive: false), 'if (');
      res = res.replaceFirst(
        RegExp(r'\s+alors\s*$', caseSensitive: false),
        ') {',
      );
      return res;
    }

    if (res.toLowerCase() == 'sinon') {
      return "} else {";
    }

    if (res.toLowerCase().startsWith('sinon si')) {
      res = res.replaceFirst(
        RegExp(r'sinon\s+si\s+', caseSensitive: false),
        '} else if (',
      );
      res = res.replaceFirst(
        RegExp(r'\s+alors\s*$', caseSensitive: false),
        ') {',
      );
      return res;
    }

    // Boucle TantQue
    if (res.toLowerCase().startsWith('tantque ')) {
      res = res.replaceFirst(
        RegExp(r'tantque\s+', caseSensitive: false),
        'while (',
      );
      res = res.replaceFirst(
        RegExp(r'\s+faire\s*$', caseSensitive: false),
        ') {',
      );
      return res;
    }

    // Boucle Pour
    final pourReg = RegExp(
      r'^pour\s+([a-zA-Z_]\w*)\s*(?:<-|de)\s+(.*)\s+(?:a|à)\s+(.*)\s+faire$',
      caseSensitive: false,
    );
    final pourMatch = pourReg.firstMatch(res);
    if (pourMatch != null) {
      final varName = pourMatch.group(1)!;
      final start = pourMatch.group(2)!.trim();
      final end = pourMatch.group(3)!.trim();
      res = "for (int $varName = $start; $varName <= $end; $varName++) {";
      return res;
    }

    // Boucle Répéter...Jusqu'à
    if (res.toLowerCase().startsWith('repeter')) {
      return "do {";
    }

    if (res.toLowerCase().startsWith('jusqua ')) {
      final match = RegExp(
        r'jusqua\s+(.*)',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final condition = match.group(1)!.trim();
        res = "} while (!($condition));";
      }
      return res;
    }

    // Selon...Cas -> switch
    if (res.toLowerCase().startsWith('selon ')) {
      final match = RegExp(
        r'selon\s+(.*)\s+faire',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final variable = match.group(1)!.trim();
        res = "switch ($variable) {";
      }
      return res;
    }

    if (res.toLowerCase().startsWith('cas ')) {
      final match = RegExp(
        r'cas\s+(.*)\s*:',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final valeur = match.group(1)!.trim();
        res = "  case $valeur:";
      }
      return res;
    }

    if (res.toLowerCase() == 'sinon' || res.toLowerCase() == 'autre') {
      return "  default:";
    }

    // Fonctions / Procédures
    if (res.toLowerCase().startsWith('fonction ')) {
      final match = RegExp(
        r'fonction\s+([a-zA-Z_]\w*)\s*\((.*)\)\s*:\s*(\w+)',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final nom = match.group(1)!;
        final params = match.group(2)!.trim();
        final typeRetour = match.group(3)!.trim().toLowerCase();

        String cTypeRetour = "int";
        if (typeRetour == 'reel' || typeRetour == 'réel')
          cTypeRetour = "float";
        else if (typeRetour == 'chaine')
          cTypeRetour = "char*";
        else if (typeRetour == 'booleen')
          cTypeRetour = "bool";

        String paramsC = "";
        if (params.isNotEmpty) {
          final paramsList = params.split(',').map((p) {
            final parts = p.split(':');
            final nomParam = parts[0].trim();
            final typeParam = parts[1].trim().toLowerCase();
            String cTypeParam = "int";

            if (typeParam.startsWith('tableau')) {
              if (typeParam.contains('2d') || typeParam.contains(',')) {
                // Tableau 2D: int (*nom)[100]
                return "int (*$nomParam)[100]";
              }
              // Tableau 1D: int* nom
              return "int* $nomParam";
            }

            if (typeParam == 'reel' || typeParam == 'réel')
              cTypeParam = "float";
            else if (typeParam == 'chaine')
              cTypeParam = "char*";
            else if (typeParam == 'booleen')
              cTypeParam = "bool";

            return "$cTypeParam $nomParam";
          }).toList();
          paramsC = paramsList.join(", ");
        }
        res = "$cTypeRetour $nom($paramsC) {";
      }
      return res;
    }

    if (res.toLowerCase().startsWith('procedure ')) {
      final match = RegExp(
        r'procedure\s+([a-zA-Z_]\w*)\s*\((.*)\)',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final nom = match.group(1)!;
        final params = match.group(2)!.trim();
        String paramsC = "";
        if (params.isNotEmpty) {
          final paramsList = params.split(',').map((p) {
            final parts = p.split(':');
            final nomParam = parts[0].trim();
            final typeParam = parts[1].trim().toLowerCase();
            String cTypeParam = "int";

            if (typeParam.startsWith('tableau')) {
              if (typeParam.contains('2d') || typeParam.contains(',')) {
                return "int (*$nomParam)[100]";
              }
              return "int* $nomParam";
            }

            if (typeParam == 'reel' || typeParam == 'réel')
              cTypeParam = "float";
            else if (typeParam == 'chaine')
              cTypeParam = "char*";
            else if (typeParam == 'booleen')
              cTypeParam = "bool";

            return "$cTypeParam $nomParam";
          }).toList();
          paramsC = paramsList.join(", ");
        }
        res = "void $nom($paramsC) {";
      }
      return res;
    }

    if (res.toLowerCase().startsWith('retourner ')) {
      final match = RegExp(
        r'retourner\s+(.*)',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final valeur = match.group(1)!.trim();
        res = "return $valeur;";
      }
      return res;
    }

    // Gestion des accès tableaux 2D : T[i,j] -> T[i][j]
    res = res.replaceAllMapped(
      RegExp(r'\[\s*([^,\[\]]+)\s*,\s*([^,\[\]]+)\s*\]'),
      (match) {
        return '[${match.group(1)}][${match.group(2)}]';
      },
    );

    // Opérateurs logiques
    res = res.replaceAll(RegExp(r'\bET\b', caseSensitive: false), '&&');
    res = res.replaceAll(RegExp(r'\bet\b'), '&&');
    res = res.replaceAll(RegExp(r'\bOU\b', caseSensitive: false), '||');
    res = res.replaceAll(RegExp(r'\bou\b'), '||');
    res = res.replaceAll(RegExp(r'\bNON\b', caseSensitive: false), '!');
    res = res.replaceAll(RegExp(r'\bnon\b'), '!');

    // Opérateurs mathématiques
    res = res.replaceAll(RegExp(r'\bMOD\b', caseSensitive: false), '%');
    res = res.replaceAll(RegExp(r'\bmod\b'), '%');
    res = res.replaceAll(RegExp(r'\bDIV\b', caseSensitive: false), '/');
    res = res.replaceAll(RegExp(r'\bdiv\b'), '/');

    // Fonctions mathématiques
    res = res.replaceAll(
      RegExp(r"\bracine_carree\b", caseSensitive: false),
      "sqrt",
    );
    res = res.replaceAll(RegExp(r"\babs\b", caseSensitive: false), "abs");
    res = res.replaceAll(RegExp(r"\bpuissance\b", caseSensitive: false), "pow");

    // Constantes booléennes
    res = res.replaceAll(RegExp(r'\bVrai\b', caseSensitive: false), 'true');
    res = res.replaceAll(RegExp(r'\bvrai\b'), 'true');
    res = res.replaceAll(RegExp(r'\bFaux\b', caseSensitive: false), 'false');
    res = res.replaceAll(RegExp(r'\bfaux\b'), 'false');

    // Ajouter point-virgule si nécessaire
    if (!res.endsWith('{') &&
        !res.endsWith('}') &&
        !res.endsWith(';') &&
        !res.isEmpty &&
        !res.toLowerCase().startsWith('cas') &&
        !res.toLowerCase().startsWith('default')) {
      res += ';';
    }

    return res;
  }

  static String _traduireEnJS(List<String> lignes) {
    StringBuffer sb = StringBuffer();

    StringBuffer classBuffer = StringBuffer();
    StringBuffer funcBuffer = StringBuffer();
    StringBuffer mainBuffer = StringBuffer();

    // Symbol table for JS
    final Map<String, String> symboles = {};

    // Pass 1: Collect symbols
    for (var l in lignes) {
      if (l.contains(':')) {
        try {
          final parts = l.split(':');
          if (parts.length >= 2) {
            final nomsStr = parts[0]
                .replaceAll(
                  RegExp(r'^\s*(?:var\s+)?', caseSensitive: false),
                  '',
                )
                .trim();
            final type = parts[1]
                .trim()
                .split(RegExp(r'\s|;'))
                .first
                .toLowerCase();
            final noms = nomsStr.split(',').map((e) => e.trim());
            for (var n in noms) {
              if (n.isNotEmpty) symboles[n.toLowerCase()] = type;
            }
          }
        } catch (_) {}
      }
    }

    String sectionActuelle = 'main';
    String nomEnCours = "";
    int indentation = 0;
    bool dansVariablesMain = false;

    for (var l in lignes) {
      String ligne = l.trim();
      String ligneLower = ligne.toLowerCase();

      if (ligne.isEmpty) continue;

      // Commentaires
      if (ligne.startsWith('//')) {
        String comment = "  " * indentation + "// ${ligne.substring(2).trim()}";
        if (sectionActuelle == 'main')
          mainBuffer.writeln(comment);
        else if (sectionActuelle == 'structure')
          classBuffer.writeln(comment);
        else
          funcBuffer.writeln(comment);
        continue;
      }

      if (ligneLower.startsWith('algorithme')) {
        mainBuffer.writeln(
          "// --- Algorithme: ${ligne.substring(10).trim()} ---",
        );
        continue;
      }

      // --- DETECTION STRUCTURES -> CLASSES JS ---
      if (ligneLower.startsWith('type ') && ligneLower.contains('structure')) {
        sectionActuelle = 'structure';
        final parts = ligne.split('=');
        nomEnCours = parts[0].substring(4).trim();
        classBuffer.writeln("class $nomEnCours {");
        classBuffer.writeln("  constructor() {");
        continue;
      }

      if (ligneLower == 'finstructure') {
        classBuffer.writeln("  }");
        classBuffer.writeln("}");
        classBuffer.writeln("");
        sectionActuelle = 'main';
        continue;
      }

      // --- DETECTION FONCTIONS ---
      if (ligneLower.startsWith('fonction ') ||
          ligneLower.startsWith('procedure ')) {
        sectionActuelle = 'fonction';
        indentation = 1;

        final matchFunc = RegExp(
          r'(?:fonction|procedure)\s+([a-zA-Z_]\w*)\s*\((.*)\)',
          caseSensitive: false,
        ).firstMatch(ligne);
        if (matchFunc != null) {
          String nom = matchFunc.group(1)!;
          String paramsStr = matchFunc.group(2)!;
          String paramsJS = "";

          if (paramsStr.trim().isNotEmpty) {
            paramsJS = paramsStr
                .split(',')
                .map((p) => p.split(':')[0].trim())
                .join(', ');
          }
          funcBuffer.writeln("function $nom($paramsJS) {");
        } else {
          funcBuffer.writeln("function unknown() {");
        }
        continue;
      }

      if (ligneLower == 'finfonction' || ligneLower == 'finprocedure') {
        funcBuffer.writeln("}");
        funcBuffer.writeln("");
        sectionActuelle = 'main';
        indentation = 0;
        continue;
      }

      // --- CONTENU INTERNE ---

      // 1. Structures
      if (sectionActuelle == 'structure') {
        if (ligne.contains(':')) {
          final parts = ligne.split(':');
          String champs = parts[0].trim();
          String type = parts[1].trim().toLowerCase();
          String defaultValue = "null";

          if (type.startsWith('entier') ||
              type.startsWith('reel') ||
              type.startsWith('réel'))
            defaultValue = "0";
          if (type.startsWith('chaine')) defaultValue = "\"\"";
          if (type.startsWith('booleen')) defaultValue = "false";
          if (type.startsWith('tableau')) defaultValue = "[]";

          classBuffer.writeln("    this.$champs = $defaultValue;");
        }
        continue;
      }

      // 2. Fonctions
      if (sectionActuelle == 'fonction') {
        if (ligneLower == 'variables' ||
            ligneLower == 'debut' ||
            ligneLower == 'début')
          continue;
        if (ligne.contains(':') &&
            !ligneLower.startsWith('cas ') &&
            !ligneLower.contains('=')) {
          final parts = ligne.split(':');
          final noms = parts[0].split(',');
          final type = parts[1].trim().toLowerCase();
          for (var n in noms) {
            if (type.startsWith('tableau')) {
              String size = "0";
              final m = RegExp(r'\[.*\.{2}(.*)\]').firstMatch(type);
              if (m != null) size = m.group(1)!.trim();
              funcBuffer.writeln(
                "  let ${n.trim()} = new Array($size).fill(0);",
              );
            } else {
              funcBuffer.writeln("  let ${n.trim()};");
            }
          }
          continue;
        }
        _traiterCorpsJS(
          ligne,
          ligneLower,
          funcBuffer,
          indentation: indentation,
          symboles: symboles,
        );
        if (_estDebutBloc(ligneLower)) indentation++;
        if (_estFinBloc(ligneLower))
          indentation = (indentation - 1).clamp(0, 50);
        continue;
      }

      // 3. Main
      if (sectionActuelle == 'main') {
        if (ligneLower == 'variables') {
          dansVariablesMain = true;
          continue;
        }
        if (ligneLower == 'debut' || ligneLower == 'début') {
          dansVariablesMain = false;
          continue;
        }

        if (dansVariablesMain) {
          if (ligne.contains(':')) {
            final parts = ligne.split(':');
            final noms = parts[0].split(',').map((e) => e.trim());
            final type = parts[1].trim().toLowerCase();

            bool isStruct = ![
              'entier',
              'reel',
              'réel',
              'chaine',
              'booleen',
              'tableau',
            ].any((t) => type.startsWith(t));

            for (var n in noms) {
              if (isStruct) {
                mainBuffer.writeln("let $n = new $type();");
              } else if (type.startsWith('tableau')) {
                // Tableau
                String size = "10";
                final m = RegExp(r'\[.*\.{2}(.*)\]').firstMatch(type);
                if (m != null) size = m.group(1)!.trim();
                mainBuffer.writeln("let $n = new Array($size).fill(0);");
              } else {
                mainBuffer.writeln("let $n;");
              }
            }
          }
          continue;
        }

        // Instructions
        if (_estFinBloc(ligneLower))
          indentation = (indentation - 1).clamp(0, 50);

        if (ligneLower.startsWith('sinon')) {
          indentation = (indentation - 1).clamp(0, 50);
          mainBuffer.writeln(
            "  " * indentation + _convertirInstructionJS(ligne, symboles),
          );
          indentation++;
          continue;
        }

        mainBuffer.writeln(
          "  " * indentation + _convertirInstructionJS(ligne, symboles),
        );
        if (_estDebutBloc(ligneLower)) indentation++;
        continue;
      }
    }

    sb.write(classBuffer.toString());
    sb.writeln("");
    sb.write(funcBuffer.toString());
    sb.writeln("");
    sb.writeln("// --- Main ---");
    sb.write(mainBuffer.toString());

    return sb.toString();
  }

  static void _traiterCorpsJS(
    String ligne,
    String lower,
    StringBuffer buffer, {
    required int indentation,
    Map<String, String>? symboles,
  }) {
    if (_estFinBloc(lower)) {
      buffer.writeln(
        "  " * (indentation - 1).clamp(0, 50) +
            _convertirInstructionJS(ligne, symboles),
      );
    } else if (lower.startsWith('sinon')) {
      buffer.writeln(
        "  " * (indentation - 1).clamp(0, 50) +
            _convertirInstructionJS(ligne, symboles),
      );
    } else {
      buffer.writeln(
        "  " * indentation + _convertirInstructionJS(ligne, symboles),
      );
    }
  }

  static String _convertirInstructionJS(
    String ligne, [
    Map<String, String>? symboles,
  ]) {
    String res = ligne;
    String cleanLine = ligne.trim().toLowerCase();

    // Affectation
    res = res.replaceAll('<-', '=');
    res = res.replaceAll('←', '=');

    // Affichage
    if (cleanLine.startsWith('afficher(') || cleanLine.startsWith('ecrire(')) {
      final isEcrire = cleanLine.startsWith('ecrire(');
      final match = RegExp(
        isEcrire ? r'ecrire\s*\((.*)\)' : r'afficher\s*\((.*)\)',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final argsBruts = match.group(1)!;
        final args = InterpreteurUtils.splitArguments(argsBruts);

        if (args.isEmpty) {
          res = "console.log();";
        } else {
          final argsList = args.map((a) => a.trim()).toList();
          res = "console.log(${argsList.join(', ')});";
        }
      }
      return res;
    }

    // Lecture intelligent
    if (cleanLine.startsWith('lire(')) {
      final match = RegExp(
        r'lire\s*\((.*)\)',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final argsBruts = match.group(1)!;
        final args = InterpreteurUtils.splitArguments(argsBruts);

        if (args.isEmpty) {
          res = "// lire() sans argument";
        } else {
          final List<String> reads = [];
          for (final arg in args) {
            final varName = arg.trim();
            final type = symboles?[varName.toLowerCase()] ?? '';

            if (type == 'entier') {
              reads.add("$varName = parseInt(prompt(\"Entrez $varName:\"));");
            } else if (type == 'reel' || type == 'réel') {
              reads.add("$varName = parseFloat(prompt(\"Entrez $varName:\"));");
            } else {
              reads.add("$varName = prompt(\"Entrez $varName:\");");
            }
          }
          res = reads.join("\n");
        }
      }
      return res;
    }

    // Si ... Alors
    if (cleanLine.startsWith('si ')) {
      res = res.replaceFirst(RegExp(r'si\s+', caseSensitive: false), 'if (');
      res = res.replaceFirst(
        RegExp(r'\s+alors\s*$', caseSensitive: false),
        ') {',
      );
      return res;
    }

    if (cleanLine == 'sinon') return "} else {";

    if (cleanLine.startsWith('sinon si')) {
      res = res.replaceFirst(
        RegExp(r'sinon\s+si\s+', caseSensitive: false),
        '} else if (',
      );
      res = res.replaceFirst(
        RegExp(r'\s+alors\s*$', caseSensitive: false),
        ') {',
      );
      return res;
    }

    // Boucle TantQue
    if (cleanLine.startsWith('tantque ')) {
      res = res.replaceFirst(
        RegExp(r'tantque\s+', caseSensitive: false),
        'while (',
      );
      res = res.replaceFirst(
        RegExp(r'\s+faire\s*$', caseSensitive: false),
        ') {',
      );
      return res;
    }

    // Boucle Pour
    final pourReg = RegExp(
      r'^pour\s+([a-zA-Z_]\w*)\s*(?:<-|de)\s+(.*)\s+(?:a|à)\s+(.*)\s+faire$',
      caseSensitive: false,
    );
    final pourMatch = pourReg.firstMatch(res);
    if (pourMatch != null) {
      final varName = pourMatch.group(1)!;
      final start = pourMatch.group(2)!.trim();
      final end = pourMatch.group(3)!.trim();
      res = "for (let $varName = $start; $varName <= $end; $varName++) {";
      return res;
    }

    // Boucle Répéter...Jusqu'à
    if (cleanLine.startsWith('repeter')) return "do {";

    if (cleanLine.startsWith('jusqua ')) {
      final match = RegExp(
        r'jusqua\s+(.*)',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final condition = match.group(1)!.trim();
        res = "} while (!($condition));";
      }
      return res;
    }

    // Selon...Cas
    if (cleanLine.startsWith('selon ')) {
      final match = RegExp(
        r'selon\s+(.*)\s+faire',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final variable = match.group(1)!.trim();
        res = "switch ($variable) {";
      }
      return res;
    }

    if (cleanLine.startsWith('cas ')) {
      final match = RegExp(
        r'cas\s+(.*)\s*:',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final val = match.group(1)!.trim();
        res = "  case $val:";
      }
      return res;
    }

    if (cleanLine == 'sinon' || cleanLine == 'autre') return "  default:";

    // Fonctions / Procédures
    if (cleanLine.startsWith('fonction ') ||
        cleanLine.startsWith('procedure ')) {
      final match = RegExp(
        r'(?:fonction|procedure)\s+([a-zA-Z_]\w*)\s*\((.*)\)',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final nom = match.group(1)!;
        final params = match.group(2)!.trim();
        String paramsJS = "";
        if (params.isNotEmpty) {
          paramsJS = params
              .split(',')
              .map((p) => p.split(':')[0].trim())
              .join(', ');
        }
        res = "function $nom($paramsJS) {";
      }
      return res;
    }

    if (cleanLine.startsWith('retourner ')) {
      res = res.replaceFirst(
        RegExp(r'retourner\s+', caseSensitive: false),
        'return ',
      );
      res += ';';
      return res;
    }

    // Opérateurs logiques
    res = res.replaceAll(RegExp(r'\bET\b', caseSensitive: false), '&&');
    res = res.replaceAll(RegExp(r'\bet\b'), '&&');
    res = res.replaceAll(RegExp(r'\bOU\b', caseSensitive: false), '||');
    res = res.replaceAll(RegExp(r'\bou\b'), '||');
    res = res.replaceAll(RegExp(r'\bNON\b', caseSensitive: false), '!');
    res = res.replaceAll(RegExp(r'\bnon\b'), '!');

    // Opérateurs mathématiques
    res = res.replaceAll(RegExp(r'\bMOD\b', caseSensitive: false), '%');
    res = res.replaceAll(RegExp(r'\bmod\b'), '%');
    res = res.replaceAll(RegExp(r'\bDIV\b', caseSensitive: false), '/');
    res = res.replaceAll(RegExp(r'\bdiv\b'), '/');

    // FunMath
    res = res.replaceAll(
      RegExp(r"\bracine_carree\b", caseSensitive: false),
      "Math.sqrt",
    );
    res = res.replaceAll(RegExp(r"\babs\b", caseSensitive: false), "Math.abs");
    res = res.replaceAll(
      RegExp(r"\bpuissance\b", caseSensitive: false),
      "Math.pow",
    );

    // Constantes booléennes
    res = res.replaceAll(RegExp(r'\bVrai\b', caseSensitive: false), 'true');
    res = res.replaceAll(RegExp(r'\bvrai\b'), 'true');
    res = res.replaceAll(RegExp(r'\bFaux\b', caseSensitive: false), 'false');
    res = res.replaceAll(RegExp(r'\bfaux\b'), 'false');

    // Semicolon
    if (!res.endsWith('{') &&
        !res.endsWith('}') &&
        !res.endsWith(';') &&
        res.isNotEmpty &&
        !res.trim().startsWith('case') &&
        !res.trim().startsWith('default')) {
      res += ';';
    }

    return res;
  }
}
