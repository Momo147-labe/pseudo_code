import 'package:pseudo_code/interpreteur/environnement.dart';
import 'package:pseudo_code/interpreteur/evaluateur_expression.dart';
import 'package:pseudo_code/interpreteur/blocs/tableaux.dart';
import 'package:pseudo_code/interpreteur/blocs/structures.dart';
import 'package:pseudo_code/interpreteur/utils.dart';

/// Gestionnaire des affectations (variable <- valeur)
class AffectationHandler {
  final Environnement env;
  final EvaluateurExpression evaluateur;

  AffectationHandler({required this.env, required this.evaluateur});

  /// Gère les affectations de tableaux (ex: tab[i] <- valeur)
  Future<void> executerAffectationTableau(String ligne) async {
    await GestionnaireTableaux.traiterAffectationAsync(
      ligne,
      env,
      evaluateur.evaluer,
    );
  }

  /// Gère les affectations simples et de structures
  Future<void> executerAffectation(String ligne) async {
    final parts = ligne.split('<-');
    if (parts.length != 2) {
      throw Exception("Syntaxe d'affectation invalide: $ligne");
    }

    final variBrute = parts[0].trim();
    final expression = parts[1].trim();
    final valeur = await evaluateur.evaluer(expression);

    // Affectation à un champ de structure (ex: e.nom <- "valeur")
    if (variBrute.contains('.')) {
      await _affecterStructure(variBrute, valeur);
    } else {
      // Affectation simple
      env.assigner(variBrute, valeur);
    }
  }

  /// Affecte une valeur à un champ de structure (peut être imbriqué)
  Future<void> _affecterStructure(String chemin, dynamic valeur) async {
    final dots = InterpreteurUtils.splitChemin(chemin);
    final prefixe = dots.sublist(0, dots.length - 1).join('.');
    final champ = dots.last.trim();

    final parent = await evaluateur.evaluer(prefixe);

    // Assigner au dernier champ
    if (parent is PseudoStructureInstance) {
      parent.assigner(champ, valeur);
    } else {
      throw Exception(
        "Impossible d'assigner au champ '$champ' sur '$prefixe'.",
      );
    }
  }

  /// Vérifie si une ligne est une affectation
  bool estAffectation(String ligne) {
    return ligne.contains('<-');
  }

  /// Vérifie si une ligne est une affectation de tableau
  bool estAffectationTableau(String ligne) {
    if (!GestionnaireTableaux.estAffectation(ligne)) return false;
    final gauche = ligne.split('<-')[0].trim();
    return gauche.endsWith(']');
  }
}
