import 'dart:math';

/// Gestionnaire de toutes les opérations mathématiques
class OperateurMath {
  // ========== Opérations arithmétiques de base ==========

  /// Addition de deux nombres
  static dynamic addition(dynamic a, dynamic b) {
    if (a is num && b is num) {
      return a + b;
    }
    // Gestion de la concaténation de chaînes si nécessaire
    if (a is String || b is String) {
      return a.toString() + b.toString();
    }
    throw Exception("Impossible d'additionner $a et $b");
  }

  /// Soustraction de deux nombres
  static dynamic soustraction(dynamic a, dynamic b) {
    if (a is num && b is num) {
      return a - b;
    }
    throw Exception("Impossible de soustraire $b de $a");
  }

  /// Multiplication de deux nombres
  static dynamic multiplication(dynamic a, dynamic b) {
    if (a is num && b is num) {
      return a * b;
    }
    throw Exception("Impossible de multiplier $a par $b");
  }

  /// Division de deux nombres (avec vérification division par zéro)
  static dynamic division(dynamic a, dynamic b) {
    if (a is num && b is num) {
      if (b == 0) {
        throw Exception("Division par zéro impossible.");
      }
      return a / b;
    }
    throw Exception("Impossible de diviser $a par $b");
  }

  /// Modulo (reste de la division)
  static dynamic modulo(dynamic a, dynamic b) {
    if (a is num && b is num) {
      if (b == 0) {
        throw Exception("Modulo par zéro impossible.");
      }
      return a % b;
    }
    throw Exception("Impossible de calculer $a mod $b");
  }

  /// Division entière
  static dynamic divisionEntiere(dynamic a, dynamic b) {
    if (a is num && b is num) {
      if (b == 0) {
        throw Exception("Division entière par zéro impossible.");
      }
      return a ~/ b;
    }
    throw Exception("Impossible de calculer $a div $b");
  }

  // ========== Fonctions mathématiques avancées ==========

  /// Puissance (a^b)
  static dynamic puissance(dynamic base, dynamic exposant) {
    if (base is num && exposant is num) {
      return pow(base, exposant);
    }
    throw Exception("Impossible de calculer $base ^ $exposant");
  }

  /// Racine carrée
  static dynamic racine(dynamic n) {
    if (n is num) {
      if (n < 0) {
        throw Exception("Racine carrée d'un nombre négatif impossible.");
      }
      return sqrt(n);
    }
    throw Exception("Impossible de calculer la racine de $n");
  }

  /// Valeur absolue
  static dynamic abs(dynamic n) {
    if (n is num) {
      return n.abs();
    }
    throw Exception("Impossible de calculer la valeur absolue de $n");
  }

  /// Arrondi au plus proche
  static dynamic arrondi(dynamic n) {
    if (n is num) {
      return n.round();
    }
    throw Exception("Impossible d'arrondir $n");
  }

  /// Plancher (arrondi inférieur)
  static dynamic plancher(dynamic n) {
    if (n is num) {
      return n.floor();
    }
    throw Exception("Impossible de calculer le plancher de $n");
  }

  /// Plafond (arrondi supérieur)
  static dynamic plafond(dynamic n) {
    if (n is num) {
      return n.ceil();
    }
    throw Exception("Impossible de calculer le plafond de $n");
  }

  // ========== Utilitaires ==========

  /// Parse un nombre (gère les négatifs)
  static num? parseNombre(String expr) {
    expr = expr.trim();

    // Essayer d'abord comme entier
    final entier = int.tryParse(expr);
    if (entier != null) return entier;

    // Puis comme réel
    final reel = double.tryParse(expr);
    if (reel != null) return reel;

    return null;
  }

  /// Vérifie si une chaîne représente un nombre (y compris négatif)
  static bool estNombre(String expr) {
    return parseNombre(expr) != null;
  }

  /// Gère les nombres négatifs dans une expression
  /// Ex: "-5" ou "-(3+2)"
  static bool estNegatif(String expr) {
    expr = expr.trim();
    return expr.startsWith('-') && expr.length > 1;
  }
}
