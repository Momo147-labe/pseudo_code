import '../interpreteur/utils.dart';

/// Traducteur Pseudo-code → JavaScript
class TraducteurJS {
  static String traduire(List<String> lignes) {
    final StringBuffer classBuffer = StringBuffer();
    final StringBuffer funcBuffer = StringBuffer();
    final StringBuffer mainBuffer = StringBuffer();

    final Map<String, String> symboles = {};

    // Passe 1 : collecte des types
    for (final l in lignes) {
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

    String sectionActuelle = 'main';
    String nomEnCours = '';
    int indentation = 0;
    bool dansVariables = false;

    for (final l in lignes) {
      final String ligne = l.trim();
      final String lower = ligne.toLowerCase();

      if (ligne.isEmpty) continue;

      // Commentaires
      if (ligne.startsWith('//')) {
        final comment = '${'  ' * indentation}// ${ligne.substring(2).trim()}';
        if (sectionActuelle == 'main')
          mainBuffer.writeln(comment);
        else if (sectionActuelle == 'structure')
          classBuffer.writeln(comment);
        else
          funcBuffer.writeln(comment);
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

      // Structures → Classes JS
      if (lower.startsWith('type ') && lower.contains('structure')) {
        sectionActuelle = 'structure';
        nomEnCours = ligne
            .split('=')[0]
            .replaceAll(RegExp(r'type\s+', caseSensitive: false), '')
            .trim();
        classBuffer.writeln('class $nomEnCours {');
        classBuffer.writeln('  constructor() {');
        continue;
      }

      if (lower == 'finstructure') {
        classBuffer.writeln('  }');
        classBuffer.writeln('}');
        classBuffer.writeln('');
        sectionActuelle = 'main';
        continue;
      }

      // Fonctions / Procédures
      if (lower.startsWith('fonction ') || lower.startsWith('procedure ')) {
        sectionActuelle = 'fonction';
        indentation = 1;
        final match = RegExp(
          r'(?:fonction|procedure)\s+([a-zA-Z_]\w*)\s*\((.*)\)',
          caseSensitive: false,
        ).firstMatch(ligne);
        if (match != null) {
          final nom = match.group(1)!;
          final paramsStr = match.group(2)!.trim();
          final paramsJS = paramsStr.isEmpty
              ? ''
              : paramsStr
                    .split(',')
                    .map((p) => p.split(':')[0].trim())
                    .join(', ');
          funcBuffer.writeln('function $nom($paramsJS) {');
        } else {
          funcBuffer.writeln('function unknown() {');
        }
        continue;
      }

      if (lower == 'finfonction' || lower == 'finprocedure') {
        funcBuffer.writeln('}');
        funcBuffer.writeln('');
        sectionActuelle = 'main';
        indentation = 0;
        continue;
      }

      // Contenu Structure
      if (sectionActuelle == 'structure') {
        if (ligne.contains(':')) {
          final parts = ligne.split(':');
          final champ = parts[0].trim();
          final type = parts[1].trim().toLowerCase();
          String val = 'null';
          if (type.startsWith('entier') ||
              type.startsWith('reel') ||
              type.startsWith('réel'))
            val = '0';
          if (type.startsWith('chaine')) val = '""';
          if (type.startsWith('booleen')) val = 'false';
          if (type.startsWith('caractere')) val = "''";
          if (type.startsWith('tableau')) val = '[]';
          classBuffer.writeln('    this.$champ = $val;');
        }
        continue;
      }

      // Contenu Fonction
      if (sectionActuelle == 'fonction') {
        if (lower == 'variables' || lower == 'debut' || lower == 'début')
          continue;

        // Déclarations locales
        if (ligne.contains(':') &&
            !lower.startsWith('cas ') &&
            !lower.contains('=') &&
            !lower.startsWith('si ') &&
            !lower.startsWith('tantque ')) {
          final parts = ligne.split(':');
          final noms = parts[0]
              .split(',')
              .map((n) => n.trim())
              .where((n) => n.isNotEmpty);
          final type = parts[1].trim().toLowerCase();
          for (final n in noms) {
            if (type.startsWith('tableau')) {
              final size = _parseTailleTableau(type);
              funcBuffer.writeln('  let $n = new Array($size).fill(0);');
            } else if (type.startsWith('entier') ||
                type.startsWith('reel') ||
                type.startsWith('réel')) {
              funcBuffer.writeln('  let $n = 0;');
            } else if (type.startsWith('chaine')) {
              funcBuffer.writeln('  let $n = "";');
            } else if (type.startsWith('booleen')) {
              funcBuffer.writeln('  let $n = false;');
            } else {
              funcBuffer.writeln('  let $n;');
            }
          }
          continue;
        }

        if (_estFinBloc(lower)) {
          indentation = (indentation - 1).clamp(0, 50);
          funcBuffer.writeln(
            '${'  ' * indentation}${_convertir(ligne, symboles)}',
          );
          continue;
        }

        if (lower == 'sinon' || lower.startsWith('sinon si ')) {
          indentation = (indentation - 1).clamp(0, 50);
          funcBuffer.writeln(
            '${'  ' * indentation}${_convertir(ligne, symboles)}',
          );
          indentation++;
          continue;
        }

        funcBuffer.writeln(
          '${'  ' * indentation}${_convertir(ligne, symboles)}',
        );
        if (_estDebutBloc(lower)) indentation++;
        continue;
      }

      // Contenu Main
      if (sectionActuelle == 'main') {
        if (lower == 'variables') {
          dansVariables = true;
          continue;
        }
        if (lower == 'debut' || lower == 'début') {
          dansVariables = false;
          continue;
        }

        if (dansVariables && ligne.contains(':')) {
          final parts = ligne.split(':');
          final noms = parts[0]
              .split(',')
              .map((n) => n.trim())
              .where((n) => n.isNotEmpty);
          final type = parts[1].trim().toLowerCase();
          final primitifs = [
            'entier',
            'reel',
            'réel',
            'chaine',
            'booleen',
            'caractere',
            'tableau',
          ];
          final isStruct = !primitifs.any((t) => type.startsWith(t));

          for (final n in noms) {
            if (isStruct) {
              mainBuffer.writeln('let $n = new ${type.trim()}();');
            } else if (type.startsWith('tableau')) {
              final size = _parseTailleTableau(type);
              if (size.contains('][')) {
                // 2D
                final dims = size.split('][');
                mainBuffer.writeln(
                  'let $n = Array.from({length: ${dims[0]}}, () => new Array(${dims[1]}).fill(0));',
                );
              } else {
                mainBuffer.writeln('let $n = new Array($size).fill(0);');
              }
            } else if (type.startsWith('entier')) {
              mainBuffer.writeln('let $n = 0;');
            } else if (type.startsWith('reel') || type.startsWith('réel')) {
              mainBuffer.writeln('let $n = 0.0;');
            } else if (type.startsWith('chaine')) {
              mainBuffer.writeln('let $n = "";');
            } else if (type.startsWith('booleen')) {
              mainBuffer.writeln('let $n = false;');
            } else {
              mainBuffer.writeln('let $n;');
            }
          }
          continue;
        }

        if (_estFinBloc(lower)) {
          indentation = (indentation - 1).clamp(0, 50);
          mainBuffer.writeln(
            '${'  ' * indentation}${_convertir(ligne, symboles)}',
          );
          continue;
        }

        if (lower == 'sinon' || lower.startsWith('sinon si ')) {
          indentation = (indentation - 1).clamp(0, 50);
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

    final sb = StringBuffer();
    if (classBuffer.isNotEmpty) {
      sb.write(classBuffer.toString());
      sb.writeln('');
    }
    if (funcBuffer.isNotEmpty) {
      sb.write(funcBuffer.toString());
      sb.writeln('');
    }
    sb.writeln('// --- Main ---');
    sb.write(mainBuffer.toString());
    return sb.toString();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _parseTailleTableau(String type) {
    final m2d = RegExp(r'\[(.*),(.*)\]').firstMatch(type);
    if (m2d != null)
      return '${_parseDim(m2d.group(1)!)}][${_parseDim(m2d.group(2)!)}';
    final m = RegExp(r'\[.*\.{2}(.*)\]').firstMatch(type);
    if (m != null) return _parseDim(m.group(1)!);
    return '10';
  }

  static String _parseDim(String raw) {
    if (raw.contains('..')) return raw.split('..').last.trim();
    return raw.trim();
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
        if (args.isEmpty) return 'console.log();';

        // Construire une template string si mixte chaines + variables
        final parts = args.map((a) => a.trim()).toList();
        return 'console.log(${parts.join(', ')});';
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
        final reads = args.map((arg) {
          final varName = arg.trim();
          final type = symboles[varName.toLowerCase()] ?? '';
          if (type == 'entier')
            return '$varName = parseInt(prompt("Entrez $varName: "));';
          if (type == 'reel' || type == 'réel')
            return '$varName = parseFloat(prompt("Entrez $varName: "));';
          return '$varName = prompt("Entrez $varName: ");';
        }).toList();
        return reads.join('\n');
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
      return 'for (let $v = $start; $v <= $end; $v++) {';
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
      if (m != null) return '  case ${m.group(1)!.trim()}:';
    }
    if (lower == 'autre') return '  default:';

    // Retourner
    if (lower.startsWith('retourner ')) {
      res = res.replaceFirst(
        RegExp(r'retourner\s+', caseSensitive: false),
        'return ',
      );
      if (!res.endsWith(';')) res += ';';
      return res;
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

    // Fonctions math
    res = res.replaceAll(
      RegExp(r'\bracine_carree\b', caseSensitive: false),
      'Math.sqrt',
    );
    res = res.replaceAll(
      RegExp(r'\bpuissance\b', caseSensitive: false),
      'Math.pow',
    );
    res = res.replaceAll(RegExp(r'\babs\b', caseSensitive: false), 'Math.abs');

    // Booléens
    res = res.replaceAll(RegExp(r'\bVrai\b', caseSensitive: false), 'true');
    res = res.replaceAll(RegExp(r'\bFaux\b', caseSensitive: false), 'false');

    // Fonctions natives
    res = _convertirFonctionsNatives(res);

    // Point-virgule
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

  /// Traduit les appels aux fonctions natives du pseudo-code en JavaScript
  static String _convertirFonctionsNatives(String res) {
    // 2-arg : car(s, i) -> s[i-1]
    res = res.replaceAllMapped(
      RegExp(r'\bcar\s*\(([^,)]+),\s*([^)]+)\)', caseSensitive: false),
      (m) =>
          '(${m.group(1).toString().trim()})[(${m.group(2).toString().trim()}) - 1]',
    );
    // 2-arg : hasard(a, b) -> Math.floor(Math.random() * (b - a + 1)) + a
    res = res.replaceAllMapped(
      RegExp(r'\bhasard\s*\(([^,)]+),\s*([^)]+)\)', caseSensitive: false),
      (m) {
        final a = m.group(1)!.trim();
        final b = m.group(2)!.trim();
        return 'Math.floor(Math.random() * (($b) - ($a) + 1)) + ($a)';
      },
    );
    // 1-arg : simples renames
    res = res.replaceAllMapped(
      RegExp(r'\blong\s*\(([^)]+)\)', caseSensitive: false),
      (m) => '(${m.group(1)}).length',
    );
    res = res.replaceAllMapped(
      RegExp(r'\bmaj\s*\(([^)]+)\)', caseSensitive: false),
      (m) => '(${m.group(1)}).toUpperCase()',
    );
    res = res.replaceAllMapped(
      RegExp(r'\bminus\s*\(([^)]+)\)', caseSensitive: false),
      (m) => '(${m.group(1)}).toLowerCase()',
    );
    res = res.replaceAllMapped(
      RegExp(r'\bracine\s*\(([^)]+)\)', caseSensitive: false),
      (m) => 'Math.sqrt(${m.group(1)})',
    );
    res = res.replaceAllMapped(
      RegExp(r'\barrondi\s*\(([^)]+)\)', caseSensitive: false),
      (m) => 'Math.round(${m.group(1)})',
    );
    res = res.replaceAllMapped(
      RegExp(r'\btronque\s*\(([^)]+)\)', caseSensitive: false),
      (m) => 'Math.trunc(${m.group(1)})',
    );
    res = res.replaceAllMapped(
      RegExp(r'\ben_entier\s*\(([^)]+)\)', caseSensitive: false),
      (m) => 'parseInt(${m.group(1)})',
    );
    res = res.replaceAllMapped(
      RegExp(r'\ben_reel\s*\(([^)]+)\)', caseSensitive: false),
      (m) => 'parseFloat(${m.group(1)})',
    );
    res = res.replaceAllMapped(
      RegExp(r'\ben_chaine\s*\(([^)]+)\)', caseSensitive: false),
      (m) => 'String(${m.group(1)})',
    );
    res = res.replaceAllMapped(
      RegExp(r'\btypevar\s*\(([^)]+)\)', caseSensitive: false),
      (m) => 'typeof (${m.group(1)})',
    );
    res = res.replaceAllMapped(
      RegExp(r'\best_numerique\s*\(([^)]+)\)', caseSensitive: false),
      (m) => '!isNaN(${m.group(1)})',
    );
    return res;
  }
}
