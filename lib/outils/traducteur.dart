import 'traducteur_python.dart';
import 'traducteur_c.dart';
import 'traducteur_js.dart';

/// Point d'entrée unique pour la traduction de pseudo-code.
/// Délègue vers le traducteur spécifique à chaque langage.
///
/// Langages supportés : 'python', 'c', 'javascript' (ou 'js')
class Traducteur {
  static String traduire(String code, String langage) {
    if (code.trim().isEmpty) return '';
    final lignes = code.split('\n');

    switch (langage.toLowerCase()) {
      case 'python':
        return TraducteurPython.traduire(lignes);
      case 'c':
        return TraducteurC.traduire(lignes);
      case 'javascript':
      case 'js':
        return TraducteurJS.traduire(lignes);
      default:
        return code;
    }
  }
}
