/// Gestionnaire de toutes les opérations logiques et comparaisons
class OperateurLogique {
  // ========== Opérations logiques ==========

  /// Opération ET logique
  static bool et(dynamic a, dynamic b) {
    if (a is bool && b is bool) {
      return a && b;
    }
    throw Exception("L'opération ET nécessite deux booléens");
  }

  /// Opération OU logique
  static bool ou(dynamic a, dynamic b) {
    if (a is bool && b is bool) {
      return a || b;
    }
    throw Exception("L'opération OU nécessite deux booléens");
  }

  /// Opération NON logique
  static bool non(dynamic a) {
    if (a is bool) {
      return !a;
    }
    throw Exception("L'opération NON nécessite un booléen");
  }

  // ========== Comparaisons ==========

  /// Égalité (=)
  static bool egal(dynamic a, dynamic b) {
    return a == b;
  }

  /// Différent (!=, ≠)
  static bool different(dynamic a, dynamic b) {
    return a != b;
  }

  /// Inférieur (<)
  static bool inferieur(dynamic a, dynamic b) {
    if (a is num && b is num) {
      return a < b;
    }
    if (a is String && b is String) {
      return a.compareTo(b) < 0;
    }
    throw Exception("Impossible de comparer $a < $b");
  }

  /// Supérieur (>)
  static bool superieur(dynamic a, dynamic b) {
    if (a is num && b is num) {
      return a > b;
    }
    if (a is String && b is String) {
      return a.compareTo(b) > 0;
    }
    throw Exception("Impossible de comparer $a > $b");
  }

  /// Inférieur ou égal (<=)
  static bool inferieurOuEgal(dynamic a, dynamic b) {
    if (a is num && b is num) {
      return a <= b;
    }
    if (a is String && b is String) {
      return a.compareTo(b) <= 0;
    }
    throw Exception("Impossible de comparer $a <= $b");
  }

  /// Supérieur ou égal (>=)
  static bool superieurOuEgal(dynamic a, dynamic b) {
    if (a is num && b is num) {
      return a >= b;
    }
    if (a is String && b is String) {
      return a.compareTo(b) >= 0;
    }
    throw Exception("Impossible de comparer $a >= $b");
  }

  // ========== Utilitaires ==========

  /// Compare deux valeurs selon un opérateur donné
  static bool comparer(dynamic v1, dynamic v2, String op) {
    switch (op) {
      case '=':
        return egal(v1, v2);
      case '!=':
      case '<>':
      case '≠':
        return different(v1, v2);
      case '<':
        return inferieur(v1, v2);
      case '>':
        return superieur(v1, v2);
      case '<=':
        return inferieurOuEgal(v1, v2);
      case '>=':
        return superieurOuEgal(v1, v2);
      default:
        throw Exception("Opérateur de comparaison inconnu: $op");
    }
  }

  /// Vérifie si une chaîne est un opérateur de comparaison
  static bool estOperateurComparaison(String op) {
    return ['=', '!=', '≠', '<', '>', '<=', '>='].contains(op);
  }

  /// Vérifie si une chaîne est un opérateur logique
  static bool estOperateurLogique(String op) {
    return [' et ', ' ou ', ' non '].contains(op.toLowerCase());
  }
}
