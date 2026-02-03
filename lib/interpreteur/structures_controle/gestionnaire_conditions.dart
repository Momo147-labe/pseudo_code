import 'package:pseudo_code/interpreteur/executeur.dart';
import 'package:pseudo_code/interpreteur/navigateur_blocs.dart';

/// Gestionnaire des structures conditionnelles (Si/Sinon/Selon)
class GestionnaireConditions {
  // Expressions régulières pour détecter les conditions
  static final RegExp siReg = RegExp(
    r'^si\\s+(.+)\\s+alors$',
    caseSensitive: false,
  );
  static final RegExp sinonSiReg = RegExp(
    r'^sinon\\s+si\\s+(.+)\\s+alors$',
    caseSensitive: false,
  );
  static final RegExp selonReg = RegExp(
    r'^selon\\s+(.+)\\s+faire$',
    caseSensitive: false,
  );
  static final RegExp casReg = RegExp(r'^cas\s*.*:?$', caseSensitive: false);
  static final RegExp autreReg = RegExp(
    r'^(?:sinon|autre|defaut)\s*:?$',
    caseSensitive: false,
  );

  /// Vérifie si une ligne est un début de condition
  static bool estDebutCondition(String ligne) {
    ligne = ligne.trim().toLowerCase();
    return siReg.hasMatch(ligne) || selonReg.hasMatch(ligne);
  }

  /// Vérifie si une ligne est une fin de condition
  static bool estFinCondition(String ligne) {
    ligne = ligne.trim().toLowerCase();
    return ligne == 'finsi' || ligne == 'finselon';
  }

  /// Traite un bloc Si/Sinon/SinonSi
  /// Retourne le nouvel index après traitement
  static Future<int> traiterSi(
    List<String> lignes,
    int indexCourant,
    Executeur exec,
    List<String> pileBlocs,
  ) async {
    final ligne = lignes[indexCourant].trim();
    final siMatch = siReg.firstMatch(ligne);

    if (siMatch != null) {
      pileBlocs.add('si');
      final condition = siMatch.group(1)!;

      // Si la condition est fausse, sauter vers la branche suivante (sinon/sinonsi)
      if (!(await exec.evaluerBooleen(condition))) {
        return await NavigateurBlocs.sauterVersBrancheSuivante(
          lignes,
          indexCourant,
          exec,
        );
      }
    }

    return indexCourant;
  }

  /// Traite un SinonSi ou Sinon
  static int traiterSinonOuSinonSi(
    List<String> lignes,
    int indexCourant,
    List<String> pileBlocs,
  ) {
    // On a déjà exécuté une branche du Si, donc on saute jusqu'à FinSi
    final newIndex = NavigateurBlocs.trouverFinBlocCorrespondant(
      lignes,
      indexCourant,
      'si',
      ['finsi'],
    );

    if (pileBlocs.isNotEmpty && pileBlocs.last == 'si') {
      pileBlocs.removeLast();
    }

    return newIndex;
  }

  /// Traite une FinSi
  static void traiterFinSi(List<String> pileBlocs) {
    if (pileBlocs.isNotEmpty && pileBlocs.last == 'si') {
      pileBlocs.removeLast();
    }
  }

  /// Traite un bloc Selon/Cas
  static Future<int> traiterSelon(
    List<String> lignes,
    int indexCourant,
    Executeur exec,
    List<String> pileBlocs,
  ) async {
    final ligne = lignes[indexCourant].trim();
    final selonMatch = selonReg.firstMatch(ligne);

    if (selonMatch != null) {
      pileBlocs.add('selon');
      final expression = selonMatch.group(1)!;
      final valCible = await exec.evaluer(expression);

      // Sauter vers le cas correspondant
      return await NavigateurBlocs.sauterVersCas(
        lignes,
        indexCourant,
        valCible,
        exec,
      );
    }

    return indexCourant;
  }

  /// Traite un Cas ou Autre dans un Selon
  static int traiterCasOuAutre(
    List<String> lignes,
    int indexCourant,
    List<String> pileBlocs,
  ) {
    // On a déjà exécuté un cas, donc on saute jusqu'à FinSelon
    final newIndex = NavigateurBlocs.trouverFinBlocCorrespondant(
      lignes,
      indexCourant,
      'selon',
      ['finselon'],
    );

    if (pileBlocs.isNotEmpty && pileBlocs.last == 'selon') {
      pileBlocs.removeLast();
    }

    return newIndex;
  }

  /// Traite une FinSelon
  static void traiterFinSelon(List<String> pileBlocs) {
    if (pileBlocs.isNotEmpty && pileBlocs.last == 'selon') {
      pileBlocs.removeLast();
    }
  }

  /// Détecte le type de ligne conditionnelle
  static String? detecterTypeCondition(String ligne) {
    ligne = ligne.trim();

    if (siReg.hasMatch(ligne)) return 'si';
    if (sinonSiReg.hasMatch(ligne)) return 'sinonsi';
    if (ligne.toLowerCase() == 'sinon') return 'sinon';
    if (ligne.toLowerCase() == 'finsi') return 'finsi';
    if (selonReg.hasMatch(ligne)) return 'selon';
    if (casReg.hasMatch(ligne)) return 'cas';
    if (autreReg.hasMatch(ligne)) return 'autre';
    if (ligne.toLowerCase() == 'finselon') return 'finselon';

    return null;
  }
}
