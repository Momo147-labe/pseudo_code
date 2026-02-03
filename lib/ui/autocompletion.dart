const List<String> motsCles = [
  'Variables',
  'Début',
  'Fin',
  'si',
  'alors',
  'sinon',
  'pour',
  'tantque',
  'faire',
  'lire',
  'afficher',
  'ecrire',
];

const List<String> types = [
  'entier',
  'réel',
  'chaine',
  'booléen',
  'caractère',
  'tableau',
];

List<String> suggestions(String mot, List<String> variables) {
  final List<String> all = [...motsCles, ...types, ...variables];

  return all
      .where((s) => s.toLowerCase().startsWith(mot.toLowerCase()))
      .toList();
}
