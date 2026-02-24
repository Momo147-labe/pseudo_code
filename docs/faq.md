# ❓ FAQ - 100+ Questions Fréquentes

Bienvenue dans la foire aux questions exhaustive de l'application **Pseudo Code**. Ce guide est conçu pour répondre à toutes vos interrogations, de la syntaxe de base aux fonctionnalités avancées d'IA.

---

## 📱 Utilisation Générale & Mobile

1. **Q : L'application est-elle disponible hors ligne ?**
   R : Oui, l'interpréteur et les schémas fonctionnent sans connexion. Seules les fonctionnalités d'IA (Groq) et les mises à jour nécessitent internet.

2. **Q : Comment passer en mode sombre ?**
   R : Menu **Fichier** -> **Changer le thème** (ou cliquez sur l'icône de lune/soleil dans la barre latérale).

3. **Q : Puis-je utiliser l'application sur une tablette ?**
   R : Absolument, l'interface est responsive et s'adapte parfaitement aux tablettes.

4. **Q : Comment changer la taille de la police rapidement sur mobile ?**
   R : Utilisez les boutons **+** et **-** dans la barre de statut en bas de l'écran.

5. **Q : Où se trouve l'option "Changer la police" sur mobile ?**
   R : Dans le menu **Fichier** en haut à gauche.

6. **Q : Pourquoi la console recouvre-t-elle mon code ?**
   R : Vous pouvez redimensionner la console en faisant glisser la barre de séparation ou la masquer via le bouton **Console** en bas.

7. **Q : Puis-je exporter mon code au format PDF ?**
   R : Oui, via le menu **Exporter** -> **Exporter en PDF**.

8. **Q : Est-il possible de prendre une capture d'écran du code proprement ?**
   R : Oui, utilisez **Exporter** -> **Exporter en Image (PNG)**.

9. **Q : Le copier-coller fonctionne-t-il sur mobile ?**
   R : Oui, maintenez la pression sur l'éditeur pour afficher les options système.

10. **Q : Comment fermer la documentation sur mobile ?**
    R : Cliquez sur la croix (**X**) en haut à droite de la page de doc.

11. **Q : Comment ouvrir un fichier existant ?**
    R : Utilisez l'explorateur de fichiers dans la barre latérale gauche.

12. **Q : Puis-je créer des dossiers pour organiser mes algorithmes ?**
    R : Oui, via l'icône "Nouveau dossier" dans l'explorateur.

13. **Q : Comment renommer un fichier ?**
    R : Faites un clic droit (ou appui long sur mobile) sur le fichier dans l'explorateur.

14. **Q : L'application sauvegarde-t-elle automatiquement ?**
    R : Oui, lors de l'exécution, mais il est conseillé d'utiliser `Ctrl+S` (ou l'icône de disquette) régulièrement.

15. **Q : Puis-je changer la langue de l'interface ?**
    R : L'application suit actuellement la langue de votre système (Français/Anglais).

---

## 🤖 Intelligence Artificielle (IA)

16. **Q : Qu'est-ce qu'Ollama ?**
    R : C'est un outil qui permet de faire tourner des IA localement sur votre ordinateur sans passer par internet.

17. **Q : Pourquoi l'IA dit "Ollama non disponible" ?**
    R : Vérifiez que l'application Ollama est lancée et que vous avez téléchargé un modèle (ex: `ollama run llama3`).

18. **Q : Quelle est la différence entre Ollama et Groq ?**
    R : Ollama est local (privé, gratuit), Groq est un service cloud (très rapide, nécessite une clé API).

19. **Q : Où configurer ma clé API Groq ?**
    R : Créez un fichier `.env` à la racine ou gérez-le dans les paramètres de l'application.

20. **Q : L'IA peut-elle m'aider à corriger mes erreurs ?**
    R : Oui, sélectionnez votre code et demandez "Pourquoi j'ai une erreur ici ?".

21. **Q : L'IA comprend-elle mon pseudo-code spécifique ?**
    R : Oui, nous lui avons fourni les règles de syntaxe de cet interpréteur.

22. **Q : Est-ce que mes données sont envoyées sur internet ?**
    R : Uniquement si vous utilisez Groq. Avec Ollama, tout reste sur votre machine.

23. **Q : Comment utiliser la commande vocale pour l'IA ?**
    R : Cliquez sur l'icône micro dans le chat (si votre appareil le supporte).

24. **Q : L'IA peut-elle commenter mon code ?**
    R : Oui, demandez-lui "Ajoute des commentaires pertinents à cet algorithme".

25. **Q : L'IA peut-elle traduire mon pseudo-code en Python ?**
    R : Oui, et nous avons aussi un outil de traduction intégré sans IA.

---

## 🧮 Syntaxe du Pseudo-Code

26. **Q : Comment déclarer une variable ?**
    R : `Variables nom : Type` (ex: `Variables x : Entier`).

27. **Q : Quels sont les types disponibles ?**
    R : `Entier`, `Réel`, `Chaîne`, `Caractère`, `Booléen`.

28. **Q : Comment faire une affectation ?**
    R : Utilisez la flèche `<-` (ex: `age <- 20`).

29. **Q : Le symbole `=` sert-il à l'affectation ?**
    R : Non, `=` est uniquement pour la comparaison dans les conditions.

30. **Q : Comment écrire un commentaire ?**
    R : Utilisez `//` pour une ligne ou `/* ... */` pour plusieurs lignes.

31. **Q : Quelle est la structure de base d'un algorithme ?**
    R : `Algorithme nom ... Variables ... DEBUT ... FIN`.

32. **Q : Comment afficher un texte à l'écran ?**
    R : `Ecrire("Mon texte")`.

33. **Q : Comment lire une valeur saisie par l'utilisateur ?**
    R : `Lire(maVariable)`.

34. **Q : Comment faire un saut de ligne dans Ecrire ?**
    R : Utilisez `EcrireLigne` ou ajoutez `\n` dans la chaîne.

35. **Q : Comment déclarer un tableau ?**
    R : `Variables t : Tableau[1..10] d'Entier`.

36. **Q : Les indices des tableaux commencent-ils à 0 ou 1 ?**
    R : Vous choisissez ! `[0..9]` ou `[1..10]` sont tous deux valides.

37. **Q : Comment faire une structure SI ?**
    R : `SI condition ALORS ... SINON ... FINSI`.

38. **Q : Comment utiliser les opérateurs logiques ?**
    R : Utilisez les mots-clés `ET`, `OU`, `NON`.

39. **Q : Comment faire une boucle POUR ?**
    R : `POUR i <- 1 A 10 [PAS 1] FAIRE ... FINPOUR`.

40. **Q : Comment faire une boucle TANT QUE ?**
    R : `TANTQUE condition FAIRE ... FINTANTQUE`.

41. **Q : Quelle est la différence avec REPETER...JUSQU'A ?**
    R : `REPETER` exécute le code au moins une fois avant de tester la condition.

42. **Q : Comment déclarer une fonction ?**
    R : `Fonction nom(param : Type) : TypeRetour ... DEBUT ... RENVOYER val ... FIN`.

43. **Q : Quelle est la différence entre une Fonction et une Procédure ?**
    R : Une procédure ne renvoie pas de valeur.

44. **Q : Puis-je passer des paramètres par référence ?**
    R : Oui, utilisez le mot-clé `REF` devant le paramètre.

45. **Q : Le pseudo-code est-il sensible à la casse ?**
    R : Non, `Variables` et `variables` sont identiques.

---

## ⚙️ Exécution & Débogage

46. **Q : Que signifie une erreur "Syntax Error" ?**
    R : Il manque probablement un mot-clé (ex: FINSI) ou une ponctuation.

47. **Q : Comment utiliser le débogueur pas à pas ?**
    R : Cliquez sur l'icône **Insecte** (Debug). Le code s'arrêtera à chaque ligne.

48. **Q : Comment voir la valeur des variables pendant le debug ?**
    R : Ouvrez l'onglet **Variables** dans la barre latérale pendant l'exécution.

49. **Q : Qu'est-ce qu'un "Point d'arrêt" (Breakpoint) ?**
    R : Cliquez à gauche du numéro de ligne pour marquer un point où l'exécution s'arrêtera.

50. **Q : Pourquoi mon programme boucle à l'infini ?**
    R : Vérifiez que la condition de votre `TANTQUE` finit par devenir fausse.

51. **Q : La console est vide après l'exécution ?**
    R : Avez-vous utilisé des instructions `Ecrire` ?

52. **Q : Comment vider la console ?**
    R : Utilisez l'icône de corbeille dans le panneau de la console.

53. **Q : Puis-je arrêter une exécution en cours ?**
    R : Oui, cliquez sur le bouton **Stop** (carré rouge).

54. **Q : Les erreurs s'affichent en rouge, c'est normal ?**
    R : Oui, l'interpréteur vous indique la ligne et la nature du problème.

55. **Q : L'application plante sur de gros calculs ?**
    R : Vérifiez que vous n'avez pas une récursion infinie (fonction qui s'appelle elle-même sans fin).

---

## 📐 Merise (MCD/MLD)

56. **Q : Qu'est-ce qu'un MCD ?**
    R : Un Modèle Conceptuel de Données représentant les entités et leurs relations.

57. **Q : Comment créer une entité ?**
    R : Cliquez sur l'outil "Entité" et placez-la sur le canevas.

58. **Q : Comment ajouter des attributs ?**
    R : Double-cliquez sur l'entité.

59. **Q : Qu'est-ce qu'une "Identifiant" ?**
    R : C'est la clé primaire de l'entité (ex: `id_client`). Elle est soulignée.

60. **Q : Comment créer une relation ?**
    R : Utilisez l'outil "Relation" pour relier deux entités.

61. **Q : Comment définir les cardinalités (0,n, 1,1...) ?**
    R : Cliquez sur le trait de liaison entre l'entité et la relation.

62. **Q : L'application peut-elle transformer mon MCD en MLD ?**
    R : Oui, il y a un bouton de génération automatique dans l'onglet Merise.

63. **Q : Qu'est-ce qu'une clé étrangère dans le MLD ?**
    R : Une clé qui provient d'une autre table pour établir un lien (souvent notée `#`).

64. **Q : Puis-je exporter mon schéma Merise en SQL ?**
    R : Oui, l'exportation MPD génère le script SQL de création des tables.

65. **Q : Quels SGBD sont supportés pour l'export SQL ?**
    R : MySQL, PostgreSQL, et SQL Server.

---

## 📊 Graphes

66. **Q : Comment créer un nouveau sommet (Node) ?**
    R : Double-cliquez sur le canevas blanc.

67. **Q : Comment relier deux sommets par une arête ?**
    R : Maintenez `Shift` et glissez d'un sommet à un autre.

68. **Q : Quelle est la différence entre un graphe Orienté et Non-orienté ?**
    R : Orienté = les flèches ont un sens. Non-orienté = simple trait.

69. **Q : Comment ajouter un poids (coût) à une arête ?**
    R : Cliquez sur l'arête et saisissez la valeur numérique.

70. **Q : L'application peut-elle résoudre le plus court chemin ?**
    R : Oui, utilisez l'outil **Dijkstra** inclus dans l'éditeur de graphes.

71. **Q : Comment lancer un parcours en largeur (BFS) ?**
    R : Sélectionnez un sommet de départ et lancez l'animation BFS.

72. **Q : Puis-je déplacer les sommets après les avoir créés ?**
    R : Oui, il suffit de les cliquer et de les glisser.

73. **Q : Comment supprimer un élément ?**
    R : Sélectionnez-le et appuyez sur la touche `Suppr` ou `Backspace`.

74. **Q : Le graphe est-il limité en nombre de sommets ?**
    R : Non, mais la lisibilité diminue au-delà de 50 sommets.

75. **Q : Puis-je sauvegarder mes graphes pour plus tard ?**
    R : Oui, ils font partie de votre projet.

---

## 🏆 Défis & Progression

76. **Q : Où trouver les exercices ?**
    R : Cliquez sur l'onglet **Défis** (icône de trophée).

77. **Q : Comment sont calculés les points ?**
    R : En fonction de la difficulté du problème et de l'efficacité de votre code.

78. **Q : Qu'est-ce qu'un "Badge" ?**
    R : Une récompense visuelle pour des exploits (ex: "10 jours consécutifs").

79. **Q : Puis-je comparer mon score avec d'autres ?**
    R : Oui, si vous êtes connecté au mode en ligne.

80. **Q : Comment débloquer le niveau "Expert" ?**
    R : Vous devez valider au moins 80% des défis "Intermédiaire".

81. **Q : Les indices pour les défis coûtent-ils des points ?**
    R : Oui, utiliser un indice réduit légèrement votre score final.

82. **Q : Puis-je refaire un défi déjà réussi ?**
    R : Oui, pour améliorer votre temps ou votre logique.

83. **Q : Où voir mon classement ?**
    R : Dans l'onglet **Classement** du menu Profil.

84. **Q : Les défis couvrent-ils aussi Merise ?**
    R : Oui, il y a des quiz et des exercices de modélisation.

85. **Q : Comment gagner des "Pièces" ?**
    R : En complétant des quêtes quotidiennes.

---

## 🛠️ Installation & Résolution de Problèmes

86. **Q : L'application ne s'ouvre pas sous Linux ?**
    R : Vérifiez les permissions du fichier (`chmod +x`).

87. **Q : Erreur de police (Font not found) ?**
    R : L'application embarque ses propres polices, essayez de redémarrer le programme.

88. **Q : Mon fichier .alg a disparu ?**
    R : Vérifiez dans la corbeille de votre système ou dans le dossier de sauvegarde.

89. **Q : L'application est lente ?**
    R : Fermez les onglets Merise ou Graphes inutilisés qui peuvent consommer de la mémoire.

90. **Q : Comment réinitialiser les paramètres par défaut ?**
    R : Menu **Paramètres** -> **Réinitialiser tout**.

91. **Q : Est-ce compatible avec Windows 11 ?**
    R : Oui, totalement compatible.

92. **Q : Comment signaler un bug ?**
    R : Utilisez le lien GitHub dans le menu d'aide ou envoyez un log via l'application.

93. **Q : Où trouver les logs d'erreur ?**
    R : Dans le dossier `.logs` situé dans le répertoire d'installation.

94. **Q : L'application demande une mise à jour Flutter ?**
    R : Non, l'application est compilée, vous n'avez pas besoin d'installer Flutter vous-même.

95. **Q : Puis-je utiliser mon propre éditeur de texte ?**
    R : Oui, mais vous perdrez la coloration syntaxique et l'exécution directe.

---

## 💡 Astuces Avancées

96. **Q : Existe-t-il des raccourcis clavier ?**
    R : Oui, ex: `Ctrl+Enter` pour exécuter, `Ctrl+F` pour rechercher.

97. **Q : Comment utiliser plusieurs fichiers à la fois ?**
    R : L'application supporte les onglets multiples en haut de l'éditeur.

98. **Q : Puis-je personnaliser les couleurs de la syntaxe ?**
    R : Pas encore, mais nous proposons 5 thèmes prédéfinis.

99. **Q : Comment insérer des caractères spéciaux sur mobile ?**
    R : Utilisez la barre d'outils au-dessus du clavier.

100. **Q : Le pseudo-code est-il standardisé ?**
    R : Nous suivons le standard académique français le plus répandu.

101. **Q : Puis-je contribuer au développement ?**
    R : L'application est open-source, contactez-nous sur GitHub !

102. **Q : Comment exporter tout mon projet d'un coup ?**
    R : Faites un clic droit sur le dossier racine dans l'explorateur -> **Compresser (Zip)**.

103. **Q : Qu'est-ce que le "Passage par Valeur-Résultat" ?**
    R : C'est la méthode interne utilisée pour synchroniser les paramètres `REF` après l'exécution.

104. **Q : Puis-je copier le résultat de la console ?**
    R : Oui, sélectionnez le texte et faites `Ctrl+C` ou clic droit -> **Copier**.

105. **Q : Comment savoir si j'ai la dernière version ?**
    R : Regardez le numéro de version dans le menu **À propos**.

---
[⬅️ Retour à l'accueil](./README.md)
