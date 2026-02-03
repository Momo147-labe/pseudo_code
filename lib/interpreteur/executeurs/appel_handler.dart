import 'package:pseudo_code/interpreteur/environnement.dart';
import 'package:pseudo_code/interpreteur/blocs/fonctions.dart';

/// Gestionnaire des appels de fonctions et procédures
class AppelHandler {
  final Environnement env;
  final Future<dynamic> Function(SousProgramme, List<String>)
  executerSousProgramme;

  AppelHandler({required this.env, required this.executerSousProgramme});

  /// Extrait les arguments d'une liste séparée par des virgules
  List<String> _extraireArguments(String argsBruts) {
    final args = <String>[];
    String courant = "";
    bool dansChaine = false;
    int parenStack = 0;

    for (var i = 0; i < argsBruts.length; i++) {
      final char = argsBruts[i];
      if (char == '"') dansChaine = !dansChaine;
      if (!dansChaine) {
        if (char == '(') parenStack++;
        if (char == ')') parenStack--;
      }
      if (char == ',' && !dansChaine && parenStack == 0) {
        args.add(courant.trim());
        courant = "";
      } else {
        courant += char;
      }
    }
    if (courant.isNotEmpty) args.add(courant.trim());
    return args;
  }

  /// Gère l'appel d'une procédure ou fonction
  Future<void> executerAppel(String ligne) async {
    final appelMatch = GestionnaireFonctions.regAppel.firstMatch(ligne);
    if (appelMatch == null) return;

    final nom = appelMatch.group(1)!;
    final argsStr = appelMatch.group(2)!;
    final args = _extraireArguments(argsStr);

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
