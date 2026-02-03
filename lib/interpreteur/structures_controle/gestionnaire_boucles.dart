import 'package:pseudo_code/interpreteur/executeur.dart';
import 'package:pseudo_code/interpreteur/environnement.dart';
import 'package:pseudo_code/interpreteur/navigateur_blocs.dart';

/// Gestionnaire des structures de boucles (Pour/TantQue/Répéter)
class GestionnaireBoucles {
  // Expressions régulières pour détecter les boucles
  static final RegExp pourReg = RegExp(
    r'^pour\\s+([a-zA-Z_]\\w*)\\s+de\\s+(.+)\\s+[aà]\\s+(.+)\\s+faire$',
    caseSensitive: false,
  );
  static final RegExp tantqueReg = RegExp(
    r'^tantque\\s+(.+)\\s+faire$',
    caseSensitive: false,
  );
  static final RegExp jusquaReg = RegExp(
    r'^jusqua\\s+(.*)$',
    caseSensitive: false,
  );

  /// Vérifie si une ligne est un début de boucle
  static bool estDebutBoucle(String ligne) {
    ligne = ligne.trim().toLowerCase();
    return pourReg.hasMatch(ligne) ||
        tantqueReg.hasMatch(ligne) ||
        ligne == 'repeter';
  }

  /// Vérifie si une ligne est une fin de boucle
  static bool estFinBoucle(String ligne) {
    ligne = ligne.trim().toLowerCase();
    return ligne == 'finpour' ||
        ligne == 'fpour' ||
        ligne == 'fintantque' ||
        jusquaReg.hasMatch(ligne);
  }

  /// Traite une boucle Pour
  static Future<int> traiterPour(
    List<String> lignes,
    int indexCourant,
    Executeur exec,
    Environnement env,
    List<String> pileBlocs,
  ) async {
    final ligne = lignes[indexCourant].trim();
    final pourMatch = pourReg.firstMatch(ligne);

    if (pourMatch != null) {
      pileBlocs.add('pour');

      final varName = pourMatch.group(1)!;
      final startVal = await exec.evaluer(pourMatch.group(2)!);
      final endVal = await exec.evaluer(pourMatch.group(3)!);

      // Initialiser la variable si nécessaire
      final currentVal = env.lire(varName);
      if (currentVal is! num || (currentVal < startVal)) {
        env.assigner(varName, startVal);
      }

      // Vérifier si on doit sauter la boucle
      if ((env.lire(varName) as num) > endVal) {
        final newIndex = NavigateurBlocs.trouverFinBlocCorrespondant(
          lignes,
          indexCourant,
          'pour',
          ['fpour', 'finpour'],
        );
        pileBlocs.removeLast();
        return newIndex;
      }
    }

    return indexCourant;
  }

  /// Traite une FinPour ou FPour
  static int traiterFinPour(
    List<String> lignes,
    int indexCourant,
    int indexInstruction,
    Environnement env,
    List<String> pileBlocs,
  ) {
    final ligne = lignes[indexCourant].trim().toLowerCase();

    if (pileBlocs.isNotEmpty && pileBlocs.last == 'pour') {
      // Trouver le début de la boucle Pour
      final pourLineIdx = NavigateurBlocs.trouverDebutBlocCorrespondant(
        lignes,
        indexInstruction,
        ligne,
        ['pour'],
      );

      // Incrémenter la variable de boucle
      final m = pourReg.firstMatch(lignes[pourLineIdx].trim());
      if (m != null) {
        final varName = m.group(1)!;
        env.assigner(varName, (env.lire(varName) as num) + 1);
      }

      pileBlocs.removeLast();
      return pourLineIdx;
    }

    return indexCourant;
  }

  /// Traite une boucle TantQue
  static Future<int> traiterTantQue(
    List<String> lignes,
    int indexCourant,
    Executeur exec,
    List<String> pileBlocs,
  ) async {
    final ligne = lignes[indexCourant].trim();
    final tantqueMatch = tantqueReg.firstMatch(ligne);

    if (tantqueMatch != null) {
      pileBlocs.add('tantque');

      final condition = tantqueMatch.group(1)!;

      // Si la condition est fausse, sauter jusqu'à FinTantQue
      if (!(await exec.evaluerBooleen(condition))) {
        final newIndex = NavigateurBlocs.trouverFinBlocCorrespondant(
          lignes,
          indexCourant,
          'tantque',
          ['fintantque'],
        );
        pileBlocs.removeLast();
        return newIndex;
      }
    }

    return indexCourant;
  }

  /// Traite une FinTantQue
  static int traiterFinTantQue(
    List<String> lignes,
    int indexInstruction,
    List<String> pileBlocs,
  ) {
    if (pileBlocs.isNotEmpty && pileBlocs.last == 'tantque') {
      // Retourner au début de la boucle TantQue
      final newIndex = NavigateurBlocs.trouverDebutBlocCorrespondant(
        lignes,
        indexInstruction,
        'fintantque',
        ['tantque'],
      );
      pileBlocs.removeLast();
      return newIndex;
    }

    return indexInstruction;
  }

  /// Traite un Répéter
  static void traiterRepeter(List<String> pileBlocs) {
    pileBlocs.add('repeter');
  }

  /// Traite un Jusqua
  static Future<int> traiterJusqua(
    List<String> lignes,
    int indexCourant,
    int indexInstruction,
    Executeur exec,
    List<String> pileBlocs,
  ) async {
    final ligne = lignes[indexCourant].trim();
    final jusquaMatch = jusquaReg.firstMatch(ligne);

    if (jusquaMatch != null &&
        pileBlocs.isNotEmpty &&
        pileBlocs.last == 'repeter') {
      final condition = jusquaMatch.group(1)!;

      // Si la condition est fausse, retourner au début de Répéter
      if (!(await exec.evaluerBooleen(condition))) {
        final newIndex = NavigateurBlocs.trouverDebutBlocCorrespondant(
          lignes,
          indexInstruction,
          'jusqua',
          ['repeter'],
        );
        return newIndex;
      }

      pileBlocs.removeLast();
    }

    return indexCourant;
  }

  /// Détecte le type de ligne de boucle
  static String? detecterTypeBoucle(String ligne) {
    ligne = ligne.trim();

    if (pourReg.hasMatch(ligne)) return 'pour';
    if (ligne.toLowerCase() == 'finpour' || ligne.toLowerCase() == 'fpour')
      return 'finpour';
    if (tantqueReg.hasMatch(ligne)) return 'tantque';
    if (ligne.toLowerCase() == 'fintantque') return 'fintantque';
    if (ligne.toLowerCase() == 'repeter') return 'repeter';
    if (jusquaReg.hasMatch(ligne)) return 'jusqua';

    return null;
  }
}
