import 'dart:convert';
import 'package:flutter/services.dart';

/// Service pour charger les règles de transformation MCD → MLD
/// depuis le fichier JSON assets/regles_de_MCD_à_MLD.json
class MeriseTransformationRules {
  static const String _rulesFilePath = 'assets/regles_de_MCD_à_MLD.json';

  static List<String>? _cachedRules;

  /// Charge les règles de transformation depuis le fichier JSON
  ///
  /// Retourne une liste de 4 règles :
  /// - Règle 1 : Entité → Relation
  /// - Règle 2 : Association binaire (1,1) → Clé étrangère
  /// - Règle 3 : Association n-aire ou N:N → Table d'association
  /// - Règle 4 : Association réflexive → Relation
  static Future<List<String>> loadRules() async {
    // Utiliser le cache si disponible
    if (_cachedRules != null) {
      return _cachedRules!;
    }

    try {
      // Charger le fichier JSON depuis les assets
      final String jsonString = await rootBundle.loadString(_rulesFilePath);
      final List<dynamic> jsonData = json.decode(jsonString);

      // Extraire les règles
      final rules = <String>[];
      for (final item in jsonData) {
        if (item is Map<String, dynamic>) {
          // Extraire la première valeur (regle1, regle2, etc.)
          final ruleText = item.values.first as String;
          rules.add(ruleText);
        }
      }

      // Mettre en cache
      _cachedRules = rules;
      return rules;
    } catch (e) {
      // En cas d'erreur, retourner des règles par défaut
      return _getDefaultRules();
    }
  }

  /// Retourne une règle spécifique par son index (0-3)
  static Future<String> getRule(int index) async {
    final rules = await loadRules();
    if (index >= 0 && index < rules.length) {
      return rules[index];
    }
    return '';
  }

  /// Règles par défaut en cas d'erreur de chargement
  static List<String> _getDefaultRules() {
    return [
      "Toute entité devient une relation dans laquelle les attributs traduisent les propriétés de l'entité et la clé primaire traduit l'identifiant de l'entité",
      "Une association de dimension 2 avec cardinalité (1,1) n'est pas traduite par une relation mais occasionne l'apparition de l'indentifiant de l'autre entité dans la relation traduisant l'entité implique avec la cardinalité(1,1)",
      "Une association de dimension supérieur ou égal à 2 avec cardinalité maximale égale à n sur chaque pate est traduite par une realtion et la clé primaire de la realtion résultante est composée des identifiants des entités impliqueées dans la collection",
      "une association réflexive est traduite par une relation quelque soit la cardinalité",
    ];
  }

  /// Vide le cache des règles (utile pour les tests)
  static void clearCache() {
    _cachedRules = null;
  }
}
