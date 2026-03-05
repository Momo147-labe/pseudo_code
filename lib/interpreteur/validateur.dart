class StructureError {
  final String message;
  final int? line;

  StructureError(this.message, {this.line});

  @override
  String toString() => message;
}

class ValidateurStructure {
  static List<StructureError> valider(List<String> lignes) {
    final errors = <StructureError>[];
    final stack = <String>[];
    bool aDebut = false;
    bool aFin = false;

    // 1. Vérifier le début (doit commencer par Algorithme)
    int premierIdx = -1;
    for (int i = 0; i < lignes.length; i++) {
      if (lignes[i].trim().isNotEmpty && !lignes[i].trim().startsWith('//')) {
        premierIdx = i;
        break;
      }
    }

    if (premierIdx == -1 ||
        !lignes[premierIdx].trim().toLowerCase().startsWith('algorithme')) {
      errors.add(
        StructureError(
          "L'algorithme doit commencer par le mot-clé 'Algorithme'.",
          line: premierIdx != -1 ? premierIdx + 1 : 1,
        ),
      );
    }

    // 2. Vérifier la fin (doit finir par Fin)
    int dernierIdx = -1;
    String dernierContenu = "";
    for (int i = lignes.length - 1; i >= 0; i--) {
      final l = lignes[i].split('//')[0].trim().toLowerCase();
      if (l.isNotEmpty) {
        dernierIdx = i;
        dernierContenu = l;
        break;
      }
    }

    if (dernierIdx == -1 || !dernierContenu.startsWith('fin')) {
      errors.add(
        StructureError(
          "L'algorithme doit se terminer par le mot-clé 'Fin'.",
          line: dernierIdx != -1 ? dernierIdx + 1 : lignes.length,
        ),
      );
    }

    for (int i = 0; i < lignes.length; i++) {
      final ligneBrute = lignes[i];
      String l = ligneBrute.split('//')[0].trim().toLowerCase();

      // On retire tout ce qui est entre guillemets
      l = l.replaceAll(RegExp(r'".*?"'), '');
      if (l.isEmpty) continue;

      // 3. Détection des limites du programme
      if (l == 'début' || l == 'debut') aDebut = true;
      if (l == 'fin') aFin = true;

      // 4. Comptage des blocs
      final siReg = RegExp(r'\bsi\b');
      final tantqueReg = RegExp(r'\btantque\b');
      final pourReg = RegExp(r'\bpour\b');
      final repeterReg = RegExp(r'\brepeter\b');
      final fonctionReg = RegExp(r'\bfonction\b');
      final procedureReg = RegExp(r'\bprocedure\b');
      final structureReg = RegExp(r'\bstructure\b');
      final selonReg = RegExp(r'\bselon\b');

      final finsiReg = RegExp(r'\bfinsi\b');
      final fintantqueReg = RegExp(r'\bfintantque\b');
      final finpourReg = RegExp(r'\bfinpour\b|\bfpour\b');
      final jusquaReg = RegExp(r'\bjusqua\b');
      final finfonctionReg = RegExp(r'\bfinfonction\b');
      final finprocedureReg = RegExp(r'\bfinprocedure\b');
      final finstructureReg = RegExp(r'\bfinstructure\b');
      final finselonReg = RegExp(r'\bfinselon\b');

      bool estFermeture = false;
      if (finsiReg.hasMatch(l) || l.startsWith('fin si')) {
        stack.removeLastIf('si', errors, i + 1);
        estFermeture = true;
      } else if (fintantqueReg.hasMatch(l) || l.startsWith('fin tant que')) {
        stack.removeLastIf('tantque', errors, i + 1);
        estFermeture = true;
      } else if (finpourReg.hasMatch(l) || l.startsWith('fin pour')) {
        stack.removeLastIf('pour', errors, i + 1);
        estFermeture = true;
      } else if (jusquaReg.hasMatch(l)) {
        stack.removeLastIf('repeter', errors, i + 1);
        estFermeture = true;
      } else if (finfonctionReg.hasMatch(l)) {
        stack.removeLastIf('fonction', errors, i + 1);
        estFermeture = true;
      } else if (finprocedureReg.hasMatch(l)) {
        stack.removeLastIf('procedure', errors, i + 1);
        estFermeture = true;
      } else if (finstructureReg.hasMatch(l)) {
        stack.removeLastIf('structure', errors, i + 1);
        estFermeture = true;
      } else if (finselonReg.hasMatch(l)) {
        stack.removeLastIf('selon', errors, i + 1);
        estFermeture = true;
      }

      if (!estFermeture) {
        // L'utilisateur veut une correspondance 1:1 pour si/sinon-si et finsi
        if (siReg.hasMatch(l) && !l.contains('finsi')) stack.add('si');
        if (tantqueReg.hasMatch(l) && !l.contains('fintantque'))
          stack.add('tantque');
        if (pourReg.hasMatch(l) &&
            !l.contains('finpour') &&
            !l.contains('fpour'))
          stack.add('pour');
        if (repeterReg.hasMatch(l)) stack.add('repeter');
        if (fonctionReg.hasMatch(l) && !l.contains('finfonction'))
          stack.add('fonction');
        if (procedureReg.hasMatch(l) && !l.contains('finprocedure'))
          stack.add('procedure');
        if (structureReg.hasMatch(l) && !l.contains('finstructure'))
          stack.add('structure');
        if (selonReg.hasMatch(l) && !l.contains('finselon')) stack.add('selon');
      }
    }

    if (!aDebut) errors.add(StructureError("Le mot-clé 'Début' est manquant."));
    // Note: aFin est déjà vérifié par le check de la dernière ligne, mais on le garde pour la cohérence
    if (!aFin) errors.add(StructureError("Le mot-clé 'Fin' est manquant."));

    if (stack.isNotEmpty) {
      errors.add(
        StructureError(
          "Certains blocs ne sont pas fermés : ${stack.join(', ')}",
        ),
      );
    }

    return errors;
  }
}

extension StackHelper on List<String> {
  void removeLastIf(String expected, List<StructureError> errors, int line) {
    if (isEmpty) {
      errors.add(
        StructureError(
          "Ligne $line : Mot-clé de fin inattendu pour '$expected'.",
          line: line,
        ),
      );
    } else if (last != expected) {
      errors.add(
        StructureError(
          "Ligne $line : On attendait la fin de '$last', mais on a trouvé la fin de '$expected'.",
          line: line,
        ),
      );
      removeLast();
    } else {
      removeLast();
    }
  }
}
