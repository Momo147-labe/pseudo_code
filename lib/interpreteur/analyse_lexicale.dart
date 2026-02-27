import 'mots_cles.dart';

enum TokenType {
  motCle,
  identifiant,
  nombre,
  chaine,
  booleen,
  operateur,
  separateur,
  finLigne,
}

class Token {
  final TokenType type;
  final String valeur;

  Token(this.type, this.valeur);

  @override
  String toString() => 'Token(${type.name}, $valeur)';
}

class AnalyseLexicale {
  static List<Token> analyser(String code) {
    final tokens = <Token>[];

    // Regex améliorée pour capturer :
    // 1. Les chaînes de caractères ("...")
    // 2. Les opérateurs complexes (<- , <=, >=, !=, <>)
    // 3. Les nombres (\d+(\.\d+)?)
    // 4. Les identifiants et mots-clés (incluant les accents)
    // 5. Les opérateurs simples et séparateurs
    final regex = RegExp(
      r'("[^"]*"|<-|<=|>=|!=|<>|[+\-*/^%²³(),:\[\]\.=<>]|≠|[a-zA-ZáàâäãåçéèêëíìîïñóòôöõúùûüýÿæœÁÀÂÄÃÅÇÉÈÊËÍÌÎÏÑÓÒÔÖÕÚÙÛÜÝŸÆŒ]\w*|\d+(?:\.\d+)?)',
    );

    final lignes = code.split('\n');
    for (final ligneBrute in lignes) {
      // Retrait des commentaires pour l'analyse lexicale
      final ligne = ligneBrute.split('//')[0];

      final matches = regex.allMatches(ligne);
      for (final match in matches) {
        final mot = match.group(0)!;

        if (mot.startsWith('"')) {
          tokens.add(Token(TokenType.chaine, mot));
        } else if (MotsCles.estUnMotCle(mot)) {
          final lowerMot = mot.toLowerCase();
          if (lowerMot == 'vrai' || lowerMot == 'faux') {
            tokens.add(Token(TokenType.booleen, mot));
          } else {
            tokens.add(Token(TokenType.motCle, mot));
          }
        } else if (RegExp(r'^\d+(?:\.\d+)?$').hasMatch(mot)) {
          tokens.add(Token(TokenType.nombre, mot));
        } else if ([
          '+',
          '-',
          '*',
          '/',
          '^',
          '%',
          '²',
          '³',
          '<-',
          '=',
          '<',
          '>',
          '<=',
          '>=',
          '!=',
          '≠',
          '<>',
        ].contains(mot)) {
          tokens.add(Token(TokenType.operateur, mot));
        } else if ([',', ':', '(', ')', '[', ']', '.'].contains(mot)) {
          tokens.add(Token(TokenType.separateur, mot));
        } else {
          tokens.add(Token(TokenType.identifiant, mot));
        }
      }
      tokens.add(Token(TokenType.finLigne, '\n'));
    }

    return tokens;
  }
}
