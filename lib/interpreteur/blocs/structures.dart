import 'package:pseudo_code/interpreteur/blocs/tableaux.dart';

class ChampStructure {
  final String nom;
  final String type;
  ChampStructure({required this.nom, required this.type});
}

class PseudoStructureDefinition {
  final String nom;
  final List<ChampStructure> champs;

  PseudoStructureDefinition({required this.nom, required this.champs});

  PseudoStructureInstance instancier([
    PseudoStructureDefinition? Function(String)? resolver,
  ]) {
    final instance = PseudoStructureInstance(definition: this);
    for (final champ in champs) {
      instance.valeurs[champ.nom] = _valeurParDefaut(champ.type, resolver);
    }
    return instance;
  }

  dynamic _valeurParDefaut(
    String type, [
    PseudoStructureDefinition? Function(String)? resolver,
  ]) {
    switch (type.toLowerCase()) {
      case 'entier':
        return 0;
      case 'réel':
      case 'reel':
        return 0.0;
      case 'chaine':
        return "";
      case 'booleen':
        return false;
      default:
        // Tenter de résoudre comme une sous-structure
        if (resolver != null) {
          final subDef = resolver(type);
          if (subDef != null) return subDef.instancier(resolver);
        }
        return null;
    }
  }
}

class PseudoStructureInstance {
  final PseudoStructureDefinition definition;
  final Map<String, dynamic> valeurs = {};

  PseudoStructureInstance({required this.definition});

  void assigner(String champ, dynamic valeur) {
    if (!valeurs.containsKey(champ)) {
      throw Exception(
        "Le champ '$champ' n'existe pas dans la structure '${definition.nom}'.",
      );
    }
    final champDef = definition.champs.firstWhere(
      (c) => c.nom == champ,
      orElse: () => throw Exception("Champ '$champ' inconnu."),
    );
    _validerTypeChamp(champ, valeur, champDef.type);
    valeurs[champ] = valeur;
  }

  void _validerTypeChamp(String nom, dynamic valeur, String type) {
    final t = type.toLowerCase();
    if (t == 'entier' && valeur is! int && valeur is! BigInt) {
      throw Exception(
        "Erreur de type: Le champ '$nom' attend un entier, reçu '${valeur.runtimeType}'.",
      );
    } else if ((t == 'réel' || t == 'reel') &&
        valeur is! double &&
        valeur is! int) {
      throw Exception(
        "Erreur de type: Le champ '$nom' attend un réel, reçu '${valeur.runtimeType}'.",
      );
    } else if (t == 'chaine' && valeur is! String) {
      throw Exception(
        "Erreur de type: Le champ '$nom' attend une chaîne, reçu '${valeur.runtimeType}'.",
      );
    } else if (t == 'booleen' && valeur is! bool) {
      throw Exception(
        "Erreur de type: Le champ '$nom' attend un booléen, reçu '${valeur.runtimeType}'.",
      );
    }
    // Pour les sous-structures et tableaux, on laisse passer sans vérification stricte
  }

  dynamic lire(String champ) {
    if (!valeurs.containsKey(champ)) {
      throw Exception(
        "Le champ '$champ' n'existe pas dans la structure '${definition.nom}'.",
      );
    }
    return valeurs[champ];
  }

  @override
  String toString() {
    return "{ ${valeurs.entries.map((e) => "${e.key}: ${e.value}").join(", ")} }";
  }

  PseudoStructureInstance clone() {
    final instance = PseudoStructureInstance(definition: definition);
    for (final entry in valeurs.entries) {
      if (entry.value is PseudoTableau) {
        instance.valeurs[entry.key] = (entry.value as PseudoTableau).clone();
      } else if (entry.value is PseudoStructureInstance) {
        instance.valeurs[entry.key] = (entry.value as PseudoStructureInstance)
            .clone();
      } else {
        instance.valeurs[entry.key] = entry.value;
      }
    }
    return instance;
  }
}
