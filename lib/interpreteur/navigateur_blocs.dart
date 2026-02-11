import 'executeur.dart';
import 'utils.dart';

class NavigateurBlocs {
  static int trouverFinBlocCorrespondant(
    List<String> lignes,
    int index,
    String typeBloc,
    List<String> keywordsFin,
  ) {
    int niveau = 0;
    final startReg = RegExp("^($typeBloc)\\b", caseSensitive: false);
    for (int j = index; j < lignes.length; j++) {
      String l = lignes[j].trim().toLowerCase();
      if (l.isEmpty || l.startsWith('//')) continue;

      // Nettoyage : retirer points-virgules et commentaires en fin de ligne
      l = l.split(';')[0].split('//')[0].trim();

      if (startReg.hasMatch(l)) {
        niveau++;
      } else if (keywordsFin.contains(l)) {
        if (niveau == 0) return j + 1;
        niveau--;
      }
    }
    throw Exception(
      "Structure '$typeBloc' non fermée. Attendu l'un des mots-clés : $keywordsFin",
    );
  }

  static int trouverDebutBlocCorrespondant(
    List<String> lignes,
    int index,
    String keywordFin,
    List<String> keywordsDebut,
  ) {
    int niveau = 0;
    for (int j = index - 1; j >= 0; j--) {
      String l = lignes[j].trim().toLowerCase();
      if (l.isEmpty || l.startsWith('//')) continue;

      // Nettoyage
      l = l.split(';')[0].split('//')[0].trim();

      if (l == keywordFin) {
        niveau++;
      } else {
        bool estUnDebut = false;
        for (final kd in keywordsDebut) {
          if (l.startsWith(kd)) estUnDebut = true;
        }
        if (estUnDebut) {
          if (niveau == 0) return j;
          niveau--;
        }
      }
    }
    return 0;
  }

  static Future<int> sauterVersBrancheSuivante(
    List<String> lignes,
    int index,
    Executeur exec,
  ) async {
    int niveau = 0;
    final siReg = RegExp(r'^si\s+(.*)\s+alors$', caseSensitive: false);
    final sinonSiReg = RegExp(
      r'^sinon\s+si\s+(.*)\s+alors$',
      caseSensitive: false,
    );
    final blockStarts = [
      'selon',
      'pour',
      'tantque',
      'repeter',
      'fonction',
      'procedure',
    ];
    final blockEnds = [
      'finselon',
      'finpour',
      'fpour',
      'fintantque',
      'jusqua',
      'finfonction',
      'finprocedure',
    ];

    for (int j = index; j < lignes.length; j++) {
      String l = lignes[j].trim();
      if (l.isEmpty || l.startsWith('//')) continue;
      String lower = l.toLowerCase();

      if (siReg.hasMatch(l)) {
        niveau++;
      } else if (lower == 'finsi') {
        if (niveau == 0) return j;
        niveau--;
      } else if (niveau == 0) {
        final mSi = sinonSiReg.firstMatch(l);
        if (mSi != null) {
          if (await exec.evaluerBooleen(mSi.group(1)!)) return j + 1;
        } else if (lower == 'sinon' || lower == 'sinon:') {
          return j + 1;
        }
      } else {
        // Gérer les autres types de blocs
        bool matched = false;
        for (var start in blockStarts) {
          if (RegExp("^$start\\b", caseSensitive: false).hasMatch(lower)) {
            niveau++;
            matched = true;
            break;
          }
        }
        if (!matched) {
          for (var end in blockEnds) {
            if (RegExp("^$end\\b", caseSensitive: false).hasMatch(lower)) {
              niveau--;
              break;
            }
          }
        }
      }
    }
    throw Exception("Structure 'si' non fermée.");
  }

  static Future<int> sauterVersCas(
    List<String> lignes,
    int index,
    dynamic valCible,
    Executeur exec,
  ) async {
    int niveau = 0;
    final selonReg = RegExp(r'^selon\s+(.*)\s+faire$', caseSensitive: false);
    final casReg = RegExp(
      r'^cas\s+([^:]*?)\s*(?::\s*)?$',
      caseSensitive: false,
    );
    final sinonCasReg = RegExp(
      r'^(?:sinon|defaut|autre)\s*(?::\s*)?$',
      caseSensitive: false,
    );
    final blockStarts = [
      'si',
      'pour',
      'tantque',
      'repeter',
      'fonction',
      'procedure',
      'selon',
    ];
    final blockEnds = [
      'finsi',
      'finpour',
      'fpour',
      'fintantque',
      'jusqua',
      'finfonction',
      'finprocedure',
      'finselon',
    ];

    for (int j = index; j < lignes.length; j++) {
      String lRaw = lignes[j].trim();
      if (lRaw.isEmpty || lRaw.startsWith('//')) continue;

      // Nettoyage pour les comparaisons de structure
      String l = lRaw.split('//')[0].trim();
      String lower = l.toLowerCase();

      if (selonReg.hasMatch(l)) {
        niveau++;
      } else if (lower == 'finselon') {
        if (niveau == 0) return j;
        niveau--;
      } else if (niveau == 0) {
        // Recherche des CAS
        final mCas = casReg.firstMatch(l);
        if (mCas != null) {
          final exprBrute = mCas.group(1)!;
          final parts = InterpreteurUtils.splitArguments(
            exprBrute,
          ); // Utiliser le splitter robuste
          for (final part in parts) {
            final p = part.trim();
            if (p.contains('..')) {
              final bounds = p.split('..');
              if (bounds.length == 2) {
                final vMin = await exec.evaluer(bounds[0].trim());
                final vMax = await exec.evaluer(bounds[1].trim());
                if (valCible is num && vMin is num && vMax is num) {
                  final vc = valCible.toDouble();
                  final min = vMin.toDouble();
                  final max = vMax.toDouble();
                  if (vc >= min && vc <= max) return j + 1;
                }
              }
            } else {
              final valCas = await exec.evaluer(p);
              // Comparaison tolérante pour les chaînes ?
              // Pour l'instant on garde l'égalité stricte mais on peut imaginer un .toLowerCase() si besoin
              if (valCas == valCible) return j + 1;
            }
          }
        } else if (sinonCasReg.hasMatch(l)) {
          return j + 1;
        } else {
          // Si on tombe sur un début de bloc (SI, POUR, etc.) on l'incrémente
          for (var start in blockStarts) {
            if (RegExp("^$start\\b", caseSensitive: false).hasMatch(lower)) {
              niveau++;
              break;
            }
          }
        }
      } else {
        // Dans un sous-bloc
        bool matched = false;
        for (var start in blockStarts) {
          if (RegExp("^$start\\b", caseSensitive: false).hasMatch(lower)) {
            niveau++;
            matched = true;
            break;
          }
        }
        if (!matched) {
          for (var end in blockEnds) {
            if (RegExp("^$end\\b", caseSensitive: false).hasMatch(lower)) {
              niveau--;
              break;
            }
          }
        }
      }
    }
    throw Exception("Structure 'selon' non fermée.");
  }
}
