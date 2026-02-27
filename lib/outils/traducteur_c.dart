import '../interpreteur/utils.dart';

/// Traducteur Pseudo-code → C
class TraducteurC {
  static String traduire(List<String> lignes) {
    final StringBuffer sb = StringBuffer();

    bool utiliseIO = false;
    bool utiliseString = false;
    bool utiliseBool = false;
    bool utiliseMath = false;

    final Map<String, String> symboles = {};

    // Passe 1 : includes + collecte des types
    for (final l in lignes) {
      final lower = l.toLowerCase();
      if (lower.contains('afficher') ||
          lower.contains('ecrire') ||
          lower.contains('lire'))
        utiliseIO = true;
      if (lower.contains('chaine') ||
          lower.contains('longueur(') ||
          lower.contains('long(') ||
          lower.contains('maj(') ||
          lower.contains('minus(') ||
          lower.contains('car(') ||
          lower.contains('en_chaine('))
        utiliseString = true;
      if (lower.contains('booleen') ||
          lower.contains('vrai') ||
          lower.contains('faux'))
        utiliseBool = true;
      if (lower.contains('racine_carree') ||
          lower.contains('racine(') ||
          lower.contains('puissance(') ||
          lower.contains('pow(') ||
          lower.contains('arrondi('))
        utiliseMath = true;

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
            for (final n
                in nomsStr.split(',').map((e) => e.trim().toLowerCase())) {
              if (n.isNotEmpty) symboles[n] = type;
            }
          }
        } catch (_) {}
      }
    }

    if (utiliseIO) sb.writeln('#include <stdio.h>');
    sb.writeln('#include <stdlib.h>');
    if (utiliseString) sb.writeln('#include <string.h>');
    if (utiliseBool) sb.writeln('#include <stdbool.h>');
    if (utiliseMath) sb.writeln('#include <math.h>');
    sb.writeln('#include <time.h>');
    sb.writeln('');

    // Injection des Helpers
    if (utiliseString) {
      sb.writeln('// Helpers pour les chaînes');
      sb.writeln(
        'void _maj(char* s) { while(*s) { *s = toupper((unsigned char)*s); s++; } }',
      );
      sb.writeln(
        'void _minus(char* s) { while(*s) { *s = tolower((unsigned char)*s); s++; } }',
      );
      sb.writeln(
        'bool _est_numerique(const char* s) { char* end; strtod(s, &end); return *s != \'\\0\' && *end == \'\\0\'; }',
      );
      sb.writeln('');
    }
    sb.writeln(
      'int _hasard(int a, int b) { return rand() % (b - a + 1) + a; }',
    );
    sb.writeln('');

    final StringBuffer structBuffer = StringBuffer();
    final StringBuffer funcProtoBuffer = StringBuffer();
    final StringBuffer funcImplBuffer = StringBuffer();
    final StringBuffer mainBuffer = StringBuffer();

    String sectionActuelle = 'main';
    String nomStructure = '';
    int indentation = 1;
    bool dansVariablesMain = false;
    final List<String> varsMainDeclarations = [];

    for (final l in lignes) {
      final String ligne = l.trim();
      final String lower = ligne.toLowerCase();

      if (ligne.isEmpty) continue;

      // Commentaires
      if (ligne.startsWith('//')) {
        final comment = '  ' * indentation + '// ${ligne.substring(2).trim()}';
        if (sectionActuelle == 'main')
          mainBuffer.writeln(comment);
        else if (sectionActuelle == 'structure')
          structBuffer.writeln('  ${ligne.substring(2).trim()}');
        else
          funcImplBuffer.writeln(comment);
        continue;
      }

      // En-tête algorithme
      if (lower.startsWith('algorithme')) {
        mainBuffer.writeln(
          '// --- Algorithme: ${ligne.substring(10).trim()} ---',
        );
        continue;
      }

      // Fin principale
      if (lower == 'fin' || lower == 'fin algorithme' || lower == 'fin.')
        continue;

      // Structures
      if (lower.startsWith('type ') && lower.contains('structure')) {
        sectionActuelle = 'structure';
        nomStructure = ligne
            .split('=')[0]
            .replaceAll(RegExp(r'type\s+', caseSensitive: false), '')
            .trim();
        structBuffer.writeln('typedef struct {');
        continue;
      }

      if (lower == 'finstructure') {
        structBuffer.writeln('} $nomStructure;');
        structBuffer.writeln('');
        sectionActuelle = 'main';
        continue;
      }

      // Fonctions / Procédures
      if (lower.startsWith('fonction ') || lower.startsWith('procedure ')) {
        sectionActuelle = 'fonction';
        indentation = 1;
        final estFonction = lower.startsWith('fonction');
        final match = RegExp(
          r'(?:fonction|procedure)\s+([a-zA-Z_]\w*)\s*\((.*)\)(?:\s*:\s*(\w+))?',
          caseSensitive: false,
        ).firstMatch(ligne);

        if (match != null) {
          final nom = match.group(1)!;
          final paramsStr = match.group(2)!;
          final returnTypeStr = match.group(3) ?? '';
          final cReturnType = estFonction ? _mapType(returnTypeStr) : 'void';
          final cParams = _parseParams(paramsStr);
          final signature = '$cReturnType $nom(${cParams.join(', ')})';
          funcProtoBuffer.writeln('$signature;');
          funcImplBuffer.writeln('$signature {');
        }
        continue;
      }

      if (lower == 'finfonction' || lower == 'finprocedure') {
        funcImplBuffer.writeln('}');
        funcImplBuffer.writeln('');
        sectionActuelle = 'main';
        indentation = 1;
        continue;
      }

      // Contenu Structure
      if (sectionActuelle == 'structure') {
        if (ligne.contains(':')) {
          final parts = ligne.split(':');
          final champ = parts[0].trim();
          final type = parts[1].trim();
          if (type.toLowerCase() == 'chaine') {
            structBuffer.writeln('  char $champ[256];');
          } else if (type.toLowerCase().startsWith('tableau')) {
            final size = _parseTailleTableau(type);
            structBuffer.writeln('  int $champ[$size];');
          } else {
            structBuffer.writeln('  ${_mapType(type)} $champ;');
          }
        }
        continue;
      }

      // Contenu Fonction
      if (sectionActuelle == 'fonction') {
        if (lower == 'variables' || lower == 'debut' || lower == 'début')
          continue;

        // Déclaration locale
        if (ligne.contains(':') &&
            !lower.startsWith('cas') &&
            !lower.contains('=') &&
            !lower.startsWith('si') &&
            !lower.startsWith('tantque')) {
          _ecrireDeclarationsC(ligne, funcImplBuffer, '  ');
          continue;
        }

        // Fin de bloc (avant écriture)
        if (_estFinBloc(lower)) {
          indentation = (indentation - 1).clamp(1, 50);
          funcImplBuffer.writeln(
            '${'  ' * indentation}${_convertir(ligne, symboles)}',
          );
          continue;
        }

        if (lower == 'sinon' || lower.startsWith('sinon si ')) {
          indentation = (indentation - 1).clamp(1, 50);
          funcImplBuffer.writeln(
            '${'  ' * indentation}${_convertir(ligne, symboles)}',
          );
          indentation++;
          continue;
        }

        funcImplBuffer.writeln(
          '${'  ' * indentation}${_convertir(ligne, symboles)}',
        );
        if (_estDebutBloc(lower)) indentation++;
        continue;
      }

      // Contenu Main
      if (sectionActuelle == 'main') {
        if (lower == 'variables') {
          dansVariablesMain = true;
          continue;
        }
        if (lower == 'debut' || lower == 'début') {
          dansVariablesMain = false;
          continue;
        }

        if (dansVariablesMain && ligne.contains(':')) {
          _collecterVarsMain(ligne, varsMainDeclarations);
          continue;
        }

        if (_estFinBloc(lower)) {
          indentation = (indentation - 1).clamp(1, 50);
          mainBuffer.writeln(
            '${'  ' * indentation}${_convertir(ligne, symboles)}',
          );
          continue;
        }

        if (lower == 'sinon' || lower.startsWith('sinon si ')) {
          indentation = (indentation - 1).clamp(1, 50);
          mainBuffer.writeln(
            '${'  ' * indentation}${_convertir(ligne, symboles)}',
          );
          indentation++;
          continue;
        }

        mainBuffer.writeln(
          '${'  ' * indentation}${_convertir(ligne, symboles)}',
        );
        if (_estDebutBloc(lower)) indentation++;
      }
    }

    // Assemblage
    sb.write(structBuffer.toString());
    if (funcProtoBuffer.isNotEmpty) {
      sb.write(funcProtoBuffer.toString());
      sb.writeln('');
    }

    sb.writeln('int main() {');
    sb.writeln('  srand(time(NULL));');
    for (final v in varsMainDeclarations) sb.writeln(v);
    if (varsMainDeclarations.isNotEmpty) sb.writeln('');
    sb.write(mainBuffer.toString());
    sb.writeln('  return 0;');
    sb.writeln('}');

    if (funcImplBuffer.isNotEmpty) {
      sb.writeln('');
      sb.write(funcImplBuffer.toString());
    }

    return sb.toString();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _mapType(String t) {
    switch (t.trim().toLowerCase()) {
      case 'entier':
        return 'int';
      case 'reel':
      case 'réel':
        return 'float';
      case 'chaine':
        return 'char[256]';
      case 'booleen':
        return 'bool';
      case 'caractere':
        return 'char';
      default:
        return t.trim().isEmpty ? 'void' : t.trim();
    }
  }

  static String _parseTailleTableau(String type) {
    final m2d = RegExp(r'\[(.*),(.*)\]').firstMatch(type);
    if (m2d != null) {
      return '${_parseDim(m2d.group(1)!)}][${_parseDim(m2d.group(2)!)}';
    }
    final m = RegExp(r'\[.*\.{2}(.*)\]').firstMatch(type);
    if (m != null) return _parseDim(m.group(1)!);
    return '100';
  }

  static String _parseDim(String raw) {
    if (raw.contains('..')) return raw.split('..').last.trim();
    return raw.trim();
  }

  static List<String> _parseParams(String paramsStr) {
    if (paramsStr.trim().isEmpty) return [];
    return paramsStr.split(',').map((p) {
      final parts = p.split(':');
      if (parts.length != 2) return 'int ${p.trim()}';
      final nom = parts[0].trim();
      final type = parts[1].trim().toLowerCase();
      if (type.startsWith('tableau')) {
        if (type.contains(',')) return 'int (*$nom)[100]';
        return 'int* $nom';
      }
      final ct = _mapType(type);
      return ct.contains('[') ? 'char* $nom' : '$ct $nom';
    }).toList();
  }

  static void _ecrireDeclarationsC(
    String ligne,
    StringBuffer buf,
    String indent,
  ) {
    final parts = ligne.split(':');
    if (parts.length < 2) return;
    final noms = parts[0]
        .split(',')
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty);
    final type = parts[1].trim();
    final cType = _mapType(type);

    for (final n in noms) {
      if (type.toLowerCase() == 'chaine') {
        buf.writeln('${indent}char $n[256];');
      } else if (type.toLowerCase().startsWith('tableau')) {
        final size = _parseTailleTableau(type);
        if (size.contains('][')) {
          buf.writeln('${indent}int $n[$size];');
        } else {
          buf.writeln('${indent}int $n[$size];');
        }
      } else if (cType.contains('[')) {
        final base = cType.split('[')[0];
        final dim = '[${cType.split('[')[1]}';
        buf.writeln('$indent$base $n$dim;');
      } else {
        buf.writeln('$indent$cType $n;');
      }
    }
  }

  static void _collecterVarsMain(String ligne, List<String> out) {
    final parts = ligne.split(':');
    if (parts.length < 2) return;
    final typeStr = parts[1].trim();
    final noms = parts[0]
        .split(',')
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty);

    for (final n in noms) {
      if (typeStr.toLowerCase() == 'chaine') {
        out.add('  char $n[256];');
      } else if (typeStr.toLowerCase().startsWith('tableau')) {
        final size = _parseTailleTableau(typeStr);
        if (size.contains('][')) {
          out.add('  int $n[$size];');
        } else {
          out.add('  int $n[$size];');
        }
      } else {
        final cType = _mapType(typeStr);
        if (cType.contains('[')) {
          final base = cType.split('[')[0];
          final dim = '[${cType.split('[')[1]}';
          out.add('  $base $n$dim;');
        } else {
          out.add('  $cType $n;');
        }
      }
    }
  }

  static bool _estDebutBloc(String l) =>
      l.endsWith('alors') ||
      l.endsWith('faire') ||
      l.startsWith('cas ') ||
      l == 'sinon' ||
      l == 'autre';

  static bool _estFinBloc(String l) =>
      l.startsWith('finsi') ||
      l.startsWith('fintantque') ||
      l.startsWith('finpour') ||
      l.startsWith('fpour') ||
      l.startsWith('finselon') ||
      l == 'finfonction' ||
      l == 'finprocedure';

  static String _convertir(String ligne, Map<String, String> symboles) {
    String res = ligne;
    final lower = ligne.trim().toLowerCase();

    // 1. Détection des assignations de chaînes (Cible = Chaine)
    if (res.contains('<-') || res.contains('←') || res.contains('=')) {
      final parts = res.split(RegExp(r'<-|←|='));
      if (parts.length == 2) {
        final gauche = parts[0].trim();
        final droite = parts[1].trim();
        final typeG = symboles[gauche.toLowerCase()];
        if (typeG == 'chaine') {
          return 'strcpy($gauche, ${_convertirExpression(droite, symboles)});';
        }
      }
    }

    res = res.replaceAll('<-', '=').replaceAll('←', '=');

    // Fermetures de blocs → }
    if (lower.startsWith('finsi') ||
        lower.startsWith('fintantque') ||
        lower.startsWith('finpour') ||
        lower.startsWith('fpour') ||
        lower.startsWith('finselon'))
      return '}';

    // Afficher / Ecrire
    if (lower.startsWith('afficher(') || lower.startsWith('ecrire(')) {
      final isEcrire = lower.startsWith('ecrire(');
      final match = RegExp(
        isEcrire ? r'ecrire\s*\((.*)\)' : r'afficher\s*\((.*)\)',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final args = InterpreteurUtils.splitArguments(match.group(1)!);
        if (args.isEmpty) return 'printf("\\n");';
        final formats = <String>[];
        final vals = <String>[];
        for (final arg in args) {
          final a = arg.trim();
          if (a.startsWith('"') && a.endsWith('"')) {
            formats.add('%s');
            vals.add(a);
          } else {
            final firstWord = a
                .split(RegExp(r'\W'))
                .firstWhere((e) => e.isNotEmpty, orElse: () => '');
            final type = symboles[firstWord.toLowerCase()];
            String fmt = '%d';
            if (type == 'reel' || type == 'réel')
              fmt = '%g'; // %g est plus propre pour les réels
            else if (type == 'chaine')
              fmt = '%s';
            else if (type == 'caractere')
              fmt = '%c';
            else if (a.contains('.') ||
                a.contains('/') ||
                a.contains('racine') ||
                a.contains('sin(') ||
                a.contains('cos('))
              fmt = '%g';
            formats.add(fmt);
            vals.add(_convertirExpression(a, symboles));
          }
        }
        return 'printf("${formats.join(' ')}\\n", ${vals.join(', ')});';
      }
    }

    // Lire
    if (lower.startsWith('lire(')) {
      final match = RegExp(
        r'lire\s*\((.*)\)',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final args = InterpreteurUtils.splitArguments(match.group(1)!);
        if (args.isEmpty) return '// lire() sans argument';
        final scans = args.map((arg) {
          final varName = arg.trim();
          final type = symboles[varName.toLowerCase()];
          if (type == 'reel' || type == 'réel')
            return 'scanf("%f", &$varName);';
          if (type == 'chaine') return 'scanf("%s", $varName);';
          if (type == 'caractere') return 'scanf(" %c", &$varName);';
          return 'scanf("%d", &$varName);';
        }).toList();
        return scans.join('\n');
      }
    }

    // Si...Alors
    if (lower.startsWith('si ')) {
      res = res.replaceFirst(RegExp(r'si\s+', caseSensitive: false), 'if (');
      res = res.replaceFirst(
        RegExp(r'\s+alors\s*$', caseSensitive: false),
        ') {',
      );
      return res;
    }
    if (lower == 'sinon') return '} else {';
    if (lower.startsWith('sinon si ')) {
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

    // TantQue
    if (lower.startsWith('tantque ')) {
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

    // Pour
    final pourMatch = RegExp(
      r'^pour\s+([a-zA-Z_]\w*)\s*(?:<-|de)\s+(.*)\s+(?:a|à)\s+(.*)\s+faire$',
      caseSensitive: false,
    ).firstMatch(res);
    if (pourMatch != null) {
      final v = pourMatch.group(1)!;
      final start = pourMatch.group(2)!.trim();
      final end = pourMatch.group(3)!.trim();
      return 'for (int $v = $start; $v <= $end; $v++) {';
    }

    // Répéter / Jusqu'à
    if (lower.startsWith('repeter')) return 'do {';
    if (lower.startsWith('jusqua ')) {
      final m = RegExp(r'jusqua\s+(.*)', caseSensitive: false).firstMatch(res);
      if (m != null) return '} while (!(${m.group(1)!.trim()}));';
    }

    // Selon / Cas
    if (lower.startsWith('selon ')) {
      final m = RegExp(
        r'selon\s+(.*)\s+faire',
        caseSensitive: false,
      ).firstMatch(res);
      if (m != null) return 'switch (${m.group(1)!.trim()}) {';
    }
    if (lower.startsWith('cas ')) {
      final m = RegExp(r'cas\s+(.*)\s*:', caseSensitive: false).firstMatch(res);
      if (m != null) return 'case ${m.group(1)!.trim()}:';
    }
    if (lower == 'autre') return 'default:';

    // Retourner
    if (lower.startsWith('retourner ')) {
      final m = RegExp(
        r'retourner\s+(.*)',
        caseSensitive: false,
      ).firstMatch(res);
      if (m != null) return 'return ${m.group(1)!.trim()};';
    }

    // Accès tableau 2D
    res = res.replaceAllMapped(
      RegExp(r'\[\s*([^\[\],]+)\s*,\s*([^\[\],]+)\s*\]'),
      (m) => '[${m.group(1)}][${m.group(2)}]',
    );

    // Opérateurs logiques
    res = res.replaceAll(RegExp(r'\bET\b', caseSensitive: false), '&&');
    res = res.replaceAll(RegExp(r'\bOU\b', caseSensitive: false), '||');
    res = res.replaceAll(RegExp(r'\bNON\b', caseSensitive: false), '!');

    // Opérateurs mathématiques
    res = res.replaceAll(RegExp(r'\bMOD\b', caseSensitive: false), '%');
    res = res.replaceAll(RegExp(r'\bDIV\b', caseSensitive: false), '/');

    res = res.replaceAll(RegExp(r'\bVrai\b', caseSensitive: false), 'true');
    res = res.replaceAll(RegExp(r'\bFaux\b', caseSensitive: false), 'false');

    res = _convertirExpression(res, symboles);

    // Point-virgule pour les lignes qui ne sont pas des structures de contrôle
    if (!res.endsWith('{') &&
        !res.endsWith('}') &&
        !res.endsWith(';') &&
        res.isNotEmpty &&
        !lower.startsWith('case') &&
        !lower.startsWith('default')) {
      res += ';';
    }

    return res;
  }

  /// Helper pour convertir une expression (utilisé dans assignations et printf)
  static String _convertirExpression(
    String expr,
    Map<String, String> symboles,
  ) {
    String res = expr;

    // Opérateurs logiques
    res = res.replaceAll(RegExp(r'\bET\b', caseSensitive: false), '&&');
    res = res.replaceAll(RegExp(r'\bOU\b', caseSensitive: false), '||');
    res = res.replaceAll(RegExp(r'\bNON\b', caseSensitive: false), '!');

    // Opérateurs mathématiques
    res = res.replaceAll(RegExp(r'\bMOD\b', caseSensitive: false), '%');
    res = res.replaceAll(RegExp(r'\bDIV\b', caseSensitive: false), '/');

    // Fonctions math
    res = res.replaceAll(
      RegExp(r'\bracine_carree\b', caseSensitive: false),
      'sqrt',
    );
    res = res.replaceAll(RegExp(r'\bpuissance\b', caseSensitive: false), 'pow');
    res = res.replaceAll(
      RegExp(r'\babs\b', caseSensitive: false),
      'fabs',
    ); // fabs pour double

    // Fonctions natives
    res = _convertirFonctionsNatives(res);

    return res;
  }

  /// Traduit les appels aux fonctions natives du pseudo-code en C
  static String _convertirFonctionsNatives(String res) {
    // 2-arg : car(s, i) -> s[i-1]
    res = res.replaceAllMapped(
      RegExp(r'\bcar\s*\(([^,)]+),\s*([^)]+)\)', caseSensitive: false),
      (m) =>
          '(${m.group(1)?.toString().trim() ?? ""})[(${m.group(2)?.toString().trim() ?? ""}) - 1]',
    );
    // 2-arg : hasard(a, b) -> _hasard(a, b)
    res = res.replaceAllMapped(
      RegExp(r'\bhasard\s*\(([^,)]+),\s*([^)]+)\)', caseSensitive: false),
      (m) =>
          '_hasard(${m.group(1)?.trim() ?? ""}, ${m.group(2)?.trim() ?? ""})',
    );
    // 1-arg
    res = res.replaceAllMapped(
      RegExp(r'\b(?:long|longueur)\s*\(([^)]+)\)', caseSensitive: false),
      (m) => 'strlen(${m.group(1)})',
    );
    // maj(s) : utilise le helper _maj
    res = res.replaceAllMapped(
      RegExp(r'\bmaj\s*\(([^)]+)\)', caseSensitive: false),
      (m) =>
          '(_maj(${m.group(1)}), ${m.group(1)})', // Utilise comma operator pour retourner la chaine
    );
    res = res.replaceAllMapped(
      RegExp(r'\bminus\s*\(([^)]+)\)', caseSensitive: false),
      (m) => '(_minus(${m.group(1)}), ${m.group(1)})',
    );
    res = res.replaceAllMapped(
      RegExp(r'\bracine\s*\(([^)]+)\)', caseSensitive: false),
      (m) => 'sqrt(${m.group(1)})',
    );
    res = res.replaceAllMapped(
      RegExp(r'\barrondi\s*\(([^)]+)\)', caseSensitive: false),
      (m) => 'round(${m.group(1)})',
    );
    res = res.replaceAllMapped(
      RegExp(r'\btronque\s*\(([^)]+)\)', caseSensitive: false),
      (m) => '((int)(${m.group(1)}))',
    );
    res = res.replaceAllMapped(
      RegExp(r'\ben_entier\s*\(([^)]+)\)', caseSensitive: false),
      (m) => 'atoi(${m.group(1)})',
    );
    res = res.replaceAllMapped(
      RegExp(r'\ben_reel\s*\(([^)]+)\)', caseSensitive: false),
      (m) => 'atof(${m.group(1)})',
    );
    res = res.replaceAllMapped(
      RegExp(r'\ben_chaine\s*\(([^)]+)\)', caseSensitive: false),
      (m) => '/* en_chaine non trivial en C */ (${m.group(1)})',
    );
    res = res.replaceAllMapped(
      RegExp(r'\btypevar\s*\(([^)]+)\)', caseSensitive: false),
      (m) => '"inconnu"',
    );
    res = res.replaceAllMapped(
      RegExp(r'\best_numerique\s*\(([^)]+)\)', caseSensitive: false),
      (m) => '_est_numerique(${m.group(1)})',
    );
    return res;
  }
}
