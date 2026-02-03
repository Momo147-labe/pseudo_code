import 'analyse_lexicale.dart';

class AnalyseSyntaxique {
  static void verifier(List<Token> tokens) {
    bool debutTrouve = false;
    bool finTrouve = false;

    for (final token in tokens) {
      if (token.valeur == 'Début') debutTrouve = true;
      if (token.valeur == 'Fin') finTrouve = true;
    }

    if (!debutTrouve) {
      throw Exception("Erreur syntaxique : 'Début' manquant");
    }
    if (!finTrouve) {
      throw Exception("Erreur syntaxique : 'Fin' manquant");
    }
  }
}
