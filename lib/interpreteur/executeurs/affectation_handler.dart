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

    dynamic courant = await evaluateur.evaluer(dots[0]);

    // On descend dans la structure jusqu'à l'avant-dernier élément
    // On descend dans la structure jusqu'à l'avant-dernier élément
    for (int i = 1; i < dots.length - 1; i++) {
      if (courant is PseudoStructureInstance) {
        String part = dots[i].trim();
        final matchTab = GestionnaireTableaux.regAcces.firstMatch(part);

        if (matchTab != null) {
          final nomChamp = matchTab.group(1)!;
          final indicesBruts = matchTab.group(2)!;
          dynamic tab = courant.lire(nomChamp);
          if (tab is! PseudoTableau)
            throw Exception("'$nomChamp' n'est pas un tableau.");
          final indices = <int>[];
          final indexParts = InterpreteurUtils.splitArguments(indicesBruts);
          for (final p in indexParts) {
            indices.add(await evaluateur.evaluer(p));
          }
          courant = tab.lire(indices);
        } else {
          courant = courant.lire(dots[i]);
        }
      } else {
        throw Exception(
          "Le chemin '$chemin' est invalide car '${dots[i - 1]}' n'est pas une structure.",
        );
      }
    }

    final dernierBrut = dots.last.trim();

    // Cas spécial : le dernier segment peut être un accès tableau (ex: s.tab[i])
    if (GestionnaireTableaux.regAcces.hasMatch(dernierBrut)) {
      final match = GestionnaireTableaux.regAcces.firstMatch(dernierBrut)!;
      final nomChamp = match.group(1)!;
      final indicesBruts = match.group(2)!;

      dynamic tab;
      if (courant is PseudoStructureInstance) {
        tab = courant.lire(nomChamp);
      } else {
        // Cas racine si dots.length == 1 (mais splitChemin a au moins 1 elem)
        // Cette branche ne devrait pas être atteinte si le chemin contient un '.'
        // et que le premier élément n'est pas une structure.
        // Si dots.length == 1, alors `courant` est la variable racine, et `_affecterStructure`
        // n'aurait pas dû être appelée car `variBrute` ne contiendrait pas de '.'.
        // Donc, `courant` sera toujours une PseudoStructureInstance ici.
        throw Exception(
          "Le chemin '$chemin' est invalide. '$dots[0]' n'est pas une structure.",
        );
      }

      if (tab is! PseudoTableau)
        throw Exception("'$nomChamp' n'est pas un tableau.");

      final parts = InterpreteurUtils.splitArguments(indicesBruts);
      final indices = <int>[];
      for (final p in parts) {
        final idx = await evaluateur.evaluer(p);
        if (idx is! int) throw Exception("L'indice doit être un entier.");
        indices.add(idx);
      }
      tab.assigner(indices, valeur);
    } else {
      // Affectation simple à un champ de structure
      if (courant is PseudoStructureInstance) {
        courant.assigner(dernierBrut, valeur);
      } else {
        throw Exception("Impossible d'assigner au champ '$dernierBrut'.");
      }
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
