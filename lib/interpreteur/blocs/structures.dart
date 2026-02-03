class ChampStructure {
  final String nom;
  final String type;
  ChampStructure({required this.nom, required this.type});
}

class PseudoStructureDefinition {
  final String nom;
  final List<ChampStructure> champs;

  PseudoStructureDefinition({required this.nom, required this.champs});

  PseudoStructureInstance instancier() {
    final instance = PseudoStructureInstance(definition: this);
    for (final champ in champs) {
      instance.valeurs[champ.nom] = _valeurParDefaut(champ.type);
    }
    return instance;
  }

  dynamic _valeurParDefaut(String type) {
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
        return null; // Pourrait être une sous-structure plus tard
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
    // TODO: On pourrait ajouter une validation de type ici aussi
    valeurs[champ] = valeur;
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
}
