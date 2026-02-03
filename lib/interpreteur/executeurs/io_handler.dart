import 'package:pseudo_code/interpreteur/environnement.dart';
import 'package:pseudo_code/interpreteur/evaluateur_expression.dart';
import 'package:pseudo_code/interpreteur/blocs/structures.dart';
import 'package:pseudo_code/interpreteur/blocs/tableaux.dart';
import 'package:pseudo_code/interpreteur/utils.dart';

/// Gestionnaire des opérations d'entrée/sortie (Afficher, Lire)
class IOHandler {
  final Environnement env;
  final EvaluateurExpression evaluateur;
  final Future<String> Function() onInput;

  IOHandler({
    required this.env,
    required this.evaluateur,
    required this.onInput,
  });

  /// Extrait les arguments d'une liste séparée par des virgules
  List<String> _extraireArguments(String argsBruts) {
    return InterpreteurUtils.splitArguments(argsBruts);
  }

  /// Gère la commande Afficher()
  Future<String> executerAfficher(String ligne) async {
    final match = RegExp(
      r'afficher\s*\((.*)\)',
      caseSensitive: false,
    ).firstMatch(ligne);

    if (match != null) {
      final args = _extraireArguments(match.group(1)!);
      String resultat = "";

      for (final arg in args) {
        final a = arg.trim();
        if (a.startsWith('"') && a.endsWith('"')) {
          resultat += a.substring(1, a.length - 1);
        } else {
          resultat += (await evaluateur.evaluer(a)).toString();
        }
      }
      return resultat;
    }
    return "";
  }

  /// Gère la commande Afficher_Table()
  Future<String> executerAfficherTable(String ligne) async {
    final match = RegExp(
      r'afficher_table\s*\((.*)\)',
      caseSensitive: false,
    ).firstMatch(ligne);

    if (match != null) {
      final arg = match.group(1)!.trim();
      final valeur = await evaluateur.evaluer(arg);
      return valeur.toString();
    }
    return "";
  }

  /// Gère la commande Effacer
  String executerEffacer(String ligne) {
    return "__CLEAR__";
  }

  /// Gère la commande Afficher2D()
  Future<String> executerAfficher2D(String ligne) async {
    final match = RegExp(
      r'afficher2D\s*\((.*)\)',
      caseSensitive: false,
    ).firstMatch(ligne);

    if (match != null) {
      final arg = match.group(1)!.trim();
      final valeur = await evaluateur.evaluer(arg);
      if (valeur is PseudoTableau) {
        return valeur.formatGrid();
      }
      return valeur.toString();
    }
    return "";
  }

  /// Gère la commande AfficherTabStructure()
  Future<String> executerAfficherTabStructure(String ligne) async {
    final match = RegExp(
      r'afficherTabStructure\s*\((.*)\)',
      caseSensitive: false,
    ).firstMatch(ligne);

    if (match != null) {
      final arg = match.group(1)!.trim();
      final valeur = await evaluateur.evaluer(arg);
      if (valeur is PseudoTableau) {
        return valeur.formatStructureGrid();
      }
      return valeur.toString();
    }
    return "";
  }

  /// Gère la commande Lire()
  Future<void> executerLire(String ligne) async {
    final match = RegExp(
      r'lire\s*\((.*)\)',
      caseSensitive: false,
    ).firstMatch(ligne);
    if (match == null) return;

    final variableBrute = match.group(1)!.trim();
    final saisie = await onInput();
    dynamic valeur;

    final dots = InterpreteurUtils.splitChemin(variableBrute);

    if (dots.length > 1) {
      // Accès à une structure (éventuellement dans un tableau : E[i].nom)
      final prefixe = dots.sublist(0, dots.length - 1).join('.');
      final champ = dots.last.trim();

      // On évalue le parent (qui peut être E[i] ou juste e)
      final parent = await evaluateur.evaluer(prefixe);

      if (parent is PseudoStructureInstance) {
        final def = parent.definition;
        final champDef = def.champs.firstWhere(
          (c) => c.nom == champ,
          orElse: () => throw Exception("Champ '$champ' inconnu."),
        );
        final typeAttendu = champDef.type;

        valeur = _convertirSaisie(saisie, typeAttendu);
        parent.assigner(champ, valeur);
      } else {
        throw Exception(
          "Impossible d'accéder au champ '$champ' sur '$prefixe'.",
        );
      }
    } else if (GestionnaireTableaux.regAcces.hasMatch(variableBrute)) {
      // Accès simple à un tableau (ex: lire(T[i]))
      final tabMatch = GestionnaireTableaux.regAcces.firstMatch(variableBrute)!;
      final nomTab = tabMatch.group(1)!;
      final indicesBruts = tabMatch.group(2)!;

      final tab = env.lire(nomTab);
      if (tab is! PseudoTableau) {
        throw Exception("'$nomTab' n'est pas un tableau.");
      }

      final parts = _extraireArguments(indicesBruts);
      final indices = <int>[];
      for (final p in parts) {
        final idx = await evaluateur.evaluer(p);
        if (idx is! int) {
          throw Exception("L'indice de tableau doit être un entier.");
        }
        indices.add(idx);
      }

      valeur = _convertirSaisie(saisie, tab.typeElement);
      tab.assigner(indices, valeur);
    } else {
      // Lecture variable simple
      final typeAttendu = env.getType(variableBrute);
      valeur = _convertirSaisie(saisie, typeAttendu);
      env.assigner(variableBrute, valeur);
    }
  }

  /// Convertit une saisie utilisateur selon le type attendu
  dynamic _convertirSaisie(String saisie, String? typeAttendu) {
    if (typeAttendu == null) return saisie;

    if (typeAttendu == 'entier') {
      return int.tryParse(saisie) ??
          (throw Exception("'$saisie' n'est pas un entier valide."));
    } else if (typeAttendu == 'réel' || typeAttendu == 'reel') {
      return double.tryParse(saisie) ??
          int.tryParse(saisie)?.toDouble() ??
          (throw Exception("'$saisie' n'est pas un nombre réel."));
    } else if (typeAttendu == 'booleen') {
      final s = saisie.toLowerCase();
      if (s == 'vrai') return true;
      if (s == 'faux') return false;
      throw Exception("'$saisie' n'est pas un booléen valide.");
    } else if (typeAttendu == 'chaine') {
      return saisie;
    } else {
      return saisie;
    }
  }
}
