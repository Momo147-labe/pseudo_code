# 📊 Graphes - Guide utilisateur

## Introduction aux graphes

Un **graphe** est une structure composée de **sommets** (ou nœuds) reliés par des **arêtes** (ou arcs). Les graphes permettent de modéliser de nombreux problèmes réels.

![Exemple de graphe](../images/screenshots/graph-example.png)

## 🎯 Créer un graphe

### Ouvrir l'éditeur de graphes

1. Ouvrez la palette de commandes (`Ctrl+Shift+P`)
2. Tapez `Pseudo Code: Nouveau Graphe`
3. Choisissez le type de graphe :
   - **Non orienté** : Les arêtes n'ont pas de direction
   - **Orienté** : Les arcs ont une direction
   - **Pondéré** : Les arêtes/arcs ont un poids

![Nouveau graphe](../images/screenshots/new-graph.png)

## 🔵 Ajouter des sommets

### Créer un sommet

1. Cliquez sur l'outil **Sommet** dans la barre d'outils
2. Cliquez sur le canvas pour placer le sommet
3. Nommez le sommet (A, B, C, ou des noms personnalisés)

![Création de sommet](../images/screenshots/create-vertex.png)

> [!TIP]
> Double-cliquez sur un sommet pour modifier son nom ou ses propriétés.

### Propriétés des sommets

Chaque sommet peut avoir :
- **Nom/Label** : Identifiant du sommet
- **Couleur** : Pour la visualisation
- **Données** : Informations supplémentaires

## ➡️ Ajouter des arêtes

### Créer une arête/arc

1. Cliquez sur l'outil **Arête**
2. Cliquez sur le sommet de départ
3. Cliquez sur le sommet d'arrivée
4. Pour un graphe pondéré, entrez le poids

![Création d'arête](../images/screenshots/create-edge.png)

### Graphe orienté vs non orienté

**Graphe non orienté :**
```
    A ───── B
     \     /
      \   /
       \ /
        C
```

**Graphe orienté :**
```
    A ────> B
     ↓     ↗
     ↓   ↗
     ↓ ↗
      C
```

![Orienté vs non orienté](../images/screenshots/directed-vs-undirected.png)

## 🎨 Algorithmes sur les graphes

### Parcours en profondeur (DFS)

> [!NOTE]
> DFS explore le graphe en allant le plus loin possible avant de revenir en arrière.

1. Sélectionnez votre graphe
2. Cliquez sur **Algorithmes** → **DFS**
3. Choisissez le sommet de départ
4. Visualisez le parcours animé

![DFS Animation](../images/screenshots/dfs-animation.png)

**Ordre de visite :** A → B → D → E → C

### Parcours en largeur (BFS)

Le BFS explore le graphe niveau par niveau.

1. Cliquez sur **Algorithmes** → **BFS**
2. Choisissez le sommet de départ
3. Observez l'exploration par niveaux

![BFS Animation](../images/screenshots/bfs-animation.png)

**Ordre de visite :** A → B → C → D → E

### Plus court chemin (Dijkstra)

> [!IMPORTANT]
> L'algorithme de Dijkstra trouve le plus court chemin dans un graphe pondéré.

1. Créez un graphe pondéré
2. Cliquez sur **Algorithmes** → **Dijkstra**
3. Sélectionnez le sommet de départ
4. Sélectionnez le sommet d'arrivée
5. L'algorithme affiche le chemin optimal

![Dijkstra](../images/screenshots/dijkstra.png)

**Exemple :**
```
    A ─5─ B
    │     │
    2     3
    │     │
    C ─1─ D

Chemin le plus court A → D : A → C → D (poids: 3)
```

### Arbre couvrant minimal (Kruskal/Prim)

Pour trouver l'arbre couvrant de poids minimal :

1. **Algorithmes** → **Kruskal** ou **Prim**
2. L'algorithme sélectionne les arêtes de poids minimal
3. Le résultat est affiché en surbrillance

![MST](../images/screenshots/mst.png)

### Détection de cycles

Détectez automatiquement les cycles dans votre graphe :

1. **Algorithmes** → **Détecter les cycles**
2. Les cycles sont mis en évidence

![Cycles](../images/screenshots/cycles.png)

## 📊 Types de graphes spéciaux

### Arbre binaire

Pour créer un arbre binaire :

1. Cliquez sur **Templates** → **Arbre binaire**
2. Définissez la racine
3. Ajoutez les nœuds gauche et droit

![Arbre binaire](../images/screenshots/binary-tree.png)

### Graphe complet

Un graphe où chaque sommet est relié à tous les autres :

![Graphe complet](../images/screenshots/complete-graph.png)

### Graphe biparti

Graphe dont les sommets peuvent être divisés en deux ensembles :

![Graphe biparti](../images/screenshots/bipartite-graph.png)

## 🎨 Visualisation et personnalisation

### Disposition automatique

> [!TIP]
> Utilisez les algorithmes de disposition pour organiser votre graphe.

- **Circulaire** : Sommets en cercle
- **Hiérarchique** : Pour les arbres
- **Force-directed** : Disposition naturelle
- **Grille** : Alignement régulier

![Layouts](../images/screenshots/layouts.png)

### Styles et couleurs

Personnalisez l'apparence :
- Couleur des sommets
- Épaisseur des arêtes
- Style des flèches
- Thème global (clair/sombre)

![Styles](../images/screenshots/graph-styles.png)

## 💾 Export et matrice d'adjacence

### Matrice d'adjacence

Affichez la représentation matricielle :

```
    A  B  C  D
A [ 0  1  1  0 ]
B [ 1  0  1  1 ]
C [ 1  1  0  1 ]
D [ 0  1  1  0 ]
```

![Matrice](../images/screenshots/adjacency-matrix.png)

### Liste d'adjacence

```
A: [B, C]
B: [A, C, D]
C: [A, B, D]
D: [B, C]
```

### Export

Exportez votre graphe en :
- **PNG/SVG** : Image
- **JSON** : Format de données
- **GraphML** : Format standard
- **DOT** : Pour Graphviz

## 🎥 Tutoriel vidéo

![Tutoriel graphes](../videos/tutorials/graph-tutorial.mp4)
*Durée : 10 minutes - Créer un graphe et appliquer Dijkstra*

## 💡 Exemples fournis

- 🗺️ **Réseau routier** : Plus court chemin entre villes
- 🌐 **Réseau social** : Connexions entre utilisateurs
- 🔄 **Ordonnancement** : Graphe de dépendances de tâches
- 🌳 **Arbre généalogique** : Relations familiales

## 🆘 Problèmes courants

### L'arête ne se crée pas

> [!WARNING]
> Vérifiez que vous avez bien cliqué sur deux sommets distincts.

### L'animation ne démarre pas

Assurez-vous d'avoir sélectionné un sommet de départ.

### Le graphe est trop dense

Utilisez la disposition **Force-directed** pour éclaircir la visualisation.

---

[⬅️ Retour : Merise](./merise.md) | [Suivant : Guide général ➡️](./general.md)
