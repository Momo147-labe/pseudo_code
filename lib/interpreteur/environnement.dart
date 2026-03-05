import 'blocs/tableaux.dart';
import 'blocs/fonctions.dart';
import 'blocs/structures.dart';

class Environnement {
  final Environnement? parent;
  final Map<String, dynamic> variables = {};
  final Map<String, String> types = {};
  final Map<String, String> noms =
      {}; // lower -> nom original (pour préserver la casse à l'affichage)
  final Map<String, dynamic> constantes = {};
  final Map<String, String> nomsConstantes = {}; // lower -> nom original
  final Map<String, PseudoFonction> fonctions = {};
  final Map<String, PseudoProcedure> procedures = {};
  final Map<String, PseudoStructureDefinition> definitionsStructures = {};
  final Map<String, String> customTypes = {};

  Environnement({this.parent});

  Map<String, dynamic> snapshot() {
    final Map<String, dynamic> allVars = {};

    Environnement? currentParent = parent;
    while (currentParent != null) {
      for (final entry in currentParent.constantes.entries) {
        final nom = currentParent.nomsConstantes[entry.key] ?? entry.key;
        allVars['\u{1F4E6} $nom (const)'] = entry.value;
      }
      for (final entry in currentParent.variables.entries) {
        final nom = currentParent.noms[entry.key] ?? entry.key;
        allVars['\u{1F4E6} $nom'] = entry.value;
      }
      currentParent = currentParent.parent;
    }

    final prefix = parent != null ? '\u{1F4CD} ' : '\u{1F4E6} ';
    for (final entry in constantes.entries) {
      final nom = nomsConstantes[entry.key] ?? entry.key;
      allVars['$prefix$nom (const)'] = entry.value;
    }
    for (final entry in variables.entries) {
      final nom = noms[entry.key] ?? entry.key;
      allVars['$prefix$nom'] = entry.value;
    }
    return allVars;
  }

  void declarerStructure(PseudoStructureDefinition def) =>
      definitionsStructures[def.nom] = def;

  PseudoStructureDefinition? chercherStructure(String nom) {
    final lower = nom.toLowerCase();
    if (definitionsStructures.containsKey(lower))
      return definitionsStructures[lower];
    return parent?.chercherStructure(lower);
  }

  void declarerType(String nom, String definition) {
    customTypes[nom.toLowerCase()] = definition;
  }

  String? chercherType(String nom) {
    final lower = nom.toLowerCase();
    if (customTypes.containsKey(lower)) return customTypes[lower];
    return parent?.chercherType(lower);
  }

  void declarer(String nom, dynamic valeur, String type) {
    final lower = nom.toLowerCase();
    if (variables.containsKey(lower) || constantes.containsKey(lower)) {
      throw Exception("La variable '$nom' est déjà déclarée.");
    }
    variables[lower] = valeur;
    types[lower] = type;
    noms[lower] = nom; // Préserver la casse originale
  }

  void declarerConstante(String nom, dynamic valeur) {
    constantes[nom.toLowerCase()] = valeur;
    nomsConstantes[nom.toLowerCase()] = nom; // Préserver la casse originale
  }

  void declarerFonction(PseudoFonction f) => fonctions[f.nom.toLowerCase()] = f;
  void declarerProcedure(PseudoProcedure p) =>
      procedures[p.nom.toLowerCase()] = p;

  PseudoFonction? chercherFonction(String nom) {
    final lower = nom.toLowerCase();
    if (fonctions.containsKey(lower)) return fonctions[lower];
    return parent?.chercherFonction(lower);
  }

  PseudoProcedure? chercherProcedure(String nom) {
    final lower = nom.toLowerCase();
    if (procedures.containsKey(lower)) return procedures[lower];
    return parent?.chercherProcedure(lower);
  }

  dynamic lire(String nom) {
    final lower = nom.toLowerCase();
    if (constantes.containsKey(lower)) {
      return constantes[lower];
    }
    if (variables.containsKey(lower)) {
      return variables[lower];
    }
    if (parent != null) {
      return parent!.lire(lower);
    }
    throw Exception(
      "La variable ou constante '$nom' n'est pas déclarée. Vérifiez l'orthographe ou si elle a été créée dans la section 'Variables'.",
    );
  }

  String? getType(String nom) {
    final lower = nom.toLowerCase();
    if (types.containsKey(lower)) return types[lower];
    return parent?.getType(lower);
  }

  void assigner(String nom, dynamic valeur) {
    final lower = nom.toLowerCase();
    if (constantes.containsKey(lower)) {
      throw Exception("Impossible de modifier la constante '$nom'");
    }
    if (variables.containsKey(lower)) {
      _validerType(nom, valeur, types[lower]);
      variables[lower] = valeur;
      return;
    }
    if (parent != null) {
      parent!.assigner(lower, valeur);
      return;
    }
    throw Exception("Variable '$nom' non déclarée");
  }

  void _validerType(String nom, dynamic valeur, String? typeAttendu) {
    if (typeAttendu == null) return;

    if (typeAttendu == 'entier') {
      if (valeur is! int && valeur is! BigInt)
        throw Exception("Erreur de type: La variable '$nom' attend un entier.");
    } else if (typeAttendu == 'réel' || typeAttendu == 'reel') {
      if (valeur is! double && valeur is! int) {
        throw Exception(
          "Erreur de type: La variable '$nom' attend un nombre réel.",
        );
      }
    } else if (typeAttendu == 'chaine') {
      if (valeur is! String)
        throw Exception(
          "Erreur de type: La variable '$nom' attend une chaîne de caractères.",
        );
    } else if (typeAttendu == 'booleen') {
      if (valeur is! bool)
        throw Exception(
          "Erreur de type: La variable '$nom' attend un booléen (Vrai ou Faux).",
        );
    } else if (typeAttendu.startsWith('tableau')) {
      if (valeur is! PseudoTableau)
        throw Exception(
          "Erreur de type: La variable '$nom' attend un tableau.",
        );
    } else {
      // Validation pour les structures personnalisées
      final structDef = chercherStructure(typeAttendu.toLowerCase());
      if (structDef != null) {
        if (valeur is! PseudoStructureInstance ||
            valeur.definition.nom != structDef.nom) {
          throw Exception(
            "Erreur de type: La variable '$nom' attend une structure de type '${structDef.nom}'.",
          );
        }
      }
    }
  }
}
