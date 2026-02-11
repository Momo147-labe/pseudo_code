/// Bibliothèque de templates réutilisables pour les prompts AI
class PromptTemplates {
  /// Template pour code review
  static String codeReview(String code) {
    return '''
**MISSION : CODE REVIEW COMPLET**

Analyse le pseudocode suivant et fournis un rapport détaillé :

\`\`\`
$code
\`\`\`

**Critères d'évaluation :**
1. **Syntaxe** : Respect des règles de syntaxe pseudocode
2. **Logique** : Cohérence algorithmique et absence d'erreurs logiques
3. **Complexité** : Analyse de la complexité temporelle et spatiale
4. **Lisibilité** : Clarté du code et des noms de variables
5. **Optimisation** : Suggestions d'amélioration

**Format de réponse :**
- Score global : X/100
- Points forts : [liste]
- Points à améliorer : [liste]
- Bugs détectés : [liste avec ligne]
- Suggestions d'optimisation : [liste]
''';
  }

  /// Template pour détection de bugs
  static String bugDetection(String code) {
    return '''
**MISSION : DÉTECTION DE BUGS**

Analyse ce pseudocode et identifie TOUS les bugs potentiels :

\`\`\`
$code
\`\`\`

**Types de bugs à rechercher :**
- Erreurs de syntaxe
- Boucles infinies
- Divisions par zéro
- Accès hors limites (tableaux)
- Variables non initialisées
- Conditions toujours vraies/fausses
- Erreurs de logique

**Format de réponse :**
Pour chaque bug :
- Ligne X : [Type de bug]
  - Problème : [description]
  - Impact : [gravité]
  - Correction suggérée : [code corrigé]
''';
  }

  /// Template pour optimisation
  static String optimization(String code) {
    return '''
**MISSION : OPTIMISATION DU CODE**

Optimise ce pseudocode pour améliorer ses performances :

\`\`\`
$code
\`\`\`

**Axes d'optimisation :**
1. Complexité algorithmique (réduire O(n²) → O(n log n), etc.)
2. Utilisation mémoire
3. Nombre d'opérations
4. Structures de données plus adaptées

**Format de réponse :**
- Complexité actuelle : O(...)
- Complexité optimisée : O(...)
- Modifications proposées : [liste]
- Code optimisé : [REPLACER_CODE] avec le code amélioré
''';
  }

  /// Template pour explication
  static String explanation(String code) {
    return '''
**MISSION : EXPLICATION PÉDAGOGIQUE**

Explique ce pseudocode de manière claire et pédagogique :

\`\`\`
$code
\`\`\`

**Structure de l'explication :**
1. **Objectif** : Que fait cet algorithme ?
2. **Étapes** : Décomposition ligne par ligne des parties importantes
3. **Exemple** : Trace d'exécution avec des valeurs concrètes
4. **Complexité** : Analyse de performance
5. **Cas d'usage** : Quand utiliser cet algorithme ?
''';
  }

  /// Template pour traduction vers un langage
  static String translation(String code, String targetLanguage) {
    return '''
**MISSION : TRADUCTION VERS $targetLanguage**

Traduis ce pseudocode vers $targetLanguage :

\`\`\`
$code
\`\`\`

**Règles de traduction :**
- Respecter les conventions de $targetLanguage
- Ajouter les imports nécessaires
- Utiliser les structures de données idiomatiques
- Ajouter des commentaires explicatifs
- Code complet et exécutable

**Format de réponse :**
\`\`\`$targetLanguage
[code traduit]
\`\`\`
''';
  }

  /// Template pour génération de tests
  static String testGeneration(String code) {
    return '''
**MISSION : GÉNÉRATION DE TESTS**

Génère des cas de test pour ce pseudocode :

\`\`\`
$code
\`\`\`

**Types de tests à générer :**
1. **Cas normaux** : Entrées valides typiques
2. **Cas limites** : Valeurs min/max, tableaux vides, etc.
3. **Cas d'erreur** : Entrées invalides

**Format de réponse :**
Pour chaque test :
- Test N : [description]
  - Entrée : [valeurs]
  - Sortie attendue : [résultat]
  - Justification : [pourquoi ce test est important]
''';
  }

  /// Template pour suggestion de structure de données
  static String dataStructureSuggestion(String problem) {
    return '''
**MISSION : SUGGESTION DE STRUCTURE DE DONNÉES**

Problème à résoudre :
$problem

**Analyse demandée :**
1. Structures de données possibles
2. Avantages et inconvénients de chaque structure
3. Complexité des opérations principales
4. Recommandation finale avec justification

**Format de réponse :**
- Structure 1 : [nom]
  - Avantages : [liste]
  - Inconvénients : [liste]
  - Complexité : [O(...)]
  
- Recommandation : [structure choisie]
  - Justification : [explication]
''';
  }

  /// Template pour amélioration de lisibilité
  static String readabilityImprovement(String code) {
    return '''
**MISSION : AMÉLIORATION DE LA LISIBILITÉ**

Améliore la lisibilité de ce code :

\`\`\`
$code
\`\`\`

**Aspects à améliorer :**
- Noms de variables plus explicites
- Commentaires pertinents
- Découpage en fonctions/procédures
- Indentation et espacement
- Suppression du code redondant

**Format de réponse :**
[REPLACER_CODE] avec le code amélioré
Puis liste des améliorations apportées
''';
  }
}
