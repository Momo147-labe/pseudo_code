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
    'a',
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
    'ecrire',
    'afficher_table',
    'ecrire_table',
    'afficher2D',
    'ecrire2D',
    'Afficher2D',
    'afficherTabStructure',
    'ecrireTabStructure',
    'AfficherTabStructure',
    'effacer',
  ];

  static const List<String> logiques = ['et', 'ou', 'non'];

  static const List<String> maths = ['racine_carree', 'div', 'mod'];

  static const List<String> types = [
    'entier',
    'réel',
    'reel',
    'chaine',
    'booleen',
    'tableau',
  ];

  static const List<String> natives = [
    'long',
    'maj',
    'minus',
    'car',
    'racine',
    'abs',
    'hasard',
    'arrondi',
    'tronque',
    'en_entier',
    'en_reel',
    'en_chaine',
    'typevar',
    'est_numerique',
  ];

  static const List<String> constantes = ['Vrai', 'vrai', 'Faux', 'faux'];

  static const Map<String, Map<String, String>> metadata = {
    'finstructure': {
      'desc': 'Marque la fin de la déclaration d\'une structure personnalisée.',
      'syntax': 'FinStructure',
      'icon': 'stop',
      'label': 'Structure',
    },
    'const': {
      'desc': 'Déclare une donnée constante dont la valeur ne changera pas.',
      'syntax': 'Const PI = 3.14',
      'icon': 'lock',
      'label': 'Déclaration',
    },
    'si': {
      'desc': 'Exécute un bloc d\'instructions si une condition est remplie.',
      'syntax': 'Si (condition) Alors\n  // instructions\nFinSi',
      'icon': 'help_outline',
      'label': 'Contrôle',
    },
    'alors': {
      'desc': 'Mot-clé qui suit la condition dans une structure "Si".',
      'syntax': 'Si (condition) Alors',
      'icon': 'arrow_forward',
      'label': 'Contrôle',
    },
    'sinon': {
      'desc': 'Exécute un bloc alternatif si la condition "Si" est fausse.',
      'syntax': 'Sinon\n  // instructions',
      'icon': 'alt_route',
      'label': 'Contrôle',
    },
    'finsi': {
      'desc': 'Marque la fin d\'un bloc "Si".',
      'syntax': 'FinSi',
      'icon': 'stop',
      'label': 'Contrôle',
    },
    'pour': {
      'desc': 'Répète un bloc pour une plage de valeurs donnée.',
      'syntax': 'Pour i de 1 à 10 Faire\n  // instructions\nFinPour',
      'icon': 'loop',
      'label': 'Boucle',
    },
    'finpour': {
      'desc': 'Marque la fin d\'une boucle "Pour".',
      'syntax': 'FinPour',
      'icon': 'stop',
      'label': 'Boucle',
    },
    'fpour': {
      'desc': 'Raccourci pour marquer la fin d\'une boucle "Pour".',
      'syntax': 'FPour',
      'icon': 'stop',
      'label': 'Boucle',
    },
    'tantque': {
      'desc': 'Répète un bloc tant qu\'une condition est vraie.',
      'syntax': 'TantQue (condition) Faire\n  // instructions\nFinTantQue',
      'icon': 'sync',
      'label': 'Boucle',
    },
    'fintantque': {
      'desc': 'Marque la fin d\'une boucle "TantQue".',
      'syntax': 'FinTantQue',
      'icon': 'stop',
      'label': 'Boucle',
    },
    'faire': {
      'desc':
          'Mot-clé de début des instructions d\'une boucle "Pour" ou "TantQue".',
      'syntax': 'Faire\n  // instructions',
      'icon': 'play_arrow',
      'label': 'Boucle',
    },
    'de': {
      'desc': 'Définit la borne initiale d\'une boucle "Pour".',
      'syntax': 'Pour i de 1',
      'icon': 'start',
      'label': 'Boucle',
    },
    'à': {
      'desc': 'Définit la borne finale d\'une boucle "Pour".',
      'syntax': 'Pour i de 1 à 10',
      'icon': 'keyboard_tab',
      'label': 'Boucle',
    },
    'a': {
      'desc': 'Alias pour "à" (borne finale).',
      'syntax': 'Pour i de 1 a 10',
      'icon': 'keyboard_tab',
      'label': 'Boucle',
    },
    'selon': {
      'desc': 'Teste la valeur d\'une variable contre plusieurs cas.',
      'syntax': 'Selon variable Faire\n  cas valeur:',
      'icon': 'call_split',
      'label': 'Contrôle',
    },
    'cas': {
      'desc': 'Un cas spécifique dans une structure "Selon".',
      'syntax': 'Cas 1: \n  // instructions',
      'icon': 'check_box',
      'label': 'Contrôle',
    },
    'finselon': {
      'desc': 'Marque la fin d\'une structure "Selon".',
      'syntax': 'FinSelon',
      'icon': 'stop',
      'label': 'Contrôle',
    },
    'repeter': {
      'desc': 'Débute une boucle s\'exécutant au moins une fois.',
      'syntax': 'Répéter\n  // instructions\nJusquà (condition)',
      'icon': 'replay',
      'label': 'Boucle',
    },
    'jusqua': {
      'desc': 'Condition de fin (inversée) d\'une boucle "Répéter".',
      'syntax': 'Jusqu\'à (condition)',
      'icon': 'flag',
      'label': 'Boucle',
    },
    'algorithme': {
      'desc': 'Définit le début et le nom du programme principal.',
      'syntax': 'Algorithme MonProgramme',
      'icon': 'terminal',
      'label': 'Structure',
    },
    'variables': {
      'desc': 'Section dédiée à la déclaration des variables.',
      'syntax': 'Variables\n  nom : type',
      'icon': 'analytics',
      'label': 'Déclaration',
    },
    'type': {
      'desc':
          'Mot-clé générique pour introduire une déclaration de type/structure.',
      'syntax': 'Type nomType = Structure',
      'icon': 'settings',
      'label': 'Structure',
    },
    'début': {
      'desc': 'Marque le début effectif des instructions exécutables.',
      'syntax': 'Début\n  // instructions',
      'icon': 'play_circle_outline',
      'label': 'Structure',
    },
    'fin': {
      'desc': 'Marque la fin du programme ou d\'un bloc principal.',
      'syntax': 'Fin',
      'icon': 'stop_circle',
      'label': 'Structure',
    },
    'fonction': {
      'desc': 'Définit un sous-programme qui retourne une valeur.',
      'syntax': 'Fonction Nom(p1: type) : type_retour',
      'icon': 'functions',
      'label': 'Sous-programme',
    },
    'finfonction': {
      'desc': 'Marque la fin d\'une fonction.',
      'syntax': 'FinFonction',
      'icon': 'stop',
      'label': 'Sous-programme',
    },
    'procedure': {
      'desc': 'Définit un sous-programme sans valeur de retour.',
      'syntax': 'Procédure Nom(p1: type)',
      'icon': 'settings_suggest',
      'label': 'Sous-programme',
    },
    'finprocedure': {
      'desc': 'Marque la fin d\'une procédure.',
      'syntax': 'FinProcédure',
      'icon': 'stop',
      'label': 'Sous-programme',
    },
    'retourner': {
      'desc': 'Renvoie une valeur depuis une Fonction et arrête son exécution.',
      'syntax': 'Retourner valeur',
      'icon': 'keyboard_return',
      'label': 'Sous-programme',
    },
    'afficher': {
      'desc': 'Affiche des données dans la console de sortie.',
      'syntax': 'Afficher("Texte", variable)',
      'icon': 'output',
      'label': 'E/S',
    },
    'ecrire': {
      'desc': 'Alias de Afficher. Affiche des données dans la console.',
      'syntax': 'Ecrire("Texte", variable)',
      'icon': 'output',
      'label': 'E/S',
    },
    'afficher_table': {
      'desc': 'Affiche le contenu d\'un tableau à une dimension.',
      'syntax': 'Afficher_table(monTableau, taille)',
      'icon': 'view_list',
      'label': 'E/S',
    },
    'ecrire_table': {
      'desc': 'Alias de Afficher_table.',
      'syntax': 'Ecrire_table(monTableau, taille)',
      'icon': 'view_list',
      'label': 'E/S',
    },
    'afficher2d': {
      'desc': 'Affiche le contenu d\'un tableau à deux dimensions (matrice).',
      'syntax': 'Afficher2D(maMatrice, lignes, colonnes)',
      'icon': 'grid_on',
      'label': 'E/S',
    },
    'ecrire2d': {
      'desc': 'Alias de Afficher2D.',
      'syntax': 'Ecrire2D(maMatrice, lignes, colonnes)',
      'icon': 'grid_on',
      'label': 'E/S',
    },
    'affichertabstructure': {
      'desc': 'Affiche un tableau contenant des structures.',
      'syntax': 'AfficherTabStructure(monTabStruct, taille)',
      'icon': 'data_object',
      'label': 'E/S',
    },
    'ecriretabstructure': {
      'desc': 'Alias de AfficherTabStructure.',
      'syntax': 'EcrireTabStructure(monTabStruct, taille)',
      'icon': 'data_object',
      'label': 'E/S',
    },
    'effacer': {
      'desc': 'Efface le contenu de la console de sortie.',
      'syntax': 'Effacer()',
      'icon': 'clear_all',
      'label': 'E/S',
    },
    'lire': {
      'desc': 'Interrompt l\'exécution pour lire une saisie utilisateur.',
      'syntax': 'Lire(ma_variable)',
      'icon': 'input',
      'label': 'E/S',
    },
    'tableau': {
      'desc': 'Structure de donnée stockant plusieurs éléments de même type.',
      'syntax': 'tab : Tableau[1..10] de Entier',
      'icon': 'grid_on',
      'label': 'Type',
    },
    'structure': {
      'desc': 'Définit un type de donnée personnalisé avec plusieurs champs.',
      'syntax': 'Type T = Structure\n  champ : type\nFinStructure',
      'icon': 'bubble_chart',
      'label': 'Structure',
    },
    'entier': {
      'desc': 'Type de donnée numérique pour les nombres sans virgule.',
      'syntax': 'x : Entier',
      'icon': 'numbers',
      'label': 'Type',
    },
    'reel': {
      'desc': 'Type de donnée numérique pour les nombres à virgule.',
      'syntax': 'y : Réel',
      'icon': 'calculate',
      'label': 'Type',
    },
    'chaine': {
      'desc': 'Type de donnée pour les suites de caractères (texte).',
      'syntax': 's : Chaine',
      'icon': 'text_fields',
      'label': 'Type',
    },
    'booleen': {
      'desc': 'Type de donnée logique (Vrai ou Faux).',
      'syntax': 'b : Booleen',
      'icon': 'toggle_on',
      'label': 'Type',
    },
    'long': {
      'desc': 'Retourne la longueur (nombre de caractères) d\'une chaîne.',
      'syntax': 'l <- Long("texte")',
      'icon': 'straighten',
      'label': 'Native',
    },
    'maj': {
      'desc': 'Convertit une chaîne de caractères en majuscules.',
      'syntax': 'm <- Maj("texte")',
      'icon': 'keyboard_capslock',
      'label': 'Native',
    },
    'minus': {
      'desc': 'Convertit une chaîne de caractères en minuscules.',
      'syntax': 'm <- Minus("TEXTE")',
      'icon': 'keyboard_arrow_down',
      'label': 'Native',
    },
    'car': {
      'desc': 'Extrait le caractère à une position donnée dans une chaîne.',
      'syntax': 'c <- Car("texte", 2)',
      'icon': 'font_download',
      'label': 'Native',
    },
    'racine': {
      'desc': 'Calcule la racine carrée d\'un nombre.',
      'syntax': 'r <- Racine(16)',
      'icon': 'square_foot',
      'label': 'Native',
    },
    'abs': {
      'desc': 'Retourne la valeur absolue d\'un nombre.',
      'syntax': 'a <- Abs(-5)',
      'icon': 'exposure_zero',
      'label': 'Native',
    },
    'hasard': {
      'desc': 'Génère un entier aléatoire entre 0 et la borne moins un.',
      'syntax': 'h <- Hasard(10) // entre 0 et 9',
      'icon': 'casino',
      'label': 'Native',
    },
    'arrondi': {
      'desc': 'Arrondit un nombre réel à l\'entier le plus proche.',
      'syntax': 'a <- Arrondi(3.6) // Donne 4',
      'icon': 'exposure_plus_1',
      'label': 'Native',
    },
    'tronque': {
      'desc': 'Retourne la partie entière d\'un nombre réel (sans arrondi).',
      'syntax': 't <- Tronque(3.9) // Donne 3',
      'icon': 'content_cut',
      'label': 'Native',
    },
    'en_entier': {
      'desc': 'Convertit une chaîne de caractères en nombre entier.',
      'syntax': 'e <- En_entier("123")',
      'icon': 'onetwothree',
      'label': 'Native',
    },
    'en_reel': {
      'desc': 'Convertit une chaîne en nombre réel.',
      'syntax': 'r <- En_reel("3.14")',
      'icon': 'calculate',
      'label': 'Native',
    },
    'en_chaine': {
      'desc': 'Convertit un nombre en chaîne de caractères.',
      'syntax': 'c <- En_chaine(123)',
      'icon': 'abc',
      'label': 'Native',
    },
    'typevar': {
      'desc': 'Retourne le type d\'une variable sour forme de texte.',
      'syntax': 't <- Typevar(maVar)',
      'icon': 'category',
      'label': 'Native',
    },
    'est_numerique': {
      'desc': 'Vérifie si une chaîne contient uniquement des chiffres.',
      'syntax': 'b <- Est_numerique("123")',
      'icon': 'pin',
      'label': 'Native',
    },
  };

  static Map<String, String>? getMetadata(String word) {
    final lower = word.toLowerCase();
    // Normalisation pour les accents
    final normalized = lower == 'réel' ? 'reel' : lower;
    return metadata[normalized];
  }

  @Deprecated('Use metadata instead')
  static Map<String, String> get descriptions =>
      metadata.map((k, v) => MapEntry(k, v['desc']!));

  static List<String> get tous => [
    ...structure,
    ...controle,
    ...io,
    ...logiques,
    ...maths,
    ...types,
    ...natives,
    ...constantes,
  ];

  static bool estUnMotCle(String word) {
    final lowerWord = word.toLowerCase();
    return tous.any((kw) => kw.toLowerCase() == lowerWord);
  }
}
