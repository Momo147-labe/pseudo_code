import 'package:pseudo_code/interpreteur/environnement.dart';
import 'package:pseudo_code/interpreteur/executeur.dart';
import 'package:pseudo_code/interpreteur/mots_cles.dart';
import 'package:pseudo_code/interpreteur/navigateur_blocs.dart';
import 'package:pseudo_code/interpreteur/blocs/tableaux.dart';
import 'package:pseudo_code/interpreteur/blocs/fonctions.dart';
import 'package:pseudo_code/interpreteur/blocs/structures.dart';
import 'package:pseudo_code/interpreteur/validateur.dart';
import 'package:pseudo_code/providers/debug_provider.dart';

class Interpreteur {
  static final RegExp _regVars = RegExp(r'^variables\b', caseSensitive: false);
  static final RegExp _regDebut = RegExp(
    r'^début\b|^debut\b',
    caseSensitive: false,
  );
  static final RegExp _regFinSpecific = RegExp(
    r'^fin[a-z]+',
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
  static final RegExp _regConstLine = RegExp(
    r'^const\s+(.*)$',
    caseSensitive: false,
  );
  static final RegExp _regAssignConst = RegExp(
    r'^([a-zA-Z_]\w*)\s*(?:<-|←|=)\s*(.*)$',
  );
  static final RegExp _regTypeStruct = RegExp(
    r'^type\s+([a-zA-Z_]\w*)\s*=\s*structure',
    caseSensitive: false,
  );
  static final RegExp _regTypeSimple = RegExp(
    r'^type\s+([a-zA-Z_]\w*)\s*=\s*(.*)$',
    caseSensitive: false,
  );
  static final RegExp _tabReg = RegExp(
    r"tableau\s*\[(.*)\]\s+(?:d'|de\s+)(\w+)",
    caseSensitive: false,
  );
  static final RegExp _regValidId = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');
  static final RegExp _regStartsWithNum = RegExp(r'^[0-9]');

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

    // 2. Pré-analyse pour enregistrer les constantes, types et structures
    await _enregistrerConstantes(lignes, env, provider, onOutput);
    _enregistrerTypesEtStructures(lignes, env);

    // 3. Pré-analyse pour enregistrer les fonctions et procédures
    _enregistrerSousProgrammes(lignes, env);

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

    int instructionCount = 0;
    int i = startIndex;
    while (i < lignes.length) {
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
      if (_regDebut.hasMatch(ligne)) {
        dansVariables = false;
        dansDebut = true;
        continue;
      }
      if (_regFin.hasMatch(ligne)) {
        if (_regFinSpecific.hasMatch(ligne) && !_regFinOnly.hasMatch(ligne)) {
          // Bloc spécifique, ignoré ici
        } else {
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
          await traiterDeclarations(ligne, env);
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
              i = await NavigateurBlocs.sauterVersBrancheSuivante(
                lignes,
                i,
                exec,
              );
            }
          } else if (sinonSiMatch != null || ligne.toLowerCase() == 'sinon') {
            i = NavigateurBlocs.trouverFinBlocCorrespondant(lignes, i, 'si', [
              'finsi',
            ]);
            if (pileBlocs.isNotEmpty && pileBlocs.last == 'si')
              pileBlocs.removeLast();
          } else if (ligne.toLowerCase() == 'finsi') {
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
          } else if (ligne.toLowerCase() == 'finselon') {
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
          } else if (ligne.toLowerCase() == 'fintantque') {
            if (pileBlocs.isNotEmpty && pileBlocs.last == 'tantque') {
              i = NavigateurBlocs.trouverDebutBlocCorrespondant(
                lignes,
                indexInstruction,
                'fintantque',
                ['tantque'],
              );
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
          } else if (ligne.toLowerCase() == 'fpour' ||
              ligne.toLowerCase() == 'finpour') {
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
                i = NavigateurBlocs.trouverDebutBlocCorrespondant(
                  lignes,
                  indexInstruction,
                  'jusqua',
                  ['repeter'],
                );
              }
              pileBlocs.removeLast();
            }
          } else {
            final sortie = await exec.executerLigne(ligne);
            if (sortie == "__RETURN__") return "__RETURN__";
            // Nettoyer les sytèmes de retour spéciaux et afficher si non vide
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
          return "__ERROR__";
        }
      }
    }
    return null;
  }

  static Future<void> _enregistrerConstantes(
    List<String> lignes,
    Environnement env,
    DebugProvider provider,
    Function(String) onOutput,
  ) async {
    final exec = Executeur(
      env,
      provider: provider,
      onInput: () async => "",
      onOutput: onOutput,
    );

    // Regex capture 'const' puis tout ce qui suit
    for (int i = 0; i < lignes.length; i++) {
      final l = lignes[i].trim();
      final matchLine = _regConstLine.firstMatch(l);
      if (matchLine != null) {
        final declarations = matchLine.group(1)!;
        // Diviser par virgules, mais respecter les parenthèses/crochets si besoin
        // Ici on suppose des expressions simples ou on utilise un splitter robuste
        final parts = _splitDeclarations(declarations);
        for (final part in parts) {
          final m = _regAssignConst.firstMatch(part.trim());
          if (m != null) {
            final nom = m.group(1)!;
            _validerNomIdentifier(nom);
            final expr = m.group(2)!;
            try {
              final valeur = await exec.evaluer(expr);
              env.declarerConstante(nom, valeur);
            } catch (e) {
              onOutput(
                "Erreur lors de l'évaluation de la constante '$nom': $e",
              );
            }
          }
        }
      }
    }
  }

  static List<String> _splitDeclarations(String s) {
    final result = <String>[];
    String courant = "";
    int parenStack = 0;
    for (int i = 0; i < s.length; i++) {
      if (s[i] == '(') parenStack++;
      if (s[i] == ')') parenStack--;
      if (s[i] == ',' && parenStack == 0) {
        result.add(courant.trim());
        courant = "";
      } else {
        courant += s[i];
      }
    }
    if (courant.isNotEmpty) result.add(courant.trim());
    return result;
  }

  static void _enregistrerTypesEtStructures(
    List<String> lignes,
    Environnement env,
  ) {
    int i = 0;

    while (i < lignes.length) {
      String l = lignes[i].trim();
      final matchStruct = _regTypeStruct.firstMatch(l);
      if (matchStruct != null) {
        String nomStruct = matchStruct.group(1)!;
        _validerNomIdentifier(nomStruct);
        nomStruct = nomStruct.toLowerCase();
        List<ChampStructure> champs = [];
        i++;
        while (i < lignes.length) {
          String ligneChamp = lignes[i].trim();
          if (ligneChamp.toLowerCase() == 'finstructure') break;
          if (ligneChamp.contains(':')) {
            final p = ligneChamp.split(':');
            final noms = p[0].split(',').map((e) => e.trim());
            final type = p[1].trim();
            for (final n in noms) {
              if (n.isNotEmpty) {
                _validerNomIdentifier(n);
                champs.add(ChampStructure(nom: n, type: type));
              }
            }
          }
          i++;
        }
        env.declarerStructure(
          PseudoStructureDefinition(nom: nomStruct, champs: champs),
        );
      } else {
        final matchSimple = _regTypeSimple.firstMatch(l);
        if (matchSimple != null) {
          final nom = matchSimple.group(1)!;
          _validerNomIdentifier(nom);
          final def = matchSimple.group(2)!;
          env.declarerType(nom, def);
        }
      }
      i++;
    }
  }

  static void _enregistrerSousProgrammes(
    List<String> lignes,
    Environnement env,
  ) {
    int i = 0;
    while (i < lignes.length) {
      String l = lignes[i].trim();
      if (l.toLowerCase().startsWith('fonction')) {
        final match = GestionnaireFonctions.regFonction.firstMatch(l);
        if (match != null) {
          final nom = match.group(1)!;
          _validerNomIdentifier(nom);
          final params = GestionnaireFonctions.extraireParametres(
            match.group(2)!,
          );
          // Valider noms des paramètres
          for (final p in params) {
            _validerNomIdentifier(p.nom);
          }
          final typeRetour = match.group(3)!;
          final debutIdx = i + 1;
          final finIdx = NavigateurBlocs.trouverFinBlocCorrespondant(
            lignes,
            debutIdx,
            'fonction',
            ['finfonction'],
          );
          env.declarerFonction(
            PseudoFonction(
              nom: nom,
              parametres: params,
              typeRetour: typeRetour,
              lignes: lignes.sublist(debutIdx, finIdx - 1),
              offset: debutIdx,
            ),
          );
          i = finIdx;
          continue;
        }
      } else if (l.toLowerCase().startsWith('procedure')) {
        final match = GestionnaireFonctions.regProcedure.firstMatch(l);
        if (match != null) {
          final nom = match.group(1)!;
          _validerNomIdentifier(nom);
          final params = GestionnaireFonctions.extraireParametres(
            match.group(2)!,
          );
          // Valider noms des paramètres
          for (final p in params) {
            _validerNomIdentifier(p.nom);
          }
          final debutIdx = i + 1;
          final finIdx = NavigateurBlocs.trouverFinBlocCorrespondant(
            lignes,
            debutIdx,
            'procedure',
            ['finprocedure'],
          );
          env.declarerProcedure(
            PseudoProcedure(
              nom: nom,
              parametres: params,
              lignes: lignes.sublist(debutIdx, finIdx - 1),
              offset: debutIdx,
            ),
          );
          i = finIdx;
          continue;
        }
      }
      i++;
    }
  }

  static Future<void> traiterDeclarations(
    String ligne,
    Environnement env,
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
      _validerNomIdentifier(nom);

      if (typeLower.startsWith('tableau')) {
        final match = _tabReg.firstMatch(typeBrut);
        if (match != null) {
          final rangesStr = match.group(1)!;
          final elemType = match.group(2)!;

          final exec = Executeur(
            env,
            provider: DebugProvider(),
            onInput: () async => "",
            onOutput: (_) {},
          );

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
            env.declarer(nom, structDef.instancier(), typeBrut);
          } else {
            throw Exception("Type inconnu : '$typeBrut'");
          }
        }
      }
    }
  }

  static void _validerNomIdentifier(String nom) {
    if (nom.isEmpty) return;

    // Règle 1: Ne pas être un mot-clé
    if (MotsCles.estUnMotCle(nom)) {
      throw Exception("Erreur: '$nom' est un mot-clé réservé du langage.");
    }

    // Règle 2: Regex ^[a-zA-Z][a-zA-Z0-9_]*$
    if (!_regValidId.hasMatch(nom)) {
      if (_regStartsWithNum.hasMatch(nom)) {
        throw Exception(
          "Erreur: Le nom '$nom' ne peut pas commencer par un chiffre.",
        );
      }
      if (nom.contains(' ')) {
        throw Exception(
          "Erreur: Le nom '$nom' ne peut pas contenir d'espaces.",
        );
      }
      throw Exception(
        "Erreur: Le nom '$nom' contient des caractères spéciaux non autorisés.",
      );
    }
  }
}
