# 📊 Graphes - Guide de Théorie et Visualisation

Le module **Graphes** vous permet d'explorer la théorie des graphes de manière interactive. Dessinez vos structures et lancez des algorithmes célèbres pour voir comment ils fonctionnent étape par étape.

---

## 🔵 Concepts Fondamentaux

- **Sommet (Node)** : Représente un point ou un objet (ex: une ville, un routeur).
- **Arête / Arc (Edge)** : Représente le lien entre deux sommets. On parle d'**Arc** si le lien est orienté (une seule direction).
- **Poids (Weight)** : Une valeur numérique associée à un lien, représentant souvent une distance, un coût ou une durée.

---

## 🎯 Manipuler l'Éditeur

### Création Rapide
- **Ajouter un sommet** : Double-cliquez n'importe où sur le canevas.
- **Relier deux sommets** : Cliquez sur un sommet, maintenez le bouton et faites glisser le lien vers le sommet de destination.
- **Supprimer** : Sélectionnez un élément et appuyez sur la touche `Suppr` (ou icône corbeille sur mobile).

### Paramètres du Graphe
Via le panneau de propriétés, vous pouvez passer le graphe en mode :
- **Orienté** (Flèches)
- **Non-orienté** (Traits simples)
- **Pondéré** (Saisie des poids activée)

---

## 🎨 Algorithmes Incontournables

L'application permet d'animer les algorithmes suivants pour mieux comprendre leur logique :

### 1. Parcours en Largeur (BFS - Breadth First Search)
- **Principe** : Explore les voisins immédiats avant de passer au niveau suivant.
- **Utilité** : Trouver le chemin le plus court dans un graphe non pondéré (nombre minimal de sauts).
- **Visualisation** : Les sommets s'allument "couche par couche" autour du sommet de départ.

### 2. Parcours en Profondeur (DFS - Depth First Search)
- **Principe** : Explore une branche le plus loin possible avant de rebrousser chemin.
- **Utilité** : Détecter des cycles, tester la connexité ou résoudre des labyrinthes.
- **Visualisation** : L'animation suit un long chemin continu jusqu'à un cul-de-sac.

### 3. Plus Court Chemin (Dijkstra)
- **Principe** : Calcule le chemin de poids minimal entre un départ et une destination.
- **Utilité** : GPS (Google Maps), routage réseau (OSPF).
- **Attention** : Ne fonctionne que si tous les poids sont positifs !

---

## 🔬 Représentations Informatiques

L'application peut générer automatiquement deux types de représentations pour vos algorithmes :

### Matrice d'Adjacence
Un tableau carré où `A[i][j] = 1` si un lien existe entre `i` et `j`. Idéal pour les graphes denses.

### Liste d'Adjacence
Pour chaque sommet, on liste ses voisins. Plus efficace en mémoire pour les graphes clairsemés (peu de liens).

---

## 🚀 Cas de Usage Pratiques

- **Réseau Social** : Les profils sont les sommets, les amitiés sont les arêtes. Utile pour suggérer des amis ("les amis de mes amis").
- **Logistique** : Optimiser les tournées de livraison en minimisant la distance totale.
- **Web** : Le moteur de recherche Google utilise des variantes d'algorithmes de graphes (PageRank) pour classer les pages.

---

[⬅️ Retour : Merise](./merise.md) | [Suivant : Guide Général 🏠](./general.md)
