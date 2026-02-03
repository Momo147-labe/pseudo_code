import '../merise/mcd_models.dart';
import 'sql_utils.dart';

/// Sévérité d'un problème de normalisation
enum IssueSeverity { error, warning, info }

/// Représente un problème détecté dans le MCD
class NormalizationIssue {
  final String title;
  final String description;
  final IssueSeverity severity;
  final String? affectedEntityId;
  final String? suggestion;

  const NormalizationIssue({
    required this.title,
    required this.description,
    required this.severity,
    this.affectedEntityId,
    this.suggestion,
  });
}

/// Analyseur de MCD pour la normalisation
class McdAnalyzer {
  /// Analyse complète du MCD
  static List<NormalizationIssue> analyze(Mcd mcd) {
    final issues = <NormalizationIssue>[];

    // 0. Vérifier la qualité des identifiants (noms)
    issues.addAll(_checkIdentifierQuality(mcd));

    // 1. Vérifier les clés primaires
    issues.addAll(_checkPrimaryKeys(mcd));

    // 2. Détecter les noms dupliqués
    issues.addAll(_checkDuplicateNames(mcd));

    // 3. Vérifier les types d'attributs
    issues.addAll(_checkAttributeTypes(mcd));

    // 4. Détecter les entités isolées
    issues.addAll(_checkIsolatedEntities(mcd));

    // 5. Vérifier les associations
    issues.addAll(_checkRelations(mcd));

    // 6. Détecter les attributs dupliqués
    issues.addAll(_checkDuplicateAttributes(mcd));

    return issues;
  }

  /// Calcule un score de qualité (0-100)
  static int calculateScore(List<NormalizationIssue> issues) {
    int score = 100;
    for (final issue in issues) {
      switch (issue.severity) {
        case IssueSeverity.error:
          score -= 20;
          break;
        case IssueSeverity.warning:
          score -= 10;
          break;
        case IssueSeverity.info:
          score -= 5;
          break;
      }
    }
    return score.clamp(0, 100);
  }

  /// Vérifie que toutes les entités ont une clé primaire
  static List<NormalizationIssue> _checkPrimaryKeys(Mcd mcd) {
    final issues = <NormalizationIssue>[];

    for (final entity in mcd.entities) {
      bool hasPK = false;
      for (final attr in entity.attributes) {
        if (attr.isPrimaryKey) {
          hasPK = true;
          break;
        }
      }

      if (!hasPK) {
        issues.add(
          NormalizationIssue(
            title: 'Clé primaire manquante',
            description:
                'L\'entité "${entity.name}" n\'a pas de clé primaire définie.',
            severity: IssueSeverity.error,
            affectedEntityId: entity.id,
            suggestion:
                'Ajoutez un attribut "id" ou marquez un attribut existant comme clé primaire pour identifier de manière unique chaque occurrence.',
          ),
        );
      }
    }

    return issues;
  }

  /// Détecte les noms d'entités dupliqués
  static List<NormalizationIssue> _checkDuplicateNames(Mcd mcd) {
    final issues = <NormalizationIssue>[];

    // Vérifier les entités
    final entityNames = <String, int>{};
    for (final entity in mcd.entities) {
      entityNames[entity.name] = (entityNames[entity.name] ?? 0) + 1;
    }

    for (final entry in entityNames.entries) {
      if (entry.value > 1) {
        issues.add(
          NormalizationIssue(
            title: 'Noms d\'entités dupliqués',
            description:
                'Le nom "${entry.key}" est utilisé ${entry.value} fois pour des entités différentes.',
            severity: IssueSeverity.error,
            suggestion:
                'Renommez les entités pour avoir des noms uniques. Utilisez des suffixes descriptifs si nécessaire.',
          ),
        );
      }
    }

    // Vérifier les relations
    final relationNames = <String, int>{};
    for (final relation in mcd.relations) {
      relationNames[relation.name] = (relationNames[relation.name] ?? 0) + 1;
    }

    for (final entry in relationNames.entries) {
      if (entry.value > 1) {
        issues.add(
          NormalizationIssue(
            title: 'Noms d\'associations dupliqués',
            description:
                'Le nom "${entry.key}" est utilisé ${entry.value} fois pour des associations différentes.',
            severity: IssueSeverity.warning,
            suggestion:
                'Renommez les associations pour avoir des noms uniques et descriptifs.',
          ),
        );
      }
    }

    return issues;
  }

  /// Vérifie la qualité des identifiants (entités, relations, attributs)
  static List<NormalizationIssue> _checkIdentifierQuality(Mcd mcd) {
    final issues = <NormalizationIssue>[];

    for (final entity in mcd.entities) {
      final name = entity.name.trim();
      if (name.isEmpty) {
        issues.add(
          NormalizationIssue(
            title: 'Entité sans nom',
            description: 'Une entité n\'a pas de nom.',
            severity: IssueSeverity.error,
            affectedEntityId: entity.id,
            suggestion: 'Donnez un nom descriptif à l\'entité.',
          ),
        );
      } else {
        if (SqlUtils.isReserved(name)) {
          issues.add(
            NormalizationIssue(
              title: 'Nom d\'entité réservé SQL',
              description: 'L\'entité "$name" utilise un mot réservé SQL.',
              severity: IssueSeverity.warning,
              affectedEntityId: entity.id,
              suggestion:
                  'Renommez l\'entité (ex: ajoutez un suffixe) pour éviter les problèmes SQL.',
            ),
          );
        }
        if (!SqlUtils.isSimpleIdentifier(name)) {
          issues.add(
            NormalizationIssue(
              title: 'Nom d\'entité non standard',
              description:
                  'Le nom "$name" contient des caractères spéciaux/espaces (il devra être quoté en SQL).',
              severity: IssueSeverity.info,
              affectedEntityId: entity.id,
              suggestion:
                  'Utilisez un format type SNAKE_CASE (lettres/chiffres/_) pour simplifier la génération.',
            ),
          );
        }
      }

      for (final attr in entity.attributes) {
        final attrName = attr.name.trim();
        if (attrName.isNotEmpty && !SqlUtils.isSimpleIdentifier(attrName)) {
          issues.add(
            NormalizationIssue(
              title: 'Nom d\'attribut non standard',
              description:
                  'L\'attribut "${attr.name}" de "$name" contient des caractères spéciaux/espaces.',
              severity: IssueSeverity.info,
              affectedEntityId: entity.id,
              suggestion:
                  'Utilisez un format simple (ex: snake_case) pour éviter le quoting partout.',
            ),
          );
        }
      }
    }

    for (final relation in mcd.relations) {
      final name = relation.name.trim();
      if (name.isEmpty) {
        issues.add(
          NormalizationIssue(
            title: 'Association sans nom',
            description: 'Une association n\'a pas de nom.',
            severity: IssueSeverity.error,
            suggestion: 'Donnez un nom descriptif à l\'association.',
          ),
        );
      } else {
        if (SqlUtils.isReserved(name)) {
          issues.add(
            NormalizationIssue(
              title: 'Nom d\'association réservé SQL',
              description: 'L\'association "$name" utilise un mot réservé SQL.',
              severity: IssueSeverity.warning,
              suggestion:
                  'Renommez l\'association pour éviter les problèmes de génération SQL.',
            ),
          );
        }
        if (!SqlUtils.isSimpleIdentifier(name)) {
          issues.add(
            NormalizationIssue(
              title: 'Nom d\'association non standard',
              description:
                  'Le nom "$name" contient des caractères spéciaux/espaces (il devra être quoté en SQL).',
              severity: IssueSeverity.info,
              suggestion:
                  'Utilisez un format type SNAKE_CASE (lettres/chiffres/_) pour simplifier la génération.',
            ),
          );
        }
      }
    }

    return issues;
  }

  /// Vérifie les types d'attributs
  static List<NormalizationIssue> _checkAttributeTypes(Mcd mcd) {
    final issues = <NormalizationIssue>[];

    for (final entity in mcd.entities) {
      for (final attr in entity.attributes) {
        // Vérifier si le type est générique
        final rawType = attr.type;
        final canon = SqlUtils.canonicalType(rawType);
        if (canon == 'string') {
          issues.add(
            NormalizationIssue(
              title: 'Type d\'attribut générique',
              description:
                  'L\'attribut "${attr.name}" de "${entity.name}" utilise un type générique (chaine/string).',
              severity: IssueSeverity.info,
              affectedEntityId: entity.id,
              suggestion:
                  'Spécifiez un type plus précis selon la nature de la donnée : Entier, Date, Booleen, Texte, etc.',
            ),
          );
        }

        // Vérifier les noms d'attributs vides
        if (attr.name.trim().isEmpty) {
          issues.add(
            NormalizationIssue(
              title: 'Attribut sans nom',
              description: 'Un attribut de "${entity.name}" n\'a pas de nom.',
              severity: IssueSeverity.error,
              affectedEntityId: entity.id,
              suggestion: 'Donnez un nom descriptif à cet attribut.',
            ),
          );
        }

        // Noms réservés SQL (warning)
        if (attr.name.trim().isNotEmpty && SqlUtils.isReserved(attr.name)) {
          issues.add(
            NormalizationIssue(
              title: 'Nom d\'attribut réservé SQL',
              description:
                  'L\'attribut "${attr.name}" de "${entity.name}" utilise un mot réservé SQL.',
              severity: IssueSeverity.warning,
              affectedEntityId: entity.id,
              suggestion:
                  'Renommez cet attribut (ex: ajoutez un suffixe) pour éviter les problèmes de génération SQL.',
            ),
          );
        }
      }
    }

    return issues;
  }

  /// Détecte les entités isolées (sans liens)
  static List<NormalizationIssue> _checkIsolatedEntities(Mcd mcd) {
    final issues = <NormalizationIssue>[];

    for (final entity in mcd.entities) {
      final hasLinks = mcd.links.any((l) => l.entityId == entity.id);

      if (!hasLinks && mcd.entities.length > 1) {
        issues.add(
          NormalizationIssue(
            title: 'Entité isolée',
            description:
                'L\'entité "${entity.name}" n\'est liée à aucune association.',
            severity: IssueSeverity.warning,
            affectedEntityId: entity.id,
            suggestion:
                'Créez des associations avec d\'autres entités ou supprimez cette entité si elle n\'est pas nécessaire dans le modèle.',
          ),
        );
      }
    }

    return issues;
  }

  /// Vérifie les associations
  static List<NormalizationIssue> _checkRelations(Mcd mcd) {
    final issues = <NormalizationIssue>[];

    for (final relation in mcd.relations) {
      final connectedLinks = mcd.links
          .where((l) => l.relationId == relation.id)
          .toList();

      // Une association doit avoir au moins 2 entités liées
      if (connectedLinks.isEmpty) {
        issues.add(
          NormalizationIssue(
            title: 'Association sans lien',
            description:
                'L\'association "${relation.name}" n\'est liée à aucune entité.',
            severity: IssueSeverity.error,
            suggestion:
                'Créez des liens entre cette association et au moins 2 entités, ou supprimez-la.',
          ),
        );
      } else if (connectedLinks.length == 1) {
        issues.add(
          NormalizationIssue(
            title: 'Association incomplète',
            description:
                'L\'association "${relation.name}" n\'est liée qu\'à une seule entité.',
            severity: IssueSeverity.error,
            suggestion:
                'Une association doit relier au moins 2 entités. Ajoutez un lien vers une autre entité.',
          ),
        );
      }

      // Vérifier les cardinalités
      for (final link in connectedLinks) {
        if (link.cardinalities.isEmpty ||
            !_isValidCardinality(link.cardinalities)) {
          issues.add(
            NormalizationIssue(
              title: 'Cardinalité invalide',
              description:
                  'Le lien de l\'association "${relation.name}" a une cardinalité invalide : "${link.cardinalities}".',
              severity: IssueSeverity.warning,
              suggestion:
                  'Utilisez des cardinalités valides : 0,1 / 1,1 / 0,n / 1,n',
            ),
          );
        }
      }
    }

    return issues;
  }

  /// Détecte les attributs avec des noms similaires
  static List<NormalizationIssue> _checkDuplicateAttributes(Mcd mcd) {
    final issues = <NormalizationIssue>[];

    for (final entity in mcd.entities) {
      final attrNames = <String, int>{};

      for (final attr in entity.attributes) {
        final name = attr.name.toLowerCase();
        attrNames[name] = (attrNames[name] ?? 0) + 1;
      }

      for (final entry in attrNames.entries) {
        if (entry.value > 1) {
          issues.add(
            NormalizationIssue(
              title: 'Attributs dupliqués',
              description:
                  'L\'entité "${entity.name}" a ${entry.value} attributs nommés "${entry.key}".',
              severity: IssueSeverity.error,
              affectedEntityId: entity.id,
              suggestion:
                  'Renommez ou supprimez les attributs en double pour éviter les ambiguïtés.',
            ),
          );
        }
      }
    }

    return issues;
  }

  /// Vérifie si une cardinalité est valide
  static bool _isValidCardinality(String cardinality) {
    final valid = ['0,1', '1,1', '0,n', '1,n', '0,N', '1,N'];
    return valid.contains(cardinality);
  }
}
