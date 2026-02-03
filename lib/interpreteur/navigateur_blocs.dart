import 'executeur.dart';

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
      if (startReg.hasMatch(l))
        niveau++;
      else if (keywordsFin.contains(l)) {
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
      if (l == keywordFin)
        niveau++;
      else {
        bool estUnDebut = false;
        for (final kd in keywordsDebut) if (l.startsWith(kd)) estUnDebut = true;
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
    for (int j = index; j < lignes.length; j++) {
      String l = lignes[j].trim();
      if (l.isEmpty || l.startsWith('//')) continue;
      if (siReg.hasMatch(l))
        niveau++;
      else if (l.toLowerCase() == 'finsi') {
        if (niveau == 0) return j;
        niveau--;
      } else if (niveau == 0) {
        final mSi = sinonSiReg.firstMatch(l);
        if (mSi != null) {
          if (await exec.evaluerBooleen(mSi.group(1)!)) return j + 1;
        } else if (l.toLowerCase() == 'sinon')
          return j + 1;
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
    final casReg = RegExp(r'^cas\s*(.*?)\s*:?$', caseSensitive: false);
    final sinonCasReg = RegExp(
      r'^(?:sinon|defaut|autre)\s*:?$',
      caseSensitive: false,
    );
    for (int j = index; j < lignes.length; j++) {
      String l = lignes[j].trim();
      if (l.isEmpty || l.startsWith('//')) continue;
      if (selonReg.hasMatch(l))
        niveau++;
      else if (l.toLowerCase() == 'finselon') {
        if (niveau == 0) return j;
        niveau--;
      } else if (niveau == 0) {
        final mCas = casReg.firstMatch(l);
        if (mCas != null) {
          if (await exec.evaluer(mCas.group(1)!) == valCible) return j + 1;
        } else if (sinonCasReg.hasMatch(l))
          return j + 1;
      }
    }
    throw Exception("Structure 'selon' non fermée.");
  }
}
