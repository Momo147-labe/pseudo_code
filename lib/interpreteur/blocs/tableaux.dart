import 'package:pseudo_code/interpreteur/environnement.dart';
import 'package:pseudo_code/interpreteur/blocs/structures.dart';

class PseudoTableau {
  final List<int> mins;
  final List<int> maxs;
  final String typeElement;
  final PseudoStructureDefinition? structureDef;
  final Map<String, dynamic> _elements = {};

  PseudoTableau({
    required this.mins,
    required this.maxs,
    required this.typeElement,
    this.structureDef,
  }) {
    // Si c'est une structure, on pourrait pré-remplir, mais pour la 2D+
    // on va plutôt le faire à la demande dans 'lire' pour économiser la mémoire
    // sauf si c'est de petite taille. Pour l'instant, lecture à la demande suffit.
  }

  void assigner(List<int> indices, dynamic valeur) {
    _validerIndices(indices);
    _elements[indices.join(',')] = valeur;
  }

  dynamic lire(List<int> indices) {
    _validerIndices(indices);
    final key = indices.join(',');
    if (!_elements.containsKey(key)) {
      _elements[key] = _valeurParDefaut();
    }
    return _elements[key];
  }

  void _validerIndices(List<int> indices) {
    if (indices.length != mins.length) {
      throw Exception(
        "Nombre d'indices incorrect. Attendu: ${mins.length}, Reçu: ${indices.length}",
      );
    }
    for (int i = 0; i < indices.length; i++) {
      if (indices[i] < mins[i] || indices[i] > maxs[i]) {
        throw Exception(
          "Index ${indices[i]} hors des bornes [${mins[i]}..${maxs[i]}] à la dimension ${i + 1}",
        );
      }
    }
  }

  dynamic _valeurParDefaut() {
    if (structureDef != null) return structureDef!.instancier();
    switch (typeElement.toLowerCase()) {
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
        return null;
    }
  }

  String formatGrid() {
    if (mins.length != 2) return toString();

    final rowMin = mins[0];
    final rowMax = maxs[0];
    final colMin = mins[1];
    final colMax = maxs[1];

    // Calculer la largeur max des cellules
    int maxCellWidth = 0;
    for (int i = rowMin; i <= rowMax; i++) {
      for (int j = colMin; j <= colMax; j++) {
        final val = lire([i, j]).toString();
        if (val.length > maxCellWidth) maxCellWidth = val.length;
      }
    }
    maxCellWidth += 2; // Padding

    final cellDivider = "-" * maxCellWidth;
    final rowSeparator = "+" + (cellDivider + "+") * (colMax - colMin + 1);

    StringBuffer sb = StringBuffer();
    sb.writeln(rowSeparator);

    for (int i = rowMin; i <= rowMax; i++) {
      sb.write("|");
      for (int j = colMin; j <= colMax; j++) {
        final val = lire([i, j]).toString();
        sb.write(
          val.padLeft((maxCellWidth + val.length) ~/ 2).padRight(maxCellWidth),
        );
        sb.write("|");
      }
      sb.writeln("");
      sb.writeln(rowSeparator);
    }

    return sb.toString();
  }

  String formatStructureGrid() {
    if (mins.length > 2) return toString();
    final is2D = mins.length == 2;

    // Extraction des noms des champs
    List<String> fieldNames = [];
    if (structureDef != null) {
      fieldNames = structureDef!.champs.map((c) => c.nom).toList();
    } else {
      for (var val in _elements.values) {
        if (val is PseudoStructureInstance) {
          fieldNames = val.valeurs.keys.toList();
          break;
        }
      }
    }
    if (fieldNames.isEmpty) return toString();

    if (!is2D) {
      // FORMAT 1D : Tableau horizontal (Champs = Colonnes)
      return _format1DStructureTable(fieldNames);
    } else {
      // FORMAT 2D : Grille de matrices (Chaque cellule = Boîte multi-lignes)
      return _format2DStructureGrid(fieldNames);
    }
  }

  String _format1DStructureTable(List<String> fieldNames) {
    final rowMin = mins[0];
    final rowMax = maxs[0];

    // Calculer la largeur de chaque colonne (y compris l'index)
    Map<String, int> widths = {};
    widths["__INDEX__"] = rowMax.toString().length + 2;

    for (final field in fieldNames) {
      int maxW = field.length;
      for (int i = rowMin; i <= rowMax; i++) {
        final val = lire([i]);
        if (val is PseudoStructureInstance) {
          final s = val.lire(field).toString();
          if (s.length > maxW) maxW = s.length;
        }
      }
      widths[field] = maxW + 2;
    }

    // Construction de la bordure
    String divider = "+";
    divider += "-" * widths["__INDEX__"]! + "+";
    for (final field in fieldNames) {
      divider += "-" * widths[field]! + "+";
    }

    StringBuffer sb = StringBuffer();
    sb.writeln(divider);

    // En-tête
    sb.write("|");
    sb.write(" # ".padRight(widths["__INDEX__"]!));
    for (final field in fieldNames) {
      sb.write("|");
      final h = field[0].toUpperCase() + field.substring(1);
      sb.write(" " + h.padRight(widths[field]! - 1));
    }
    sb.writeln("|");
    sb.writeln(divider);

    // Données
    for (int i = rowMin; i <= rowMax; i++) {
      sb.write("|");
      sb.write(" $i ".padRight(widths["__INDEX__"]!));
      final val = lire([i]);
      for (final field in fieldNames) {
        sb.write("|");
        String content = "";
        if (val is PseudoStructureInstance) {
          content = val.lire(field).toString();
        }
        sb.write(" " + content.padRight(widths[field]! - 1));
      }
      sb.writeln("|");
    }
    sb.writeln(divider);

    return sb.toString();
  }

  String _format2DStructureGrid(List<String> fieldNames) {
    final rowMin = mins[0];
    final rowMax = maxs[0];
    final colMin = mins[1];
    final colMax = maxs[1];

    int maxCellWidth = 0;
    for (int i = rowMin; i <= rowMax; i++) {
      for (int j = colMin; j <= colMax; j++) {
        final val = lire([i, j]);
        if (val is PseudoStructureInstance) {
          for (final field in fieldNames) {
            final line =
                "${field[0].toUpperCase()}${field.substring(1)} : ${val.lire(field)}";
            if (line.length > maxCellWidth) maxCellWidth = line.length;
          }
        }
      }
    }
    maxCellWidth += 2;

    final cellDivider = "-" * maxCellWidth;
    final rowSeparator = "+" + (cellDivider + "+") * (colMax - colMin + 1);

    StringBuffer sb = StringBuffer();
    sb.writeln(rowSeparator);

    for (int i = rowMin; i <= rowMax; i++) {
      for (int f = 0; f < fieldNames.length; f++) {
        final field = fieldNames[f];
        sb.write("|");
        for (int j = colMin; j <= colMax; j++) {
          final val = lire([i, j]);
          String content = "";
          if (val is PseudoStructureInstance) {
            content =
                "${field[0].toUpperCase()}${field.substring(1)} : ${val.lire(field)}";
          }
          sb.write(" " + content.padRight(maxCellWidth - 1));
          sb.write("|");
        }
        sb.writeln("");
      }
      sb.writeln(rowSeparator);
    }

    return sb.toString();
  }

  @override
  String toString() {
    if (mins.length > 1) return "Tableau ${mins.length}D ($typeElement)";

    StringBuffer sb = StringBuffer();
    sb.writeln("");
    sb.writeln("┌────────┬─────────────┐");
    sb.writeln("│ Index  │ Valeur      │");
    sb.writeln("├────────┼─────────────┤");
    for (int i = mins[0]; i <= maxs[0]; i++) {
      String idxStr = i.toString().padRight(6);
      String valStr = lire([i]).toString().padRight(11);
      if (valStr.length > 11) valStr = valStr.substring(0, 8) + "...";
      sb.writeln("│ $idxStr │ $valStr │");
    }
    sb.write("└────────┴─────────────┘");
    return sb.toString();
  }
}

class GestionnaireTableaux {
  static final RegExp regAffectation = RegExp(
    r'^([a-zA-Z_]\w*)\s*\[(.*)\]\s*<-\s*(.*)$',
  );
  static final RegExp regAcces = RegExp(r'^([a-zA-Z_]\w*)\s*\[(.*)\]$');

  static bool estAffectation(String ligne) => regAffectation.hasMatch(ligne);

  static Future<void> traiterAffectationAsync(
    String ligne,
    Environnement env,
    Future<dynamic> Function(String) evaluer,
  ) async {
    final match = regAffectation.firstMatch(ligne);
    if (match != null) {
      final nomTab = match.group(1)!;
      final indexExprs = match.group(2)!;
      final valExp = match.group(3)!;

      final tab = env.lire(nomTab);
      if (tab is! PseudoTableau)
        throw Exception("'$nomTab' n'est pas un tableau.");

      // Découper les indices par virgules
      final parts = _extraireArguments(indexExprs);
      final indices = <int>[];
      for (final p in parts) {
        final idx = await evaluer(p);
        if (idx is! int)
          throw Exception(
            "L'indice de tableau doit être un entier. Reçu: $idx",
          );
        indices.add(idx);
      }

      final valeur = await evaluer(valExp);
      tab.assigner(indices, valeur);
    }
  }

  static List<String> _extraireArguments(String argsBruts) {
    final args = <String>[];
    String courant = "";
    int parenStack = 0;
    int crochetStack = 0;
    for (var i = 0; i < argsBruts.length; i++) {
      final char = argsBruts[i];
      if (char == '(') parenStack++;
      if (char == ')') parenStack--;
      if (char == '[') crochetStack++;
      if (char == ']') crochetStack--;

      if (char == ',' && parenStack == 0 && crochetStack == 0) {
        args.add(courant.trim());
        courant = "";
      } else {
        courant += char;
      }
    }
    if (courant.isNotEmpty) args.add(courant.trim());
    return args;
  }
}
