# 🧮 Algorithmes - Guide utilisateur

## Introduction

Les algorithmes sont au cœur de la programmation. Cette section vous guide à travers les différentes fonctionnalités liées aux algorithmes dans **Pseudo Code**.

![Exemple d'algorithme](../images/screenshots/algo-example.png)

## 🎯 Créer un algorithme

### Étape 1 : Nouveau fichier

1. Ouvrez la palette de commandes (`Ctrl+Shift+P`)
2. Tapez `Pseudo Code: Nouvel Algorithme`
3. Choisissez un template :
   - **Vide** : Pour commencer de zéro
   - **Tri** : Template pour algorithmes de tri
   - **Recherche** : Template pour recherche
   - **Récursif** : Template pour algorithmes récursifs

![Création d'algorithme](../images/screenshots/new-algo.png)

### Étape 2 : Écrire le pseudo-code

Utilisez la syntaxe simplifiée :

```
ALGORITHME TriBulles
VARIABLES
    tableau : TABLEAU d'ENTIERS
    i, j, temp : ENTIER
DEBUT
    POUR i DE 0 À longueur(tableau) - 1 FAIRE
        POUR j DE 0 À longueur(tableau) - i - 1 FAIRE
            SI tableau[j] > tableau[j + 1] ALORS
                temp ← tableau[j]
                tableau[j] ← tableau[j + 1]
                tableau[j + 1] ← temp
            FIN SI
        FIN POUR
    FIN POUR
FIN
```

## 🎨 Fonctionnalités

### Coloration syntaxique

> [!TIP]
> Tous les mots-clés sont automatiquement colorés pour une meilleure lisibilité.

- **Mots-clés** : `ALGORITHME`, `DEBUT`, `FIN`, `SI`, `ALORS`, `POUR`, etc.
- **Types** : `ENTIER`, `REEL`, `CHAINE`, `BOOLEEN`, `TABLEAU`
- **Opérateurs** : `←`, `+`, `-`, `*`, `/`, `ET`, `OU`, `NON`

### Auto-complétion

Tapez les premières lettres et appuyez sur `Ctrl+Space` pour afficher les suggestions :

![Auto-complétion](../images/screenshots/autocomplete.png)

### Vérification de syntaxe

L'extension détecte automatiquement les erreurs :

![Erreurs de syntaxe](../images/screenshots/syntax-errors.png)

## 🎬 Exécution et visualisation

### Exécuter l'algorithme

1. Cliquez sur l'icône **▶️ Exécuter** en haut à droite
2. Entrez les données de test si nécessaire
3. Visualisez l'exécution pas à pas

![Exécution](../images/screenshots/execution.png)

### Mode pas à pas (Débogage)

> [!NOTE]
> Le mode pas à pas vous permet de suivre l'exécution ligne par ligne.

- **F10** : Ligne suivante
- **F11** : Entrer dans une fonction
- **Shift+F11** : Sortir d'une fonction
- **F5** : Continuer

### Visualisation des variables

Pendant l'exécution, vous pouvez voir :
- Les valeurs des variables
- L'état de la pile d'appels
- Les sorties du programme

![Variables](../images/screenshots/variables-view.png)

## 📊 Analyse de complexité

### Afficher la complexité

Cliquez sur **Analyser la complexité** pour obtenir :
- **Complexité temporelle** : O(n), O(n²), O(log n), etc.
- **Complexité spatiale** : Mémoire utilisée
- **Graphique de performance**

![Complexité](../images/screenshots/complexity.png)

## 💾 Exemples fournis

L'extension inclut plusieurs exemples :

### Algorithmes de tri
- Tri à bulles
- Tri par insertion
- Tri rapide (QuickSort)
- Tri fusion (MergeSort)

### Algorithmes de recherche
- Recherche linéaire
- Recherche dichotomique
- Recherche dans un arbre

### Structures de données
- Piles (Stack)
- Files (Queue)
- Listes chaînées
- Arbres binaires

## 🎥 Tutoriel vidéo

![Tutoriel algorithmes](../videos/tutorials/algo-tutorial.mp4)
*Durée : 5 minutes - Créer et exécuter votre premier algorithme*

## 🆘 Problèmes courants

### L'algorithme ne s'exécute pas

> [!WARNING]
> Vérifiez que :
> - Tous les `DEBUT` ont un `FIN` correspondant
> - Les variables sont déclarées avant utilisation
> - La syntaxe est correcte

### Erreur de syntaxe non détectée

Rechargez la fenêtre VSCode : `Ctrl+Shift+P` → `Reload Window`

---

[⬅️ Retour à l'accueil](../README.md) | [Suivant : Merise ➡️](./merise.md)
