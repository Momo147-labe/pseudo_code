import 'package:pseudo_code/interpreteur/environnement.dart';
import 'package:pseudo_code/interpreteur/evaluateur_expression.dart';
import 'package:pseudo_code/interpreteur/blocs/fonctions.dart';
import 'package:pseudo_code/interpreteur/interpreteur.dart';
import 'package:pseudo_code/providers/debug_provider.dart';

// Import des nouveaux handlers
import 'package:pseudo_code/interpreteur/executeurs/io_handler.dart';
import 'package:pseudo_code/interpreteur/executeurs/affectation_handler.dart';
import 'package:pseudo_code/interpreteur/executeurs/appel_handler.dart';

class Executeur {
  final Environnement env;
  final DebugProvider provider;
  final Future<String> Function() onInput;
  final Function(String) onOutput;
  late final EvaluateurExpression _evaluateur;
  dynamic _resultatRetour;

  // Handlers spécialisés
  late final IOHandler _ioHandler;
  late final AffectationHandler _affectationHandler;
  late final AppelHandler _appelHandler;

  Executeur(
    this.env, {
    required this.provider,
    required this.onInput,
    required this.onOutput,
  }) {
    _evaluateur = EvaluateurExpression(
      env,
      onAppelFonction: (nom, args) async {
        final fonction = env.chercherFonction(nom);
        if (fonction != null) {
          return await executerSousProgramme(fonction, args);
        }
        throw Exception("Fonction '$nom' non définie.");
      },
    );

    // Initialisation des handlers
    _ioHandler = IOHandler(env: env, evaluateur: _evaluateur, onInput: onInput);
    _affectationHandler = AffectationHandler(env: env, evaluateur: _evaluateur);
    _appelHandler = AppelHandler(
      env: env,
      executerSousProgramme: executerSousProgramme,
    );
  }

  Future<bool> evaluerBooleen(String exp) async {
    final result = await _evaluateur.evaluer(exp);
    if (result is! bool)
      throw Exception("L'expression '$exp' n'est pas un booléen.");
    return result;
  }

  Future<dynamic> evaluer(String exp) async => await _evaluateur.evaluer(exp);

  Future<String> executerLigne(String ligne) async {
    ligne = ligne.trim();
    if (ligne.endsWith(';')) {
      ligne = ligne.substring(0, ligne.length - 1).trim();
    }
    if (ligne.isEmpty) return "";

    // Retourner (gestion du retour de fonction)
    if (ligne.toLowerCase().startsWith('retourner ')) {
      final exp = ligne.substring(10).trim();
      _resultatRetour = await _evaluateur.evaluer(exp);
      return "__RETURN__";
    }

    // Délégation aux handlers spécialisés

    // 1. Lecture (Lire)
    if (ligne.toLowerCase().startsWith('lire')) {
      await _ioHandler.executerLire(ligne);
      return "";
    }

    // 2. Affichage de tableau (Afficher_Table)
    if (ligne.toLowerCase().startsWith('afficher_table')) {
      return await _ioHandler.executerAfficherTable(ligne);
    }

    // 3. Affichage 2D (Afficher2D)
    if (ligne.toLowerCase().startsWith('afficher2d')) {
      return await _ioHandler.executerAfficher2D(ligne);
    }

    // 4. Affichage Structure (AfficherTabStructure)
    if (ligne.toLowerCase().startsWith('affichertabstructure')) {
      return await _ioHandler.executerAfficherTabStructure(ligne);
    }

    // 5. Affichage (Afficher/Ecrire)
    if (ligne.toLowerCase().startsWith('afficher') ||
        ligne.toLowerCase().startsWith('ecrire')) {
      return await _ioHandler.executerAfficher(ligne);
    }

    // 6. Effacer l'écran (Effacer)
    if (ligne.toLowerCase() == 'effacer') {
      return _ioHandler.executerEffacer(ligne);
    }

    // 4. Appels de procédures/fonctions
    if (_appelHandler.estAppel(ligne)) {
      await _appelHandler.executerAppel(ligne);
      return "";
    }

    // 5. Affectations de tableaux
    if (_affectationHandler.estAffectationTableau(ligne)) {
      await _affectationHandler.executerAffectationTableau(ligne);
      return "";
    }

    // 6. Affectations simples et de structures
    if (_affectationHandler.estAffectation(ligne)) {
      await _affectationHandler.executerAffectation(ligne);
      return "";
    }

    return "";
  }

  Future<dynamic> executerSousProgramme(
    SousProgramme sp,
    List<String> argumentsExps,
  ) async {
    final valeurs = <dynamic>[];
    for (final exp in argumentsExps) {
      valeurs.add(await _evaluateur.evaluer(exp));
    }

    final envLocal = Environnement(parent: env);
    if (valeurs.length != sp.parametres.length) {
      throw Exception("Arguments invalides pour '${sp.nom}'.");
    }
    for (int i = 0; i < sp.parametres.length; i++) {
      envLocal.declarer(
        sp.parametres[i].nom,
        valeurs[i],
        sp.parametres[i].type,
      );
    }

    // Gestion de la variable de retour implicite (nom de la fonction)
    if (sp is PseudoFonction) {
      // On déclare une variable locale du même nom que la fonction
      // Initialisée avec une valeur par défaut selon le type
      dynamic valeurInit;
      if (sp.typeRetour.toLowerCase() == 'entier')
        valeurInit = 0;
      else if (sp.typeRetour.toLowerCase() == 'réel' ||
          sp.typeRetour.toLowerCase() == 'reel')
        valeurInit = 0.0;
      else if (sp.typeRetour.toLowerCase() == 'chaine')
        valeurInit = "";
      else if (sp.typeRetour.toLowerCase() == 'booleen')
        valeurInit = false;

      envLocal.declarer(sp.nom, valeurInit, sp.typeRetour);
    }

    final execLocal = Executeur(
      envLocal,
      provider: provider,
      onInput: onInput,
      onOutput: onOutput,
    );

    final result = await Interpreteur.boucleExecution(
      lignes: sp.lignes,
      exec: execLocal,
      env: envLocal,
      provider: provider,
      onOutput: onOutput,
      startIndex: 0,
      baseOffset: sp.offset,
      dansVariables: false, // Will be set by 'variables' keyword
      dansDebut: false, // Will be set by 'début' keyword
    );

    if (result == "__RETURN__") return execLocal._resultatRetour;

    // Si on sort sans '__RETURN__', on vérifie si la variable du nom de la fonction a été modifiée
    if (sp is PseudoFonction) {
      return envLocal.lire(sp.nom);
    }

    return null;
  }
}
