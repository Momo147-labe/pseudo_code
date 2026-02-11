import 'package:pseudo_code/interpreteur/environnement.dart';
import 'package:pseudo_code/interpreteur/blocs/fonctions.dart';
import 'package:pseudo_code/interpreteur/utils.dart';

/// Gestionnaire des appels de fonctions et procédures
class AppelHandler {
  final Environnement env;
  final Future<dynamic> Function(SousProgramme, List<String>)
  executerSousProgramme;

  AppelHandler({required this.env, required this.executerSousProgramme});

  /// Gère l'appel d'une procédure ou fonction
  Future<void> executerAppel(String ligne) async {
    final appelMatch = GestionnaireFonctions.regAppel.firstMatch(ligne);
    if (appelMatch == null) return;

    final nom = appelMatch.group(1)!;
    final argsStr = appelMatch.group(2)!;
    final args = InterpreteurUtils.splitArguments(argsStr);

    // Chercher d'abord une procédure
    final proc = env.chercherProcedure(nom);
    if (proc != null) {
      await executerSousProgramme(proc, args);
      return;
    }

    // Sinon chercher une fonction (appelée comme procédure)
    final func = env.chercherFonction(nom);
    if (func != null) {
      await executerSousProgramme(func, args);
      return;
    }

    throw Exception("Procédure ou fonction '$nom' non trouvée.");
  }

  /// Vérifie si une ligne est un appel de procédure/fonction
  bool estAppel(String ligne) {
    return GestionnaireFonctions.regAppel.hasMatch(ligne);
  }
}
