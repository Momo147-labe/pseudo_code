class Parametre {
  final String nom;
  final String type;
  Parametre(this.nom, this.type);
}

abstract class SousProgramme {
  final String nom;
  final List<Parametre> parametres;
  final List<String> lignes; // Le code source brut (section variables + debut)
  final int offset; // Ligne de début dans le fichier original (0-indexed)

  SousProgramme({
    required this.nom,
    required this.parametres,
    required this.lignes,
    required this.offset,
  });
}

class PseudoFonction extends SousProgramme {
  final String typeRetour;

  PseudoFonction({
    required super.nom,
    required super.parametres,
    required super.lignes,
    required super.offset,
    required this.typeRetour,
  });
}

class PseudoProcedure extends SousProgramme {
  PseudoProcedure({
    required super.nom,
    required super.parametres,
    required super.lignes,
    required super.offset,
  });
}

class GestionnaireFonctions {
  // Regex pour détecter les définitions
  static final regFonction = RegExp(
    r'^fonction\s+([a-zA-Z_]\w*)\s*\((.*)\)\s*:\s*(\w+)',
    caseSensitive: false,
  );
  static final regProcedure = RegExp(
    r'^procedure\s+([a-zA-Z_]\w*)\s*\((.*)\)',
    caseSensitive: false,
  );

  // Regex pour détecter un appel : addition(x, y)
  static final regAppel = RegExp(r'^([a-zA-Z_]\w*)\s*\((.*)\)$');

  static List<Parametre> extraireParametres(String paramsBruts) {
    if (paramsBruts.trim().isEmpty) return [];
    // Format: a : entier, b : entier
    return paramsBruts.split(',').map((p) {
      final parts = p.split(':');
      return Parametre(parts[0].trim(), parts[1].trim());
    }).toList();
  }
}
