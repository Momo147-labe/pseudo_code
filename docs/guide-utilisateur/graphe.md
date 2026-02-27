# 📊 Graphes — Guide Complet

Le module **Graph Studio** vous permet d'explorer la théorie des graphes de façon interactive. Construisez vos graphes visuellement, lancez des algorithmes animés et accédez à des dizaines d'analyses théoriques en temps réel.

---

## 🗺️ L'Interface

```
┌─────────────────────────────────────────────────┐
│  ⬡ Studio  | ↩ ↪ | + ⊕ | ψ ⚙ | Dijkstra | 📊 │  ← Barre d'outils
├─────────────────────────────────────────────────┤
│                                                  │
│            Canevas interactif (infini)           │  ← Zone de travail
│                                                  │
│                                      [Minimap]   │  ← Vue miniature
└─────────────────────────────────────────────────┘
```

---

## 🖱️ Manipulation du Canevas

### Navigation
| Geste | Action |
|---|---|
| `Molette souris` / `Pinch` | Zoom avant / arrière |
| `Clic + Glisser` sur le fond | Déplacer la vue (pan) |
| Boutons `+` / `-` dans la barre | Zoom via bouton |
| Minimap (coin bas-droit) | Vue d'ensemble du graphe |

### Création des éléments
| Geste | Action |
|---|---|
| **Double-clic** sur le fond | Ajouter un nouveau sommet |
| **Glisser** depuis le bouton `+` | Ajouter un sommet (drag & drop) |
| **Appui long + Glisser** sommet → sommet | Créer une arête |
| Bouton **⊕ Arête** dans la barre | Ajouter une arête via formulaire |

### Sélection et déplacement
| Geste | Action |
|---|---|
| **Clic** sur un sommet | Sélectionner un seul sommet |
| **Shift + Clic** / Mode multi-sélection | Ajouter à la sélection |
| **Glisser** sur le fond (mode Lasso) | Sélectionner une zone rectangulaire |
| **Glisser** un sommet | Déplacer le sommet (ou toute la sélection) |

> **Mode sélection multiple** : Cliquez sur l'icône ⧉ dans la barre d'outils ou maintenez `Shift` pour activer le lasso.

### Menus contextuels
- **Clic droit** sur un sommet → **Renommer**, Définir comme Départ/Arrivée, Supprimer
- **Clic droit** sur une arête → Supprimer
- **Double-clic** sur une arête → Modifier le poids

---

## ⚙️ Configuration du Graphe

Ouvrez **Outils > Configuration** pour ajuster :

| Option | Description |
|---|---|
| **Graphe Orienté** | Active les flèches directionnelles sur les arêtes |
| **Graphe Pondéré** | Active la saisie de poids sur les arêtes |
| **Aligner sur la grille** | Magnétisme des sommets pour un placement régulier |

---

## 🛠️ Barre d'Outils — Détail

| Icône | Fonction |
|---|---|
| ↩ **Annuler** | Revenir en arrière (Undo) |
| ↪ **Rétablir** | Refaire l'action annulée (Redo) |
| **+ Sommet** | Ajouter un sommet (clic) ou glisser sur le canevas |
| **⊕ Arête** | Ajouter une arête via un formulaire de sélection |
| **ψ Algorithmes** | Lancer BFS, DFS, Dijkstra ou Détection de cycles |
| **⚙ Outils** | Graphe aléatoire, Organisation automatique, Tout effacer, Configuration |
| **Dijkstra** | Ouvrir/Fermer le panneau de résultat Dijkstra |
| **📊 Analyse** | Ouvrir/Fermer le panneau d'analyse théorique |
| **🔍+ / 🔍-** | Zoom avant / arrière |
| **⧉ Multi-select** | Activer le mode multi-sélection (Lasso) |
| ▶ **Exécuter** | Lancer une animation BFS depuis le premier sommet |
| ⏸ **Pause / Reprendre** | Contrôler l'animation en cours |
| ⏹ **Arrêter** | Stopper l'algorithme en cours |
| 💾 **Sauvegarder** | Exporter le graphe en JSON |
| 🖼️ **Exporter PNG** | Capturer le canevas en image |

---

## 🎬 Algorithmes Animés

### 1. BFS — Parcours en Largeur
- **Comment** : Menu **Algorithmes > BFS** ou bouton ▶ (Exécuter)
- **Principe** : Explore tous les voisins d'un sommet avant de passer au niveau suivant.
- **Utilité** : Plus court chemin en nombre de sauts (graphes non pondérés), recherche de connexité.
- **Animation** : Les sommets visitées s'illuminent **couche par couche** (vague circulaire).

### 2. DFS — Parcours en Profondeur
- **Comment** : Menu **Algorithmes > DFS**
- **Principe** : Explore une branche entière avant de rebrousser chemin.
- **Utilité** : Détection de cycles, vérification de connexité, résolution de labyrinthes.
- **Animation** : L'animation suit un chemin continu en profondeur, puis revient sur ses pas.

### 3. Dijkstra — Plus Court Chemin Pondéré
- **Comment** : Menu **Algorithmes > Dijkstra** ou bouton **Dijkstra** dans la barre
- **Principe** : Calcule le chemin de coût minimal entre un sommet source et tout le reste du graphe.
- **Utilité** : GPS, routage réseau (OSPF), planification de trajets.
- **Prérequis** : Tous les poids doivent être **positifs**. Activer le mode **Graphe Pondéré**.
- **Panneau Dijkstra** : Affiche le tableau des distances et le chemin optimal vers chaque sommet.

### 4. Détection de Cycles
- **Comment** : Menu **Algorithmes > Détection Cycles**
- **Principe** : Vérifie si le graphe contient au moins un cycle.
- **Résultat** : Un message s'affiche indiquant si un cycle a été trouvé ou non.

### 5. Organisation Automatique
- **Comment** : Menu **Outils > Organisation Automatique**
- **Description** : Replace automatiquement les sommets de manière lisible (algorithme de force dirigée).

---

## 🔬 Panneau d'Analyse Théorique

Cliquez sur **📊 Analyse** dans la barre d'outils pour ouvrir le panneau d'analyse. Il comporte **6 onglets** détaillés ci-dessous.

---

### Onglet 1 : Résumé

Vue d'ensemble des propriétés globales du graphe calculées en temps réel.

#### Propriétés Globales

| Propriété | Description |
|---|---|
| **Ordre (n)** | Nombre total de sommets |
| **Taille (m)** | Nombre total d'arêtes |
| **Densité** | Rapport arêtes existantes / arêtes possibles. Un graphe complet a une densité de 1. |
| **Type** | Orienté ou Non-orienté |
| **Structure** | Simple (pas de doublons) ou Multiple (multi-arêtes) |
| **Biparti** | `Oui` si les sommets peuvent être divisés en 2 groupes sans arête interne à un groupe |
| **Nombre Cyclomatique** | Aussi appelé *circuit rank* : `m - n + composantes`. Indique la complexité (nombre de cycles indépendants). |

#### Sous-graphe Induit (Sélection)

Si vous avez sélectionné des sommets, ce bloc apparaît et affiche :
- **Ordre (n')** : Nombre de sommets sélectionnés
- **Taille (m')** : Nombre d'arêtes entre ces sommets uniquement

#### Connectivité

| Propriété | Description |
|---|---|
| **Connexe** | `Oui` si tous les sommets sont reliés par un chemin |
| **Fortement Connexe** *(orienté)* | `Oui` si un chemin existe dans **les deux sens** entre chaque paire |
| **Nombre de Composantes** | Nombre de sous-graphes connexes distincts |
| **Détail des composantes** | Liste des sommets appartenant à chaque composante (G1, G2, …) |

#### Sommets Spéciaux

- **Isolés** : Sommets sans aucune arête. Count + liste affichés en orange.

---

### Onglet 2 : Sommets

Détail des métriques pour **chaque sommet individuel**.

| Indicateur | Description |
|---|---|
| **d⁻ (Degré entrant)** | Nombre d'arêtes arrivant sur ce sommet (en vert) |
| **d⁺ (Degré sortant)** | Nombre d'arêtes partant de ce sommet (en orange) |
| **Ecc (Excentricité)** | Distance maximale vers les autres sommets. L'excentricité minimale = rayon, l'excentricité maximale = diamètre. |
| **Voisinage sortant** | Liste des sommets directement accessibles depuis ce sommet |

> Les sommets sélectionnés sont marqués d'une étoile **★**.

---

### Onglet 3 : Matrices

Affiche les 3 représentations matricielles du graphe, toutes défilables horizontalement.

#### Matrice d'Adjacence (A)

- Un tableau carré N×N.
- `A[i][j] = 1` s'il existe un lien de `i` vers `j`, sinon `0`.
- En mode **pondéré**, les valeurs sont les poids des arêtes.
- **Usage** : Vérifier rapidement si deux sommets sont voisins. Idéal pour graphes denses.

#### Matrice d'Incidence (M)

- Un tableau N×M (sommets × arêtes).
- Chaque colonne représente une arête. Pour un graphe **non-orienté** : `+1` si le sommet est incident à l'arête.
- Pour un graphe **orienté** : `+1` pour le sommet de départ, `-1` pour le sommet d'arrivée.
- **Usage** : Représentation canonique en algèbre des graphes.

#### Matrice de Degré (D)

- Une matrice diagonale N×N.
- `D[i][i]` = degré du sommet `i`, zéros ailleurs.
- **Usage** : Utilisée en combinaison avec la matrice d'adjacence pour calculer le Laplacien du graphe (`L = D - A`).

---

### Onglet 4 : Distances

Affiche la **Matrice des Distances** calculée par l'algorithme Floyd-Warshall.

- Chaque cellule `[i][j]` indique le **plus court chemin** (en nombre de sauts) entre les sommets `i` et `j`.
- `0` en diagonale (distance de soi à soi).
- `∞` si aucun chemin n'existe entre deux sommets (graphe non connexe).
- Les en-têtes de lignes et colonnes affichent les labels des sommets.

**Propriétés déduites :**
- **Rayon** : Minimum des excentricités (voir onglet Sommets)
- **Diamètre** : Maximum des excentricités = la plus grande distance entre deux sommets connexes
- **Centre** : Sommet(s) dont l'excentricité est égale au rayon

---

### Onglet 5 : Cycles

Affiche la **Base des Cycles Fondamentaux** du graphe.

- Un cycle fondamental est un cycle simple qu'on ne peut pas exprimer comme combinaison d'autres cycles plus petits.
- Leur nombre est égal au **Nombre Cyclomatique** visible dans l'onglet Résumé.

Pour chaque cycle :
- **Chemin** : Séquence des labels de sommets (`A - B - C - A`)
- **Vecteur associé** : Représentation binaire du cycle dans l'espace des arêtes (vecteur d'incidence). Utile pour les calculs algébriques sur les graphes.

> Si le graphe est acyclique (un arbre), cet onglet affiche `Aucun cycle détecté.`

---

### Onglet 6 : Listes

Deux représentations textuelles classiques du graphe.

#### Liste d'Adjacence

Pour chaque sommet, liste ses voisins (sortants) sous la forme :

```
A : { B, C }
B : { C }
C : { }
```

- **Usage** : Représentation préférée pour les graphes **clairsemés** (peu d'arêtes). Très économe en mémoire.
- Format affiché en `monospace` pour faciliter la copie.

#### Dictionnaire des Arêtes

Liste toutes les arêtes du graphe sous forme de paires ou triplets :

```
(A, B, poids: 5.0)
(B, C, poids: 2.0)
```

- Pratique pour exporter ou vérifier manuellement la structure du graphe.

---

## 💾 Import / Export

| Action | Description |
|---|---|
| 💾 **Sauvegarder JSON** | Exporte le graphe (sommets, arêtes, poids, positions) en JSON dans le fichier du projet |
| 🖼️ **Exporter PNG** | Capture une image du canevas actuel (vue actuelle) |

---

## 🚀 Cas d'Usage Pratiques

| Domaine | Application |
|---|---|
| **Réseau Social** | Sommets = profils, Arêtes = amitiés. BFS pour suggérer des amis ("les amis de mes amis") |
| **GPS / Logistique** | Sommets = villes, Arêtes pondérées = distances. Dijkstra pour le trajet optimal |
| **Réseau Informatique** | Sommets = routeurs. BFS pour vérifier la connectivité, Dijkstra pour le routage OSPF |
| **Détection d'erreurs** | Cycles dans un graphe de dépendances → dépendance circulaire |
| **Compilation** | Tri topologique (DFS) pour ordonner les étapes de compilation |
| **Web / PageRank** | Google classe les pages via des variantes d'algorithmes de graphes |

---

[⬅️ Retour : Merise](./merise.md) | [Suivant : Guide Général 🏠](./general.md)
