# 📘 Guide Utilisateur de l'Algorithmique

Bienvenue dans ce guide complet. Avant de plonger dans le code, comprenons les bases.

---

## 🚀 1. Qu'est-ce qu'un Algorithme ?

Un **algorithme** est une suite d'instructions claires et ordonnées permettant de résoudre un problème ou d'accomplir une tâche. C'est, en quelque sorte, la "recette" logique que l'ordinateur doit suivre pour transformer des données d'entrée en un résultat.

**Pourquoi est-ce important ?**
L'algorithmique est le fondement de toute programmation. Elle permet de structurer sa pensée, de prévoir tous les cas de figure et de créer des solutions efficaces et réutilisables, quel que soit le langage informatique utilisé par la suite.

---

## 🏗️ 2. Structure de Base d'un Algorithme

Le squelette standard d'un programme définit l'ordre de déclaration et d'exécution des instructions. C'est le cadre qui délimite où les données sont définies et où l'action commence.

```javascript
Algorithme Nom_Du_Programme

// 1. Déclarations (Constantes, Types, Variables)
variables
    Rayon : reel

// 2. Corps du programme
Début
    Afficher("Entrez le rayon : ")
    Lire(Rayon)
    Afficher("Le périmètre est : ", 2 * 3.14 * Rayon)
Fin
```

> [!VIDEO]
> ![Tutoriel Structure de Base](path/to/video_structure.mp4)
> *Vidéo illustrative : Créer son premier algorithme.*

---

## 🏷️ 3. Nomenclature et Mots Réservés

Le choix du nom de vos variables n'est pas libre. Il suit des règles précises pour éviter toute confusion avec les instructions du langage.

### Règle de d'écriture des Identifiants
- **Composition** : Un nom peut contenir des lettres, des chiffres et le tiret bas (`_`).
- **Premier Caractère** : Il doit obligatoirement commencer par une **lettre**.
- **Casse** : Le langage est insensible à la casse (`MaVariable` est identique à `mavariable`).

### 🚫 Mots Interdits (Mots Réservés)
Vous ne pouvez pas utiliser les mots-clés du langage comme noms de variables. Voici les plus courants :
- **Structure** : `Algorithme`, `Variables`, `Début`, `Fin`, `const`, `type`, `structure`.
- **Contrôle** : `si`, `alors`, `sinon`, `finsi`, `pour`, `tantque`, `faire`, `selon`, `cas`, `repeter`, `fonction`, `procedure`, `retourner`.
- **Logique/Types** : `entier`, `reel`, `chaine`, `booleen`, `tableau`, `vrai`, `faux`, `et`, `ou`, `non`.
- **Actions/Natives** : `lire`, `afficher`, `ecrire`, `effacer`, `long`, `maj`, `minus`, `car`, `racine`, `abs`, `hasard`, `arrondi`, `tronque`, `en_entier`, `en_reel`, `en_chaine`, `typevar`, `est_numerique`.

### Pourquoi ces restrictions ?
L'interpréteur utilise ces mots pour identifier la structure logique de votre programme. Si vous appeliez une variable `si`, le moteur ne pourrait plus savoir si vous essayez de faire un test conditionnel ou d'accéder à une valeur, ce qui provoquerait une **erreur de syntaxe**.

---

## 📦 4. Variables et Types de Données

Une variable est un **conteneur nommé** stocké dans la mémoire de l'ordinateur. Elle permet de conserver une valeur qui peut changer durant l'exécution de l'algorithme.

### Les Types Fondamentaux
- **entier** : Nombres entiers (ex: `10`, `-5`).
- **reel** : Nombres à virgule (ex: `3.14`,`30`).
- **chaine** : Texte entre guillemets (ex: `"Bonjour"`).
- **booleen** : Valeurs logiques (`vrai` ou `faux`).

### Déclaration et Affectation
```javascript
variables
    age : entier
Début
    age <- 25 // Affectation de la valeur 25
    age <- age + 1
Fin
```

---

## 🔢 5. Opérateurs Arithmétiques et Logiques

Les opérateurs sont les outils qui permettent de manipuler les données, que ce soit pour effectuer des calculs mathématiques ou pour comparer des valeurs entre elles.

### Mathématiques
- `+`, `-`, `*`, `/` : Opérations classiques.
- `^` : Puissance (ex: `2 ^ 3` donne `8`).
- `div` : Quotient de la division entière (ex: `10 div 3` = `3`).
- `mod` : Reste de la division entière (ex: `10 mod 3` = `1`).

### Comparaisons et Logique
- `=`, `< >`, `<`, `>`, `< =`, `> =`
- `et`, `ou`, `non`

---

## 🖥️ 6. Entrées / Sorties et Console

Les instructions de communication permettent au programme d'interagir avec l'utilisateur via la console.

### 📥 Lire / Afficher
- **Lire** : Attend une saisie utilisateur et l'enregistre dans une variable.
- **Afficher / Ecrire** : Affiche des messages ou le contenu de variables sur l'écran.

### 🧹 Effacer la Console
L'instruction `effacer` permet de vider instantanément tout le contenu de la console. C'est très utile pour garder un affichage propre lors de menus ou de jeux.

```javascript
Début
    Afficher("Bienvenue !")
    Effacer // La console devient vide
    Afficher("Nouveau message propre.")
Fin
```

---

## 🔄 7. Structures de Contrôle

Ce sont les mécanismes permettant d'orienter l'exécution de l'algorithme vers différents blocs d'instructions selon le résultat d'un test logique (vrai ou faux).

### ➡️ Les Conditions (Si...Alors...Sinon)
Permet de prendre des décisions selon un test logique.
```javascript
Si Température > 30 Alors
    Afficher("Il fait chaud")
Sinon
    Afficher("Température agréable")
FinSi
```

### ➡️ Le Choix Multiple (Selon...Cas)
Idéal pour tester plusieurs valeurs d'une même variable.
```javascript
Selon Choix faire
    Cas 1 : Additionner()
    Cas 2 : Soustraire()
    Sinon : Afficher("Erreur")
FinSelon
```

---

## 🔁 8. Les Boucles (Répétitions)

Aussi appelées structures répétitives, elles permettent d'exécuter un bloc d'instructions plusieurs fois de suite sans avoir à réécrire le code.

### ♾️ Boucle Tantque
Répète tant que la condition est vraie. Le test est fait **avant**.
```javascript
Tantque Niveau > 0 faire
    Vider_Un_Litre()
FinTantque
```

### ♾️ Boucle Pour
Utilisée quand le nombre de répétitions est connu.
```javascript
Pour i de 1 à 10 Faire
    Afficher(i)
FinPour
```

### ♾️ Boucle Repeter...Jusqu'à
Exécute au moins une fois, s'arrête quand la condition devient **vraie**.
```javascript
Répéter
    Lire(Note)
Jusqua Note >= 0 ET Note <= 20
```

---

## 📊 9. Tableaux et Structures

Ces structures permettent de regrouper plusieurs données sous un même nom, facilitant la gestion de collections d'éléments ou d'objets complexes.

### Tableaux (1D et 2D)
```javascript
variables
    Noms : tableau [1..5] de chaine
    Grille : tableau [1..3, 1..3] de entier
Début
    Noms[1] <- "Alice"
    Grille[1, 2] <- 0
Fin
```

### Structures (Enregistrements)
```javascript
type Etudiant = structure
    nom : chaine
    note : reel
finstructure

variables
    e1 : Etudiant
Début
    e1.nom <- "Jean"
Fin
```

---

## 🛠️ 10. Fonctions et Procédures

Les sous-programmes sont des blocs de code isolés conçus pour effectuer une tâche précise. Ils permettent de structurer les gros programmes et de réutiliser les solutions.

Les sous-programmes permettent de réutiliser du code. 

- **Fonction** : Exécute une tâche et **retourne** obligatoirement un résultat.
- **Procédure** : Exécute une suite d'instructions sans retourner de valeur.

```javascript
Fonction Carre(x : entier) : entier
Début
    Retourner x * x
finfonction

procedure Saluer(nom : chaine)
Début
    Afficher("Bonjour ", nom)
finprocedure
```

---

## 📚 11. Fonctions Natives (Bibliothèque Standard)

La plateforme met à votre disposition une "boîte à outils" de fonctions prêtes à l'emploi pour gagner du temps sur les opérations fréquentes.

Le langage propose un ensemble de fonctions intégrées pour manipuler vos données. Voici les principales catégories :

### 🔤 Manipulation de Chaînes
- **`long(s)`** : Retourne la longueur d'une chaîne.
  - *Exemple* : `long("Hello")` → `5`
- **`maj(s)`** : Convertit la chaîne en MAJUSCULES.
  - *Exemple* : `maj("fode momo soumah")` → `"FODE MOMO SOUMAH"`
- **`minus(s)`** : Convertit la chaîne en minuscules.
  - *Exemple* : `minus("ABC")` → `"abc"`
- **`car(s, i)`** : Récupère le i-ème caractère (index 1).
  - *Exemple* : `car("Pseudo", 1)` → `"P"`

### 🔢 Mathématiques
- **`racine(n)`** : Calcule la racine carrée.
  - *Exemple* : `racine(16)` → `4.0`
- **`abs(n)`** : Retourne la valeur absolue.
  - *Exemple* : `abs(-5)` → `5`
- **`hasard(a, b)`** : Entier aléatoire entre a et b.
  - *Exemple* : `hasard(1, 10)` → `7`
- **`arrondi(n)`** : Arrondit au nombre le plus proche.
  - *Exemple* : `arrondi(3.6)` → `4`
- **`tronque(n)`** : Garde uniquement la partie entière.
  - *Exemple* : `tronque(3.9)` → `3`

### 🔄 Conversions et Analyse
- **`en_entier(v)`** : Convertit une valeur en entier.
  - *Exemple* : `en_entier("42")` → `42`
- **`en_reel(v)`** : Convertit une valeur en réel.
  - *Exemple* : `en_reel("3.14")` → `3.14`
- **`en_chaine(v)`** : Convertit une valeur en texte.
  - *Exemple* : `en_chaine(123)` → `"123"`
- **`typevar(v)`** : Retourne le type de la variable.
  - *Exemple* : `typevar(vrai)` → `"booleen"`
- **`est_numerique(s)`** : Vérifie si le texte est un nombre.
  - *Exemple* : `est_numerique("12")` → `vrai`

---

## 💡 12. Mode Aide et Algorithmes Inclus

Une fonctionnalité puissante de l'éditeur est le **Mode Aide**. Il vous permet d'accéder instantanément à des modèles d'algorithmes classiques.

### Comment l'utiliser ?
1. Dans l'éditeur, tapez simplement le mot-clé `aide`.
2. Une liste de suggestions apparaîtra, contenant des algorithmes célèbres.
3. Sélectionnez celui que vous voulez, et son code sera automatiquement inséré !

### Quelques algorithmes disponibles via `aide` :
- **Tris** : `TriSelection`, `TriBulles`, `TriInsertion`.
- **Recherche** : `RechercheDichotomique`, `rechercheSequentielle`.
- **Maths** : `Factorielle`, `Fibonacci`, `PGCD`, `EstPremier`.
- **Matrices** : `ProduitMatrices`, `TransposerMatrice`.
- **Divers** : `EstPalindrome`, `DecimalEnBinaire`, `LaboratoireNatives`.

> [!TIP]
> **Le Laboratoire des Natives** : Tapez `aide` puis sélectionnez `LaboratoireNatives` pour insérer un programme de test complet qui démontre l'utilisation de toutes les fonctions natives citées plus haut !

---

## 🏆 13. Système de Défis (Gamification)

La plateforme propose un système de défis interactifs pour mettre vos compétences à l'épreuve et suivre votre progression.

### Accès aux Défis
Cliquez sur l'onglet **Défis** (icône trophée) dans la barre latérale. Vous y trouverez :
- **Défis Disponibles** : La liste des exercices que vous pouvez tenter. Certains sont verrouillés et ne se débloquent qu'en réussissant les précédents.
- **Défis Réalisés** : L'historique de vos succès.

### Résoudre un Défi
Chaque défi se compose de trois parties :
1. **Énigme / Instructions** : Une description détaillée du problème à résoudre et les contraintes à respecter.
2. **Éditeur de Code** : Un espace dédié pour écrire votre solution (souvent avec un code de départ fourni).
3. **Validation (Bouton TESTER)** : Cliquez sur ce bouton pour lancer une série de tests automatiques.

### Récompenses et XP
- Chaque test réussi valide une partie de votre solution.
- Si tous les tests passent, le défi est marqué comme **Réussi**.
- Vous gagnez des **XP (Points d'Expérience)** qui augmentent votre niveau sur la plateforme.

---

> [!TIP]
> **Conseil de pro** : Utilisez le débugger (exécution pas-à-pas) pour voir l'évolution de vos variables en temps réel et comprendre comment vos boucles ou vos tris fonctionnent !

> [!IMPORTANT]
> N'oubliez pas que les index de tableaux commencent généralement à **1** dans notre langage pseudo-code.
