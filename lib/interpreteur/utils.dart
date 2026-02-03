class InterpreteurUtils {
  /// Découpe un chemin (ex: E[i].nom) par points, en respectant les crochets
  static List<String> splitChemin(String s) {
    final result = <String>[];
    String courant = "";
    int pileCrochet = 0;
    bool dansChaine = false;

    for (int i = 0; i < s.length; i++) {
      if (s[i] == '"') dansChaine = !dansChaine;
      if (!dansChaine) {
        if (s[i] == '[') pileCrochet++;
        if (s[i] == ']') pileCrochet--;
      }

      if (s[i] == '.' && !dansChaine && pileCrochet == 0) {
        result.add(courant.trim());
        courant = "";
      } else {
        courant += s[i];
      }
    }
    result.add(courant.trim());
    return result;
  }

  /// Découpe une liste d'arguments par virgules, en respectant (), [], et ""
  static List<String> splitArguments(String s) {
    final result = <String>[];
    String courant = "";
    int pileCrochet = 0;
    int pileParen = 0;
    bool dansChaine = false;

    for (int i = 0; i < s.length; i++) {
      if (s[i] == '"') dansChaine = !dansChaine;
      if (!dansChaine) {
        if (s[i] == '[') pileCrochet++;
        if (s[i] == ']') pileCrochet--;
        if (s[i] == '(') pileParen++;
        if (s[i] == ')') pileParen--;
      }

      if (s[i] == ',' && !dansChaine && pileCrochet == 0 && pileParen == 0) {
        result.add(courant.trim());
        courant = "";
      } else {
        courant += charAt(s, i);
      }
    }
    if (courant.isNotEmpty) result.add(courant.trim());
    return result;
  }

  static String charAt(String s, int i) => s[i];
}
