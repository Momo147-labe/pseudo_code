import 'package:pseudo_code/interpreteur/environnement.dart';
import 'package:pseudo_code/interpreteur/executeur.dart';
import 'package:pseudo_code/interpreteur/navigateur_blocs.dart';
import 'package:pseudo_code/interpreteur/blocs/tableaux.dart';
import 'package:pseudo_code/interpreteur/validateur.dart';
import 'package:pseudo_code/interpreteur/pre_analyseur.dart';
import 'package:pseudo_code/providers/debug_provider.dart';

class Interpreteur {
  /// Signaux internes de sortie de boucle (remplacement des chaînes magiques)
  static const String _kRetour = '__RETURN__';
  static const String _kErreur = '__ERROR__';

  static final RegExp _regVars = RegExp(r'^variables\b', caseSensitive: false);
  static final RegExp _regDebut = RegExp(
    r'^début\b|^debut\b',
    caseSensitive: false,
  );
  static final RegExp _regFin = RegExp(r'^fin\b', caseSensitive: false);
  static final RegExp _regFinOnly = RegExp(r'^fin\s*$', caseSensitive: false);
  static final RegExp _siReg = RegExp(
    r'^si\s+(.*)\s+alors$',
    caseSensitive: false,
  );
  static final RegExp _sinonSiReg = RegExp(
    r'^sinon\s+si\s+(.*)\s+alors$',
    caseSensitive: false,
  );
  static final RegExp _selonReg = RegExp(
    r'^selon\s+(.*)\s+faire$',
    caseSensitive: false,
  );
  static final RegExp _tantqueReg = RegExp(
    r'^tantque\s+(.*)\s+faire$',
    caseSensitive: false,
  );
  static final RegExp _pourReg = RegExp(
    r'^pour\s+([a-zA-Z_]\w*)\s*(?:<-|de)\s*(.*)\s+(?:a|à)\s+(.*?)(?:\s+pas\s+(.*))?\s+faire$',
    caseSensitive: false,
  );
  static final RegExp _jusquaReg = RegExp(
    r'^jusqua\s+(.*)$',
    caseSensitive: false,
  );
  static final RegExp _casReg = RegExp(r'^cas\s+', caseSensitive: false);
  static final RegExp _sinonAutreReg = RegExp(
    r'^(?:sinon|autre)\s*(?::\s*)?$',
    caseSensitive: false,
  );

  static Future<void> executer(
    String code, {
    required DebugProvider provider,
    required Future<String> Function() onInput,
    required Function(String) onOutput,
  }) async {
    final lignes = code.split('\n');

    // 1. Validation de la structure avant tout
    final erreursStructure = ValidateurStructure.valider(lignes);
    if (erreursStructure.isNotEmpty) {
      // On souligne la première erreur structurelle qui a une ligne définie
      for (final e in erreursStructure) {
        if (e.line != null) {
          provider.setErrorLine(e.line);
          break;
        }
      }

      for (final e in erreursStructure) {
        onOutput("ERREUR STRUCTURELLE: ${e.message}");
      }
      return;
    }

    final env = Environnement();

    // 2. Pré-analyse (constantes, types, structures, fonctions)
    await PreAnalyseur.analyser(lignes, env, provider, onOutput);

    final exec = Executeur(
      env,
      provider: provider,
      onInput: onInput,
      onOutput: onOutput,
    );

    // Initialisation état débogage (Déjà fait au début, on garde pour la cohérence si appelé ailleurs)
    provider.setErrorLine(null);
    provider.setHighlightLine(null);
    provider.updateDebugVariables({});

    await boucleExecution(
      lignes: lignes,
      exec: exec,
      env: env,
      provider: provider,
      onOutput: onOutput,
    );

    // Nettoyage après exécution
    provider.setHighlightLine(null);
    provider.setPaused(false);
  }

  static Future<String?> boucleExecution({
    required List<String> lignes,
    required Executeur exec,
    required Environnement env,
    required DebugProvider provider,
    required Function(String) onOutput,
    int startIndex = 0,
    int baseOffset = 0,
    bool dansVariables = false,
    bool dansDebut = false,
    String? nomContexte,
  }) async {
    // Pile pour l'exécution dynamique
    final List<String> pileBlocs = [];
    // Cache pour figer les bornes et le pas des boucles "pour"
    final Map<int, Map<String, dynamic>> frozenLoops = {};
    // Cache pour éviter la recherche O(n) du début de boucle à chaque itération
    final Map<int, int> frozenWhileLoops =
        {}; // index fintantque -> index tantque
    final Map<int, int> frozenRepeatLoops = {}; // index jusqua -> index repeter

    int instructionCount = 0;
    int? derniereLigneSautee;
    for (int i = startIndex; i < lignes.length;) {
      instructionCount++;
      // Optimisation performance: ne pas tout ralentir en attendant à chaque ligne
      // On rafraîchit l'UI seulement toutes les 50 instructions
      if (instructionCount % 50 == 0) {
        await Future.delayed(Duration.zero);
      }

      String ligneFull = lignes[i];
      String ligne = ligneFull.trim();

      // Prise en compte du débogage avant nettoyage pour correspondre à l'affichage
      int indexInstruction = i;
      bool estUnSaut = (derniereLigneSautee == i);
      derniereLigneSautee = null;
      i++;

      if (ligne.isEmpty || ligne.startsWith('//')) continue;

      // Nettoyage pour l'exécution
      ligne = ligne.split('//')[0].trim();
      if (ligne.endsWith(';')) {
        ligne = ligne.substring(0, ligne.length - 1).trim();
      }

      // Sauter les constantes et types déjà traités en pré-analyse
      if (ligne.toLowerCase().startsWith('const ') ||
          ligne.toLowerCase().startsWith('type ')) {
        if (ligne.toLowerCase().contains('structure')) {
          i = NavigateurBlocs.trouverFinBlocCorrespondant(lignes, i, 'type', [
            'finstructure',
          ]);
        }
        continue;
      }

      if (_regVars.hasMatch(ligne) && !dansDebut) {
        dansVariables = true;
        continue;
      }
      final ligneLower = ligne.toLowerCase();
      if (_regDebut.hasMatch(ligne)) {
        dansVariables = false;
        dansDebut = true;
        continue;
      }
      if (_regFin.hasMatch(ligne)) {
        // On ne s'arrête que si c'est "fin" (Fin de l'algorithme)
        // et non un bloc spécifique (finsi, finpour, etc.)
        if (_regFinOnly.hasMatch(ligne) ||
            (ligneLower == 'fin' || ligneLower == 'fin.')) {
          provider.setHighlightLine(null);
          dansDebut = false;
          break;
        }
      }

      // --- LOGIQUE DE DÉBOGAGE ---
      if (dansDebut) {
        final currentLine = indexInstruction + baseOffset + 1;
        provider.setHighlightLine(currentLine);
        provider.updateDebugVariables(env.snapshot());

        // Vérifier point d'arrêt ou mode pas-à-pas
        bool hitBreakpoint = provider.breakpoints.contains(currentLine);
        if (hitBreakpoint || provider.isPaused) {
          provider.setPaused(true);
          // Attendre que l'utilisateur clique sur "Suivant" ou "Continuer"
          await provider.waitForNextStep();
        }
      }
      // ---------------------------

      // Sauter les définitions de fonctions et structures
      if (ligne.toLowerCase().startsWith('fonction') ||
          ligne.toLowerCase().startsWith('procedure')) {
        final typeBloc = ligne.split(' ')[0].toLowerCase();
        final keywordFin = ('fin' + typeBloc);
        i = NavigateurBlocs.trouverFinBlocCorrespondant(lignes, i, typeBloc, [
          keywordFin,
        ]);
        continue;
      }

      if (ligne.toLowerCase().startsWith('algorithme')) continue;

      if (dansVariables) {
        try {
          await traiterDeclarations(ligne, env, exec);
        } catch (e) {
          final errLine = indexInstruction + baseOffset + 1;
          onOutput("Erreur de déclaration à la ligne $errLine: $e");
          return "__ERROR__";
        }
      } else if (dansDebut) {
        try {
          final siMatch = _siReg.firstMatch(ligne);
          final sinonSiMatch = _sinonSiReg.firstMatch(ligne);
          final selonMatch = _selonReg.firstMatch(ligne);
          final tantqueMatch = _tantqueReg.firstMatch(ligne);
          final pourMatch = _pourReg.firstMatch(ligne);
          final jusquaMatch = _jusquaReg.firstMatch(ligne);

          if (siMatch != null) {
            pileBlocs.add('si');
            if (!(await exec.evaluerBooleen(siMatch.group(1)!))) {
              i = await NavigateurBlocs.sauterVersBrancheSuivante(lignes, i);
              derniereLigneSautee = i;
            }
          } else if (sinonSiMatch != null) {
            if (estUnSaut) {
              pileBlocs.add('si');
              if (!(await exec.evaluerBooleen(sinonSiMatch.group(1)!))) {
                i = await NavigateurBlocs.sauterVersBrancheSuivante(lignes, i);
                derniereLigneSautee = i;
              }
            } else {
              // On a déjà exécuté une branche, on saute tout le bloc sinon-si
              i = NavigateurBlocs.trouverFinBlocCorrespondant(lignes, i, 'si', [
                'finsi',
                'fin si',
              ]);
            }
          } else if (ligneLower.startsWith('sinon') ||
              ligneLower.startsWith('sinon:')) {
            if (estUnSaut) {
              // On est arrivé ici par saut, donc on exécute ce sinon (conceptuel,
              // en mode imbriqué 'sinon' ne fait rien de spécial, on continue)
              // Note: pileBlocs.add n'est pas nécessaire ici car pas de FinSi spécifique au Sinon seul
            } else {
              i = NavigateurBlocs.trouverFinBlocCorrespondant(lignes, i, 'si', [
                'finsi',
                'fin si',
              ]);
            }
          } else if (ligneLower.startsWith('finsi') ||
              ligneLower.startsWith('fin si')) {
            if (pileBlocs.isNotEmpty && pileBlocs.last == 'si')
              pileBlocs.removeLast();
          } else if (selonMatch != null) {
            pileBlocs.add('selon');
            final valCible = await exec.evaluer(selonMatch.group(1)!);
            i = await NavigateurBlocs.sauterVersCas(lignes, i, valCible, exec);
          } else if (pileBlocs.isNotEmpty &&
              pileBlocs.last == 'selon' &&
              (_casReg.hasMatch(ligne) || _sinonAutreReg.hasMatch(ligne))) {
            i = NavigateurBlocs.trouverFinBlocCorrespondant(
              lignes,
              i,
              'selon',
              ['finselon'],
            );
            pileBlocs.removeLast();
          } else if (ligneLower.startsWith('finselon') ||
              ligneLower.startsWith('fin selon')) {
            if (pileBlocs.isNotEmpty && pileBlocs.last == 'selon')
              pileBlocs.removeLast();
          } else if (tantqueMatch != null) {
            pileBlocs.add('tantque');
            if (!(await exec.evaluerBooleen(tantqueMatch.group(1)!))) {
              i = NavigateurBlocs.trouverFinBlocCorrespondant(
                lignes,
                i,
                'tantque',
                ['fintantque'],
              );
              pileBlocs.removeLast();
            }
          } else if (ligneLower.startsWith('fintantque') ||
              ligneLower.startsWith('fin tant que') ||
              ligneLower.startsWith('fintant que')) {
            if (pileBlocs.isNotEmpty && pileBlocs.last == 'tantque') {
              // Cache : évite une recherche O(n) à chaque itération
              final tantqueIdx = frozenWhileLoops.putIfAbsent(
                indexInstruction,
                () => NavigateurBlocs.trouverDebutBlocCorrespondant(
                  lignes,
                  indexInstruction,
                  'fintantque',
                  ['tantque'],
                ),
              );
              i = tantqueIdx;
              pileBlocs.removeLast();
            }
          } else if (pourMatch != null) {
            final varName = pourMatch.group(1)!;
            final startVal = await exec.evaluer(pourMatch.group(2)!);
            final endVal = await exec.evaluer(pourMatch.group(3)!);
            num pas = 1;

            if (pourMatch.group(4) != null) {
              pas = await exec.evaluer(pourMatch.group(4)!);
            } else {
              if (startVal is num && endVal is num && startVal > endVal) {
                pas = -1;
              }
            }

            env.assigner(varName, startVal);

            bool continueLoop = false;
            if (startVal is num && endVal is num) {
              if (pas > 0) {
                continueLoop = startVal <= endVal;
              } else {
                continueLoop = startVal >= endVal;
              }
            }

            if (!continueLoop) {
              i = NavigateurBlocs.trouverFinBlocCorrespondant(
                lignes,
                i,
                'pour',
                ['fpour', 'finpour'],
              );
            } else {
              frozenLoops[indexInstruction] = {
                'endVal': endVal,
                'pas': pas,
                'varName': varName,
              };
              pileBlocs.add('pour');
            }
          } else if (ligneLower.startsWith('finpour') ||
              ligneLower.startsWith('fpour') ||
              ligneLower.startsWith('fin pour')) {
            if (pileBlocs.isNotEmpty && pileBlocs.last == 'pour') {
              final pourLineIdx = NavigateurBlocs.trouverDebutBlocCorrespondant(
                lignes,
                indexInstruction,
                ligne.toLowerCase(),
                ['pour'],
              );

              final frozen = frozenLoops[pourLineIdx];
              if (frozen != null) {
                final varName = frozen['varName'] as String;
                final endVal = frozen['endVal'] as num;
                final pas = frozen['pas'] as num;

                dynamic currentVal = env.lire(varName);
                if (currentVal is num) {
                  currentVal = currentVal + pas;
                  env.assigner(varName, currentVal);

                  bool condition;
                  if (pas > 0) {
                    condition = currentVal <= endVal;
                  } else {
                    condition = currentVal >= endVal;
                  }

                  if (condition) {
                    i = pourLineIdx + 1;
                  } else {
                    frozenLoops.remove(pourLineIdx);
                    pileBlocs.removeLast();
                  }
                } else {
                  frozenLoops.remove(pourLineIdx);
                  pileBlocs.removeLast();
                }
              } else {
                // Fallback si pas figé (ne devrait pas arriver avec la nouvelle logique)
                pileBlocs.removeLast();
              }
            }
          } else if (ligne.toLowerCase() == 'repeter') {
            pileBlocs.add('repeter');
          } else if (jusquaMatch != null) {
            if (pileBlocs.isNotEmpty && pileBlocs.last == 'repeter') {
              if (!(await exec.evaluerBooleen(jusquaMatch.group(1)!))) {
                // Cache : évite une recherche O(n) à chaque itération
                final repeterIdx = frozenRepeatLoops.putIfAbsent(
                  indexInstruction,
                  () => NavigateurBlocs.trouverDebutBlocCorrespondant(
                    lignes,
                    indexInstruction,
                    'jusqua',
                    ['repeter'],
                  ),
                );
                i = repeterIdx;
              }
              pileBlocs.removeLast();
            }
          } else {
            final sortie = await exec.executerLigne(ligne);
            if (sortie == _kRetour) return _kRetour;
            // Nettoyer les systèmes de retour spéciaux et afficher si non vide
            if (sortie.trim().isNotEmpty) {
              onOutput(sortie);
            }
          }
        } catch (e) {
          final errLine = indexInstruction + baseOffset + 1;
          provider.setHighlightLine(null);
          provider.setErrorLine(errLine);
          final suffix = nomContexte != null ? " (dans '$nomContexte')" : "";
          onOutput("Erreur à la ligne $errLine$suffix: $e");
          return _kErreur;
        }
      }
    }
    return null;
  }

  static Future<void> traiterDeclarations(
    String ligne,
    Environnement env,
    Executeur exec,
  ) async {
    if (!ligne.contains(':')) return;
    final parts = ligne.split(':');
    final nomsBruts = parts[0].trim();
    String typeBrut = parts[1].trim();

    // Résolution récursive des types personnalisés
    while (env.chercherType(typeBrut) != null) {
      typeBrut = env.chercherType(typeBrut)!;
    }

    final typeLower = typeBrut.toLowerCase();
    final noms = nomsBruts.split(',').map((e) => e.trim());
    for (final nom in noms) {
      if (nom.isEmpty) continue;
      PreAnalyseur.validerNomIdentifier(nom);

      if (typeLower.startsWith('tableau')) {
        final match = RegExp(
          r"tableau\s*\[(.*)\]\s+(?:d'|de\s+)(\w+)",
          caseSensitive: false,
        ).firstMatch(typeBrut);
        if (match != null) {
          final rangesStr = match.group(1)!;
          final elemType = match.group(2)!;

          // Réutilise l'Executeur fourni pour évaluer les bornes
          // (au lieu de créer un Executeur jetable par déclaration)
          final ranges = rangesStr.split(',');
          List<int> mins = [];
          List<int> maxs = [];

          for (final r in ranges) {
            final bounds = r.split('..');
            if (bounds.length != 2)
              throw Exception("Format de plage invalide: $r");
            final minVal = await exec.evaluer(bounds[0]);
            final maxVal = await exec.evaluer(bounds[1]);
            mins.add((minVal as num).toInt());
            maxs.add((maxVal as num).toInt());
          }

          final structDef = env.chercherStructure(elemType.toLowerCase());
          env.declarer(
            nom,
            PseudoTableau(
              mins: mins,
              maxs: maxs,
              typeElement: elemType,
              structureDef: structDef,
              resolver: env.chercherStructure,
            ),
            typeBrut,
          );
        }
      } else {
        if (typeLower == 'entier')
          env.declarer(nom, 0, 'entier');
        else if (typeLower == 'réel' || typeLower == 'reel')
          env.declarer(nom, 0.0, 'réel');
        else if (typeLower == 'chaine')
          env.declarer(nom, "", 'chaine');
        else if (typeLower == 'booleen')
          env.declarer(nom, false, 'booleen');
        else {
          // Vérifier si c'est une structure personnalisée
          final structDef = env.chercherStructure(typeLower);
          if (structDef != null) {
            env.declarer(
              nom,
              structDef.instancier(env.chercherStructure),
              typeBrut,
            );
          }
        }
      }
    }
  }
}
