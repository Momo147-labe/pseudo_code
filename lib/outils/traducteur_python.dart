import '../interpreteur/utils.dart';

/// Traducteur Pseudo-code → Python
class TraducteurPython {
  static String traduire(List<String> lignes) {
    final StringBuffer sb = StringBuffer();
    int indentation = 0;
    bool dansVariables = false;

    bool utiliseMath = false;
    final Map<String, String> symboles = {};

    bool utiliseRandom = false;

    // Passe 1 : collecte des types et imports
    for (final l in lignes) {
      final lower = l.toLowerCase();
      if (lower.contains('racine_carree') ||
          lower.contains('racine(') ||
          lower.contains('puissance(') ||
          lower.contains('abs(')) {
        utiliseMath = true;
      }
      if (lower.contains('hasard(')) utiliseRandom = true;
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
            for (final n in nomsStr.split(',').map((e) => e.trim())) {
              if (n.isNotEmpty) symboles[n.toLowerCase()] = type;
            }
          }
        } catch (_) {}
      }
    }

    if (utiliseMath) sb.writeln('import math');
    if (utiliseRandom) sb.writeln('import random');

    for (final l in lignes) {
      final String ligne = l.trim();
      final String lower = ligne.toLowerCase();

      if (ligne.isEmpty) {
        sb.writeln('');
        continue;
      }

      // Commentaires
      if (ligne.startsWith('//')) {
        sb.writeln('${'  ' * indentation}# ${ligne.substring(2).trim()}');
        continue;
      }

      // Entête algorithme
      if (lower.startsWith('algorithme')) {
        final nom = ligne.split(' ').skip(1).join(' ').trim();
        sb.writeln('# --- Algorithme: $nom ---');
        continue;
      }

      // Section Variables
      if (lower == 'variables') {
        dansVariables = true;
        sb.writeln('${'  ' * indentation}# === Variables ===');
        continue;
      }

      if (lower == 'debut' || lower == 'début') {
        dansVariables = false;
        continue;
      }

      if (lower == 'fin') break;

      // Types/Structures
      if (lower.startsWith('type ') && !lower.contains('structure')) {
        sb.writeln(
          '${'  ' * indentation}# Type: $ligne (Implémentez ces types comme des classes Python)',
        );
        continue;
      }

      if (lower.startsWith('type ') && lower.contains('structure')) {
        final nomType = ligne
            .replaceAll(RegExp(r'type\s+', caseSensitive: false), '')
            .split('=')[0]
            .trim();
        sb.writeln('class $nomType:');
        sb.writeln('  def __init__(self):');
        continue;
      }

      if (lower == 'finstructure') {
        indentation = 0;
        // Fin de la classe, rien à écrire
        continue;
      }

      // Constantes
      if (lower.startsWith('const ')) {
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
            sb.writeln('${'  ' * indentation}$nom = $valeur  # Constante');
          }
        }
        continue;
      }

      // Déclarations de variables
      if (dansVariables && ligne.contains(':')) {
        final parts = ligne.split(':');
        final noms = parts[0]
            .split(',')
            .map((e) => e.trim())
            .where((n) => n.isNotEmpty);
        final type = parts[1].trim().toLowerCase();

        if (type.startsWith('tableau')) {
          // Extraction de la taille
          int taille = 10;
          final m = RegExp(r'\[.*\.{2}(.*)\]').firstMatch(type);
          if (m != null) taille = int.tryParse(m.group(1)!.trim()) ?? 10;

          // Détection 2D
          final m2d = RegExp(r'\[(.*),(.*)\]').firstMatch(type);
          if (m2d != null) {
            final d1 = _parseDim(m2d.group(1)!);
            final d2 = _parseDim(m2d.group(2)!);
            for (final n in noms) {
              sb.writeln(
                '${'  ' * indentation}$n = [[0] * $d2 for _ in range($d1)]  # Tableau 2D',
              );
            }
          } else {
            for (final n in noms) {
              sb.writeln('${'  ' * indentation}$n = [0] * $taille  # Tableau');
            }
          }
        } else if (type == 'entier') {
          for (final n in noms) sb.writeln('${'  ' * indentation}$n = 0');
        } else if (type == 'reel' || type == 'réel') {
          for (final n in noms) sb.writeln('${'  ' * indentation}$n = 0.0');
        } else if (type == 'chaine') {
          for (final n in noms) sb.writeln('${'  ' * indentation}$n = ""');
        } else if (type == 'booleen') {
          for (final n in noms) sb.writeln('${'  ' * indentation}$n = False');
        } else if (type == 'caractere') {
          for (final n in noms) sb.writeln('${'  ' * indentation}$n = \'\'');
        } else {
          for (final n in noms)
            sb.writeln('${'  ' * indentation}$n = None  # type: $type');
        }
        continue;
      }

      // Réduction de l'indentation avant d'écrire les fins de blocs
      if (_estFinBloc(lower)) {
        indentation = (indentation - 1).clamp(0, 50);
        // Les mots-clés de fermeture Python sont déjà pris en charge
        // (finsi → pas de ligne, sinon → else:, etc.) donc on continue
        continue;
      }

      // Sinon / Sinon Si → réduction avant, augmentation après
      if (lower == 'sinon' || lower.startsWith('sinon si ')) {
        indentation = (indentation - 1).clamp(0, 50);
        final instPy = _convertir(ligne, symboles);
        sb.writeln('${'  ' * indentation}$instPy');
        indentation++;
        continue;
      }

      final instPy = _convertir(ligne, symboles);
      sb.writeln('${'  ' * indentation}$instPy');

      // Augmenter l'indentation pour les ouvertures de blocs
      if (_estDebutBloc(lower)) indentation++;
    }

    return sb.toString();
  }

  static bool _estDebutBloc(String l) =>
      l.endsWith('alors') ||
      l.endsWith('faire') ||
      l.endsWith(':') && (l.startsWith('def ') || l.startsWith('class ')) ||
      l.startsWith('def ') ||
      l == 'else:' ||
      l.startsWith('elif ');

  static bool _estFinBloc(String l) =>
      l.startsWith('finsi') ||
      l.startsWith('fintantque') ||
      l.startsWith('finpour') ||
      l.startsWith('fpour') ||
      l.startsWith('finselon') ||
      l == 'finfonction' ||
      l == 'finprocedure';

  static String _parseDim(String raw) {
    if (raw.contains('..')) {
      return raw.split('..').last.trim();
    }
    return raw.trim();
  }

  static String _convertir(String ligne, Map<String, String> symboles) {
    String res = ligne;
    final lower = ligne.trim().toLowerCase();

    // Affectation
    res = res.replaceAll('<-', '=').replaceAll('←', '=');

    // Afficher / Ecrire
    if (lower.startsWith('afficher(') || lower.startsWith('ecrire(')) {
      final isEcrire = lower.startsWith('ecrire(');
      final match = RegExp(
        isEcrire ? r'ecrire\s*\((.*)\)' : r'afficher\s*\((.*)\)',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final args = InterpreteurUtils.splitArguments(match.group(1)!);
        if (args.isEmpty) return 'print()';
        return 'print(${args.map((a) => a.trim()).join(', ')})';
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
        if (args.isEmpty) return 'input()';
        final assignments = args.map((arg) {
          final varName = arg.trim();
          final type = symboles[varName.toLowerCase()] ?? '';
          if (type == 'entier')
            return '$varName = int(input("Entrez $varName: "))';
          if (type == 'reel' || type == 'réel')
            return '$varName = float(input("Entrez $varName: "))';
          return '$varName = input("Entrez $varName: ")';
        }).toList();
        return assignments.join('\n');
      }
    }

    // Si...Alors
    if (lower.startsWith('si ')) {
      res = res.replaceFirst(RegExp(r'si\s+', caseSensitive: false), 'if ');
      res = res.replaceFirst(
        RegExp(r'\s+alors\s*$', caseSensitive: false),
        ':',
      );
      return res;
    }

    if (lower == 'sinon') return 'else:';

    if (lower.startsWith('sinon si ')) {
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

    // TantQue
    if (lower.startsWith('tantque ')) {
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

    // Pour
    final pourMatch = RegExp(
      r'^pour\s+([a-zA-Z_]\w*)\s*(?:<-|de)\s+(.*)\s+(?:a|à)\s+(.*)\s+faire$',
      caseSensitive: false,
    ).firstMatch(res);
    if (pourMatch != null) {
      final v = pourMatch.group(1)!;
      final start = pourMatch.group(2)!.trim();
      final end = pourMatch.group(3)!.trim();
      return 'for $v in range($start, $end + 1):';
    }

    // Répéter / Jusqu'à
    if (lower.startsWith('repeter')) return 'while True:';
    if (lower.startsWith('jusqua ')) {
      final match = RegExp(
        r'jusqua\s+(.*)',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) return '  if ${match.group(1)!.trim()}: break';
    }

    // Selon / Cas (Python 3.10+)
    if (lower.startsWith('selon ')) {
      final match = RegExp(
        r'selon\s+(.*)\s+faire',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) return 'match ${match.group(1)!.trim()}:';
    }
    if (lower.startsWith('cas ')) {
      final match = RegExp(
        r'cas\s+(.*)\s*:',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) return '  case ${match.group(1)!.trim()}:';
    }
    if (lower == 'autre') return '  case _:';

    // Fonctions / Procédures
    if (lower.startsWith('fonction ') || lower.startsWith('procedure ')) {
      final match = RegExp(
        r'(?:fonction|procedure)\s+([a-zA-Z_]\w*)\s*\((.*)\)',
        caseSensitive: false,
      ).firstMatch(res);
      if (match != null) {
        final nom = match.group(1)!;
        final params = match.group(2)!.trim();
        final paramsPy = params.isEmpty
            ? ''
            : params.split(',').map((p) => p.split(':')[0].trim()).join(', ');
        return 'def $nom($paramsPy):';
      }
    }

    if (lower.startsWith('retourner ')) {
      return res.replaceFirst(
        RegExp(r'retourner\s+', caseSensitive: false),
        'return ',
      );
    }

    // Opérateurs logiques
    res = res.replaceAll(RegExp(r'\bET\b', caseSensitive: false), 'and');
    res = res.replaceAll(RegExp(r'\bOU\b', caseSensitive: false), 'or');
    res = res.replaceAll(RegExp(r'\bNON\b', caseSensitive: false), 'not');

    // Opérateurs mathématiques
    res = res.replaceAll(RegExp(r'\bMOD\b', caseSensitive: false), '%');
    res = res.replaceAll(RegExp(r'\bDIV\b', caseSensitive: false), '//');

    // Fonctions mathématiques
    res = res.replaceAll(
      RegExp(r'\bracine_carree\b', caseSensitive: false),
      'math.sqrt',
    );
    res = res.replaceAll(RegExp(r'\bpuissance\b', caseSensitive: false), 'pow');
    res = res.replaceAll(RegExp(r'\babs\b', caseSensitive: false), 'abs');

    // Booléens
    res = res.replaceAll(RegExp(r'\bVrai\b', caseSensitive: false), 'True');
    res = res.replaceAll(RegExp(r'\bFaux\b', caseSensitive: false), 'False');

    // Fonctions natives
    res = _convertirFonctionsNatives(res);

    // Accès tableau 2D : T[i,j] -> T[i][j]
    res = res.replaceAllMapped(
      RegExp(r'\[\s*([^\[\],]+)\s*,\s*([^\[\],]+)\s*\]'),
      (m) => '[${m.group(1)}][${m.group(2)}]',
    );

    return res;
  }

  /// Traduit les appels aux fonctions natives du pseudo-code en Python
  static String _convertirFonctionsNatives(String res) {
    // 2-arg : car(s, i) -> s[i-1]
    res = res.replaceAllMapped(
      RegExp(r'\bcar\s*\(([^,)]+),\s*([^)]+)\)', caseSensitive: false),
      (m) =>
          '(${m.group(1).toString().trim()})[${m.group(2).toString().trim()} - 1]',
    );
    // 2-arg : hasard(a, b) -> random.randint(a, b)
    res = res.replaceAllMapped(
      RegExp(r'\bhasard\s*\(([^,)]+),\s*([^)]+)\)', caseSensitive: false),
      (m) =>
          'random.randint(${m.group(1).toString().trim()}, ${m.group(2).toString().trim()})',
    );
    // 1-arg : simples renames
    res = res.replaceAllMapped(
      RegExp(r'\blong\s*\(([^)]+)\)', caseSensitive: false),
      (m) => 'len(${m.group(1)})',
    );
    res = res.replaceAllMapped(
      RegExp(r'\bmaj\s*\(([^)]+)\)', caseSensitive: false),
      (m) => '(${m.group(1)}).upper()',
    );
    res = res.replaceAllMapped(
      RegExp(r'\bminus\s*\(([^)]+)\)', caseSensitive: false),
      (m) => '(${m.group(1)}).lower()',
    );
    res = res.replaceAllMapped(
      RegExp(r'\bracine\s*\(([^)]+)\)', caseSensitive: false),
      (m) => 'math.sqrt(${m.group(1)})',
    );
    res = res.replaceAllMapped(
      RegExp(r'\barrondi\s*\(([^)]+)\)', caseSensitive: false),
      (m) => 'round(${m.group(1)})',
    );
    res = res.replaceAllMapped(
      RegExp(r'\btronque\s*\(([^)]+)\)', caseSensitive: false),
      (m) => 'int(${m.group(1)})',
    );
    res = res.replaceAllMapped(
      RegExp(r'\ben_entier\s*\(([^)]+)\)', caseSensitive: false),
      (m) => 'int(${m.group(1)})',
    );
    res = res.replaceAllMapped(
      RegExp(r'\ben_reel\s*\(([^)]+)\)', caseSensitive: false),
      (m) => 'float(${m.group(1)})',
    );
    res = res.replaceAllMapped(
      RegExp(r'\ben_chaine\s*\(([^)]+)\)', caseSensitive: false),
      (m) => 'str(${m.group(1)})',
    );
    res = res.replaceAllMapped(
      RegExp(r'\btypevar\s*\(([^)]+)\)', caseSensitive: false),
      (m) => 'type(${m.group(1)}).__name__',
    );
    res = res.replaceAllMapped(
      RegExp(r'\best_numerique\s*\(([^)]+)\)', caseSensitive: false),
      (m) => '(${m.group(1)}).isnumeric()',
    );
    return res;
  }
}
