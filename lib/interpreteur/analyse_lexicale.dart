enum TokenType { motCle, identifiant, nombre, operateur, separateur, finLigne }

class Token {
  final TokenType type;
  final String valeur;

  Token(this.type, this.valeur);
}

class AnalyseLexicale {
  static List<Token> analyser(String code) {
    final tokens = <Token>[];

    // Regex pour capturer les mots, les nombres, les chaînes de caractères, les opérateurs et les séparateurs
    final regex = RegExp(
      r'("[^"]*"|\d+|<-|[+\-*/(),:]|[a-zA-ZáàâäãåçéèêëíìîïñóòôöõúùûüýÿæœÁÀÂÄÃÅÇÉÈÊËÍÌÎÏÑÓÒÔÖÕÚÙÛÜÝŸÆŒ]\w*)',
    );

    final lignes = code.split('\n');
    for (final ligne in lignes) {
      final matches = regex.allMatches(ligne);
      for (final match in matches) {
        final mot = match.group(0)!;

        if (mot.startsWith('"')) {
          tokens.add(
            Token(TokenType.nombre, mot),
          ); // On utilise nombre provisoirement pour les constantes
        } else if ([
          'Algorithme',
          'Variables',
          'Début',
          'Fin',
          'si',
          'alors',
          'sinon',
          'tantque',
          'faire',
          'afficher',
          'lire',
        ].contains(mot)) {
          tokens.add(Token(TokenType.motCle, mot));
        } else if (RegExp(r'^\d+$').hasMatch(mot)) {
          tokens.add(Token(TokenType.nombre, mot));
        } else if (['+', '-', '*', '/', '<-'].contains(mot)) {
          tokens.add(Token(TokenType.operateur, mot));
        } else if ([',', ':', '(', ')'].contains(mot)) {
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
