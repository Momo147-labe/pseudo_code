import 'blocs/tableaux.dart';
import 'blocs/fonctions.dart';
import 'blocs/structures.dart';

class Environnement {
  final Environnement? parent;
  final Map<String, dynamic> variables = {};
  final Map<String, String> types = {};
  final Map<String, dynamic> constantes = {};
  final Map<String, PseudoFonction> fonctions = {};
  final Map<String, PseudoProcedure> procedures = {};
  final Map<String, PseudoStructureDefinition> definitionsStructures = {};
  final Map<String, String> customTypes = {};

  Environnement({this.parent});

  Map<String, dynamic> snapshot() {
    final Map<String, dynamic> allVars = {};
    if (parent != null) {
      allVars.addAll(parent!.snapshot());
    }
    allVars.addAll(constantes);
    allVars.addAll(variables);
    return allVars;
  }

  void declarerStructure(PseudoStructureDefinition def) =>
      definitionsStructures[def.nom] = def;

  PseudoStructureDefinition? chercherStructure(String nom) {
    if (definitionsStructures.containsKey(nom))
      return definitionsStructures[nom];
    return parent?.chercherStructure(nom);
  }

  void declarerType(String nom, String definition) {
    customTypes[nom] = definition;
  }

  String? chercherType(String nom) {
    if (customTypes.containsKey(nom)) return customTypes[nom];
    return parent?.chercherType(nom);
  }

  void declarer(String nom, dynamic valeur, String type) {
    variables[nom] = valeur;
    types[nom] = type;
  }

  void declarerConstante(String nom, dynamic valeur) {
    constantes[nom] = valeur;
  }

  void declarerFonction(PseudoFonction f) => fonctions[f.nom] = f;
  void declarerProcedure(PseudoProcedure p) => procedures[p.nom] = p;

  PseudoFonction? chercherFonction(String nom) {
    if (fonctions.containsKey(nom)) return fonctions[nom];
    return parent?.chercherFonction(nom);
  }

  PseudoProcedure? chercherProcedure(String nom) {
    if (procedures.containsKey(nom)) return procedures[nom];
    return parent?.chercherProcedure(nom);
  }

  dynamic lire(String nom) {
    if (constantes.containsKey(nom)) {
      return constantes[nom];
    }
    if (variables.containsKey(nom)) {
      return variables[nom];
    }
    if (parent != null) {
      return parent!.lire(nom);
    }
    throw Exception(
      "La variable ou constante '$nom' n'est pas déclarée. Vérifiez l'orthographe ou si elle a été créée dans la section 'Variables'.",
    );
  }

  String? getType(String nom) {
    if (types.containsKey(nom)) return types[nom];
    return parent?.getType(nom);
  }

  void assigner(String nom, dynamic valeur) {
    if (constantes.containsKey(nom)) {
      throw Exception("Impossible de modifier la constante '$nom'");
    }
    if (variables.containsKey(nom)) {
      _validerType(nom, valeur, types[nom]);
      variables[nom] = valeur;
      return;
    }
    if (parent != null) {
      parent!.assigner(nom, valeur);
      return;
    }
    throw Exception("Variable '$nom' non déclarée");
  }

  void _validerType(String nom, dynamic valeur, String? typeAttendu) {
    if (typeAttendu == null) return;

    if (typeAttendu == 'entier') {
      if (valeur is! int)
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
