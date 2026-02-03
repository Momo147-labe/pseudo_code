class MotsCles {
  static const List<String> structure = [
    'Algorithme',
    'Variables',
    'Début',
    'Fin',
    'variables',
    'type',
    'structure',
    'finstructure',
    'const',
    'Const',
    'CONST',
  ];

  static const List<String> controle = [
    'si',
    'alors',
    'sinon',
    'finsi',
    'pour',
    'finpour',
    'fpour',
    'tantque',
    'fintantque',
    'faire',
    'de',
    'à',
    'selon',
    'cas',
    'finselon',
    'repeter',
    'jusqua',
    'fonction',
    'finfonction',
    'procedure',
    'finprocedure',
    'retourner',
  ];

  static const List<String> io = [
    'lire',
    'afficher',
    'afficher_table',
    'afficher2D',
    'Afficher2D',
    'afficherTabStructure',
    'AfficherTabStructure',
    'effacer',
  ];

  static const List<String> logiques = ['et', 'ou', 'non'];

  static const List<String> maths = ['racine_carree', 'abs', 'div', 'mod'];

  static const List<String> types = [
    'entier',
    'réel',
    'reel',
    'chaine',
    'booleen',
    'tableau',
  ];

  static const List<String> constantes = ['Vrai', 'vrai', 'Faux', 'faux'];

  static const Map<String, String> descriptions = {
    'si': 'Structure conditionnelle : Si (condition) Alors ... FinSi',
    'pour':
        'Boucle itérative : Pour (variable) de (début) à (fin) Faire ... FinPour',
    'tantque':
        'Boucle conditionnelle : Tantque (condition) Faire ... FinTantQue',
    'afficher': 'Affiche une ou plusieurs valeurs dans la console.',
    'lire': 'Attend une saisie utilisateur et l\'enregistre dans une variable.',
    'const': 'Déclare une constante qui ne peut pas être modifiée.',
    'tableau': 'Stocke une liste ordonnée d\'éléments de même type.',
    'structure': 'Définit un type complexe regroupant plusieurs champs.',
    'effacer': 'Efface tout le contenu de la console.',
  };

  static List<String> get tous => [
    ...structure,
    ...controle,
    ...io,
    ...logiques,
    ...maths,
    ...types,
    ...constantes,
  ];

  static bool estUnMotCle(String word) {
    final lowerWord = word.toLowerCase();
    return tous.any((kw) => kw.toLowerCase() == lowerWord);
  }
}
