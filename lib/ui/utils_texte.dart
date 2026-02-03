String motCourant(String texte, int position) {
  int start = position;
  while (start > 0 && texte[start - 1].trim().isNotEmpty) {
    start--;
  }
  return texte.substring(start, position);
}

int debutMot(String texte, int position) {
  int start = position;
  while (start > 0 && texte[start - 1].trim().isNotEmpty) {
    start--;
  }
  return start;
}
