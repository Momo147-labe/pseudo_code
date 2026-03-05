import 'package:pseudo_code/interpreteur/environnement.dart';
import 'package:pseudo_code/interpreteur/blocs/tableaux.dart';
import 'package:pseudo_code/interpreteur/blocs/structures.dart';
import 'package:pseudo_code/interpreteur/operateurs/operateur_math.dart';
import 'package:pseudo_code/interpreteur/operateurs/operateur_logique.dart';
import 'package:pseudo_code/interpreteur/analyse_lexicale.dart';

class EvaluateurExpression {
  final Environnement env;
  final Future<dynamic> Function(String, List<String>)? onAppelFonction;

  EvaluateurExpression(this.env, {this.onAppelFonction});

  Future<dynamic> evaluer(String expr) async {
    final tokens = AnalyseLexicale.analyser(
      expr,
    ).where((t) => t.type != TokenType.finLigne).toList();

    if (tokens.isEmpty) return null;

    final parser = _Parser(tokens, env, onAppelFonction, this);
    return await parser.parseTopLevel();
  }
}

class _Parser {
  final List<Token> tokens;
  final Environnement env;
  final Future<dynamic> Function(String, List<String>)? onAppelFonction;
  final EvaluateurExpression evaluateur;
  int pos = 0;

  _Parser(this.tokens, this.env, this.onAppelFonction, this.evaluateur);

  Token get current =>
      pos < tokens.length ? tokens[pos] : Token(TokenType.finLigne, "");

  void advance() => pos++;

  bool matches(dynamic types, {String? valeur}) {
    if (pos >= tokens.length) return false;
    final token = tokens[pos];
    if (types is List) {
      if (!types.contains(token.type)) return false;
    } else {
      if (token.type != types) return false;
    }
    if (valeur != null && token.valeur.toLowerCase() != valeur.toLowerCase()) {
      return false;
    }
    return true;
  }

  Future<dynamic> parse() async {
    return await ou();
  }

  Future<dynamic> parseTopLevel() async {
    final result = await ou();
    if (pos < tokens.length) {
      throw Exception(
        "Erreur de syntaxe : Fin d'expression attendue à '${tokens[pos].valeur}'",
      );
    }
    return result;
  }

  // ou -> et ( 'ou' et )*
  Future<dynamic> ou() async {
    dynamic node = await et();
    while (matches(TokenType.motCle, valeur: 'ou')) {
      advance();
      final right = await et();
      node = OperateurLogique.ou(node, right);
    }
    return node;
  }

  // et -> comparaison ( 'et' comparaison )*
  Future<dynamic> et() async {
    dynamic node = await comparaison();
    while (matches(TokenType.motCle, valeur: 'et')) {
      advance();
      final right = await comparaison();
      node = OperateurLogique.et(node, right);
    }
    return node;
  }

  // comparaison -> addition ( OP addition )?
  Future<dynamic> comparaison() async {
    dynamic node = await addition();
    final ops = ['<=', '>=', '!=', '<>', '≠', '=', '<', '>'];
    if (matches(TokenType.operateur) && ops.contains(current.valeur)) {
      final op = current.valeur;
      advance();
      final right = await addition();
      node = OperateurLogique.comparer(node, right, op);
    }
    return node;
  }

  // addition -> multiplication ( ('+'|'-') multiplication )*
  Future<dynamic> addition() async {
    dynamic node = await multiplication();
    while (matches(TokenType.operateur) &&
        (current.valeur == '+' || current.valeur == '-')) {
      final op = current.valeur;
      advance();
      final right = await multiplication();
      if (op == '+') {
        node = OperateurMath.addition(node, right);
      } else {
        node = OperateurMath.soustraction(node, right);
      }
    }
    return node;
  }

  // multiplication -> puissance ( ('*'|'/'|'mod'|'div'|'%') puissance )*
  Future<dynamic> multiplication() async {
    dynamic node = await puissance();
    while (true) {
      if (matches(TokenType.operateur) &&
          (current.valeur == '*' ||
              current.valeur == '/' ||
              current.valeur == '%')) {
        final op = current.valeur;
        advance();
        final right = await puissance();
        if (op == '*') node = OperateurMath.multiplication(node, right);
        if (op == '/') node = OperateurMath.division(node, right);
        if (op == '%') node = OperateurMath.modulo(node, right);
      } else if (matches(TokenType.motCle) &&
          (current.valeur.toLowerCase() == 'mod' ||
              current.valeur.toLowerCase() == 'div')) {
        final op = current.valeur.toLowerCase();
        advance();
        final right = await puissance();
        if (op == 'mod') node = OperateurMath.modulo(node, right);
        if (op == 'div') node = OperateurMath.divisionEntiere(node, right);
      } else {
        break;
      }
    }
    return node;
  }

  // puissance -> unaire ( '^' unaire | '²' | '³' )*
  Future<dynamic> puissance() async {
    dynamic node = await unaire();
    while (true) {
      if (matches(TokenType.operateur, valeur: '^')) {
        advance();
        final right = await unaire();
        node = OperateurMath.puissance(node, right);
      } else if (matches(TokenType.operateur, valeur: '²')) {
        advance();
        node = OperateurMath.puissance(node, 2);
      } else if (matches(TokenType.operateur, valeur: '³')) {
        advance();
        node = OperateurMath.puissance(node, 3);
      } else {
        break;
      }
    }
    return node;
  }

  // unaire -> '-' unaire | 'non' unaire | atom
  Future<dynamic> unaire() async {
    if (matches(TokenType.operateur, valeur: '-')) {
      advance();
      final right = await unaire();
      return OperateurMath.soustraction(0, right);
    }
    if (matches(TokenType.motCle, valeur: 'non')) {
      advance();
      final val = await unaire();
      if (val is bool) return !val;
      throw Exception("L'opérateur 'non' attend un booléen, reçu: $val");
    }
    return await atome();
  }

  // atome -> nombre | chaine | booleen | '(' expression ')' | racine_carree(...) | id_ou_appel_ou_acces
  Future<dynamic> atome() async {
    if (matches(TokenType.nombre)) {
      final val = current.valeur;
      advance();
      return num.tryParse(val) ?? BigInt.tryParse(val);
    }
    if (matches(TokenType.chaine)) {
      final val = current.valeur;
      advance();
      return val.substring(1, val.length - 1);
    }
    if (matches(TokenType.booleen)) {
      final val = current.valeur.toLowerCase();
      advance();
      return val == 'vrai';
    }
    if (matches(TokenType.separateur, valeur: '(')) {
      advance();
      final val = await parse();
      if (!matches(TokenType.separateur, valeur: ')')) {
        throw Exception("Parenthèse fermante manquante");
      }
      advance();
      return val;
    }

    // Gestion racine_carree (ancien format fonction pré-définie)
    if (matches(TokenType.motCle, valeur: 'racine_carree')) {
      advance();
      if (!matches(TokenType.separateur, valeur: '('))
        throw Exception("Parenthèse ouvrante attendue après racine_carree");
      advance();
      final val = await parse();
      if (!matches(TokenType.separateur, valeur: ')'))
        throw Exception("Parenthèse fermante attendue");
      advance();
      return OperateurMath.racine(val);
    }

    // ID, Appel de fonction, Accès Tableau, Accès Structure
    if (matches(TokenType.identifiant) || matches(TokenType.motCle)) {
      return await idOuAppelOuAcces();
    }

    throw Exception("Expression invalide ou inattendue : '${current.valeur}'");
  }

  Future<dynamic> idOuAppelOuAcces() async {
    final name = current.valeur;
    advance();

    dynamic currentVal;

    // 1. Appel de fonction ?
    if (matches(TokenType.separateur, valeur: '(')) {
      advance();
      final args = <String>[];
      if (!matches(TokenType.separateur, valeur: ')')) {
        while (true) {
          // On capture l'expression brute pour l'évaluateur (on pourrait faire mieux avec l'AST)
          // Mais ici on va juste parser l'expression pour obtenir sa valeur, puis la re-stringify?
          // Non, on va modifier onAppelFonction pour accepter des valeurs déjà évaluées?
          // Non, on garde la compatibilité. On va donc "re-capturer" le texte de l'argument.
          int start = pos;
          await parse();
          // On recreé le texte de l'argument à partir des tokens consommés
          String argText = tokens
              .sublist(start, pos)
              .map((t) => t.valeur)
              .join(' ');
          args.add(argText);

          if (matches(TokenType.separateur, valeur: ',')) {
            advance();
          } else {
            break;
          }
        }
      }
      if (!matches(TokenType.separateur, valeur: ')'))
        throw Exception("Parenthèse fermante attendue pour l'appel de '$name'");
      advance();

      if (onAppelFonction == null)
        throw Exception("Appels de fonctions non supportés ici.");
      currentVal = await onAppelFonction!(name, args);
    } else {
      // 2. Simple variable
      currentVal = env.lire(name);
    }

    // 3. Chainage d'accès ( [indices] ou .champ )
    while (true) {
      if (matches(TokenType.separateur, valeur: '[')) {
        advance();
        if (currentVal is! PseudoTableau)
          throw Exception("'$name' n'est pas un tableau.");
        final indices = <int>[];
        while (true) {
          final idx = await parse();
          int idxInt;
          if (idx is int) {
            idxInt = idx;
          } else if (idx is double && idx == idx.roundToDouble()) {
            idxInt = idx.toInt();
          } else {
            throw Exception("L'indice doit être un entier. Reçu : $idx");
          }
          indices.add(idxInt);
          if (matches(TokenType.separateur, valeur: ',')) {
            advance();
          } else {
            break;
          }
        }
        if (!matches(TokenType.separateur, valeur: ']'))
          throw Exception("] attendu");
        advance();
        currentVal = currentVal.lire(indices);
      } else if (matches(TokenType.separateur, valeur: '.')) {
        advance();
        if (currentVal is! PseudoStructureInstance)
          throw Exception("Structure attendue");
        if (!matches(TokenType.identifiant) && !matches(TokenType.motCle))
          throw Exception("Nom de champ attendu");
        final fieldName = current.valeur;
        advance();
        currentVal = currentVal.lire(fieldName);
      } else {
        break;
      }
    }

    return currentVal;
  }
}
