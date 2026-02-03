import 'package:pseudo_code/interpreteur/environnement.dart';
import 'package:pseudo_code/interpreteur/blocs/tableaux.dart';
import 'package:pseudo_code/interpreteur/blocs/structures.dart';
import 'package:pseudo_code/interpreteur/operateurs/operateur_math.dart';
import 'package:pseudo_code/interpreteur/operateurs/operateur_logique.dart';
import 'package:pseudo_code/interpreteur/utils.dart';

class EvaluateurExpression {
  final Environnement env;
  final Future<dynamic> Function(String, List<String>)? onAppelFonction;

  EvaluateurExpression(this.env, {this.onAppelFonction});

  Future<dynamic> evaluer(String expr) async {
    expr = expr.trim();
    if (expr.isEmpty) return null;

    // 1. Gérer les priorités (parenthèses)
    if (expr.startsWith('(') && expr.endsWith(')')) {
      // Vérifier si ce sont des parenthèses englobantes réelles
      int pile = 0;
      bool englobantes = true;
      for (int i = 0; i < expr.length - 1; i++) {
        if (expr[i] == '(') pile++;
        if (expr[i] == ')') pile--;
        if (pile == 0) {
          englobantes = false;
          break;
        }
      }
      if (englobantes) return await evaluer(expr.substring(1, expr.length - 1));
    }

    // 2. Opérateurs logiques et comparaisons (plus basse priorité)
    // 2. Opérateurs logiques et comparaisons (plus basse priorité)
    final resOu = await _evaluerLogique(expr, ' ou ');
    if (resOu != null) return resOu;

    final resEt = await _evaluerLogique(expr, ' et ');
    if (resEt != null) return resEt;

    // Gestion du NON (négation)
    if (expr.toLowerCase().startsWith('non ') ||
        expr.toLowerCase().startsWith('non(')) {
      final sub = expr.substring(3).trim();
      final val = await evaluer(sub);
      if (val is bool) return !val;
      throw Exception("L'opérateur 'non' attend un booléen, reçu: $val");
    }

    final compOps = ['<=', '>=', '!=', '<>', '≠', '=', '<', '>'];
    for (final op in compOps) {
      if (expr.contains(op)) {
        // Attention: Ne pas splitter si c'est dans une chaîne
        final parts = _splitHorsChaine(expr, op);
        if (parts.length == 2) {
          final v1 = await evaluer(parts[0]);
          final v2 = await evaluer(parts[1]);
          return _comparer(v1, v2, op);
        }
      }
    }

    // 3. Gestion des nombres négatifs (ex: -10, -3.5)
    // IMPORTANT: Doit être traité AVANT l'addition/soustraction
    if (expr.startsWith('-') && !expr.contains(' ')) {
      // Vérifier si c'est un nombre négatif simple (pas une expression)
      final resteSansNeg = expr.substring(1).trim();
      final numNegatif = num.tryParse(resteSansNeg);
      if (numNegatif != null) {
        return -numNegatif;
      }

      // Si ce n'est pas un nombre simple, c'est peut-être -(expression)
      if (resteSansNeg.startsWith('(') && resteSansNeg.endsWith(')')) {
        return OperateurMath.soustraction(0, await evaluer(resteSansNeg));
      }
    }

    // 4. Addition / Soustraction
    final addSubParts = _splitHorsChaine(expr, '+', op2: '-');
    if (addSubParts.length > 1) {
      dynamic resultat = await evaluer(addSubParts[0]);
      int charIdx = addSubParts[0].length;
      for (int i = 1; i < addSubParts.length; i++) {
        String op = expr[charIdx];
        dynamic suivant = await evaluer(addSubParts[i]);

        // Délégation aux opérateurs mathématiques
        if (op == '+') {
          resultat = OperateurMath.addition(resultat, suivant);
        } else {
          resultat = OperateurMath.soustraction(resultat, suivant);
        }

        charIdx += addSubParts[i].length + 1;
      }
      return resultat;
    }

    // 4. Multiplication / Division / Mod / Div
    final multDivParts = _splitHorsChaine(
      expr,
      '*',
      op2: '/',
      op3: ' mod ',
      op4: ' div ',
      op5: '%',
    );
    if (multDivParts.length > 1) {
      dynamic resultat = await evaluer(multDivParts[0]);
      int currentPos = multDivParts[0].length;
      for (int i = 1; i < multDivParts.length; i++) {
        String opFound = "";
        if (expr.substring(currentPos).startsWith('*'))
          opFound = '*';
        else if (expr.substring(currentPos).startsWith('/'))
          opFound = '/';
        else if (expr.substring(currentPos).toLowerCase().startsWith(' mod '))
          opFound = ' mod ';
        else if (expr.substring(currentPos).toLowerCase().startsWith(' div '))
          opFound = ' div ';
        else if (expr.substring(currentPos).startsWith('%'))
          opFound = '%';

        dynamic suivant = await evaluer(multDivParts[i]);

        // Délégation aux opérateurs mathématiques
        if (opFound == '*') {
          resultat = OperateurMath.multiplication(resultat, suivant);
        } else if (opFound == '/') {
          resultat = OperateurMath.division(resultat, suivant);
        } else if (opFound == ' mod ' || opFound == '%') {
          resultat = OperateurMath.modulo(resultat, suivant);
        } else if (opFound == ' div ') {
          resultat = OperateurMath.divisionEntiere(resultat, suivant);
        }

        currentPos += multDivParts[i].length + opFound.length;
      }
      return resultat;
    }

    // 5. Puissance (^)
    if (expr.contains('^')) {
      final parts = _splitHorsChaine(expr, '^');
      if (parts.length == 2) {
        return OperateurMath.puissance(
          await evaluer(parts[0]),
          await evaluer(parts[1]),
        );
      }
    }

    // 6. Atomes (Nombres, Chaînes, Variables, Fonctions, Accès Tableaux, Accès Structures)

    // Fonctions Math
    if (expr.toLowerCase().startsWith('racine_carree(')) {
      final sub = expr.substring(14, expr.length - 1);
      return OperateurMath.racine(await evaluer(sub));
    }

    // Chaîne de caractères
    if (expr.startsWith('"') && expr.endsWith('"')) {
      return expr.substring(1, expr.length - 1);
    }

    // Booléens
    if (expr.toLowerCase() == 'vrai') return true;
    if (expr.toLowerCase() == 'faux') return false;

    // Nombres
    final numVal = num.tryParse(expr);
    if (numVal != null) return numVal;

    // Appel de fonction (ex: addition(1, 2))
    final funcMatch = RegExp(r'^([a-zA-Z_]\w*)\s*\((.*)\)$').firstMatch(expr);
    if (funcMatch != null && onAppelFonction != null) {
      final nom = funcMatch.group(1)!;
      final argsStr = funcMatch.group(2)!;
      final args = _extraireArguments(argsStr);
      return await onAppelFonction!(nom, args);
    }

    // Accès Tableau (ex: notes[i] ou M[i, j])
    final tabMatch = GestionnaireTableaux.regAcces.firstMatch(expr);
    if (tabMatch != null) {
      final nomTab = tabMatch.group(1)!;
      final indicesBruts = tabMatch.group(2)!;
      final tab = env.lire(nomTab);
      if (tab is! PseudoTableau)
        throw Exception("'$nomTab' n'est pas un tableau.");

      final parts = _extraireArguments(indicesBruts);
      final indices = <int>[];
      for (final p in parts) {
        final idx = await evaluer(p);
        if (idx is! int)
          throw Exception("L'indice doit être un entier. Reçu: $idx");
        indices.add(idx);
      }
      return tab.lire(indices);
    }

    // Accès Structure (ex: e.nom ou tab[i].nom)
    if (expr.contains('.')) {
      final parts = InterpreteurUtils.splitChemin(expr);
      if (parts.length > 1) {
        dynamic courant = await evaluer(parts[0].trim());
        for (int i = 1; i < parts.length; i++) {
          if (courant is PseudoStructureInstance) {
            courant = courant.lire(parts[i].trim());
          } else {
            throw Exception(
              "'${parts[i - 1]}' n'est pas une structure valdie pour accéder à '${parts[i]}'.",
            );
          }
        }
        return courant;
      }
    }

    // Variable simple
    return env.lire(expr);
  }

  Future<dynamic>? _evaluerLogique(String expr, String op) async {
    final parts = _splitHorsChaine(expr, op);
    if (parts.length >= 2) {
      final v1 = await evaluer(parts[0]);
      final v2 = await evaluer(parts[1]);

      if (op == ' ou ') {
        return OperateurLogique.ou(v1, v2);
      } else if (op == ' et ') {
        return OperateurLogique.et(v1, v2);
      }
    }
    return null;
  }

  bool _comparer(dynamic v1, dynamic v2, String op) {
    return OperateurLogique.comparer(v1, v2, op);
  }

  List<String> _splitHorsChaine(
    String s,
    String op, {
    String? op2,
    String? op3,
    String? op4,
    String? op5,
  }) {
    final result = <String>[];
    String courant = "";
    bool dansChaine = false;
    int pileParen = 0;

    for (int i = 0; i < s.length; i++) {
      if (s[i] == '"') dansChaine = !dansChaine;
      if (!dansChaine) {
        if (s[i] == '(') pileParen++;
        if (s[i] == ')') pileParen--;
      }

      bool matches = false;
      String currentOp = "";
      if (!dansChaine && pileParen == 0) {
        if (s.substring(i).startsWith(op)) {
          matches = true;
          currentOp = op;
        } else if (op2 != null && s.substring(i).startsWith(op2)) {
          matches = true;
          currentOp = op2;
        } else if (op3 != null && s.substring(i).startsWith(op3)) {
          matches = true;
          currentOp = op3;
        } else if (op4 != null && s.substring(i).startsWith(op4)) {
          matches = true;
          currentOp = op4;
        } else if (op5 != null && s.substring(i).startsWith(op5)) {
          matches = true;
          currentOp = op5;
        }
      }

      if (matches) {
        result.add(courant);
        courant = "";
        i += currentOp.length - 1;
      } else {
        courant += s[i];
      }
    }
    result.add(courant);
    return result;
  }

  List<String> _extraireArguments(String argsBruts) {
    return InterpreteurUtils.splitArguments(argsBruts);
  }
}
