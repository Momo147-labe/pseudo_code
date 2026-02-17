# 📘 Guide général

## Vue d'ensemble de l'application

**Pseudo Code** est une extension VSCode complète pour l'apprentissage et la pratique de :
- 🧮 Algorithmes et structures de données
- 🗂️ Méthode Merise (MCD, MLD, MPD)
- 📊 Théorie des graphes

![Interface principale](../images/screenshots/main-interface.png)

## 🖥️ Interface utilisateur

### Barre d'outils principale

La barre d'outils se trouve en haut de l'éditeur :

![Barre d'outils](../images/screenshots/toolbar.png)

| Icône | Fonction | Raccourci |
|-------|----------|-----------|
| 📄 | Nouveau fichier | `Ctrl+N` |
| 💾 | Sauvegarder | `Ctrl+S` |
| ▶️ | Exécuter | `F5` |
| 🐛 | Déboguer | `F9` |
| ⚙️ | Paramètres | `Ctrl+,` |

### Panneau latéral

Le panneau latéral offre un accès rapide aux principales fonctionnalités :

![Panneau latéral](../images/screenshots/sidebar.png)

- **Explorer** : Parcourir vos fichiers
- **Exemples** : Bibliothèque d'exemples
- **Défis** : Exercices et challenges
- **Historique** : Projets récents

### Palette de commandes

> [!TIP]
> Accédez à toutes les fonctionnalités via `Ctrl+Shift+P`

Commandes principales :
```
Pseudo Code: Nouvel Algorithme
Pseudo Code: Nouveau diagramme Merise
Pseudo Code: Nouveau Graphe
Pseudo Code: Ouvrir un exemple
Pseudo Code: Lancer un défi
```

![Palette](../images/screenshots/command-palette.png)

## ⚙️ Paramètres et personnalisation

### Accéder aux paramètres

1. Ouvrez les paramètres : `Ctrl+,`
2. Recherchez "Pseudo Code"
3. Modifiez les paramètres selon vos préférences

![Paramètres](../images/screenshots/settings.png)

### Paramètres principaux

#### Thème de l'éditeur

```json
{
  "pseudoCode.theme": "dark", // ou "light"
  "pseudoCode.editorFontSize": 14,
  "pseudoCode.editorFontFamily": "Fira Code, monospace"
}
```

#### Langue de l'interface

```json
{
  "pseudoCode.language": "fr" // ou "en", "es", "de"
}
```

#### Comportement de l'exécution

```json
{
  "pseudoCode.autoSave": true,
  "pseudoCode.debugMode": "step-by-step",
  "pseudoCode.showComplexity": true
}
```

#### Visualisation des graphes

```json
{
  "pseudoCode.graph.layout": "force-directed",
  "pseudoCode.graph.theme": "modern",
  "pseudoCode.graph.animationSpeed": "normal"
}
```

## 🎯 Système de défis

### Accéder aux défis

1. Cliquez sur l'icône **Défis** 🏆 dans la barre latérale
2. Parcourez les catégories :
   - 🥉 **Débutant**
   - 🥈 **Intermédiaire**
   - 🥇 **Avancé**
   - 💎 **Expert**

![Défis](../images/screenshots/challenges.png)

### Lancer un défi

1. Sélectionnez un défi
2. Lisez l'énoncé et les contraintes
3. Cliquez sur **Commencer**
4. Codez votre solution
5. Testez avec les cas de test fournis
6. Soumettez votre solution

![Défi en cours](../images/screenshots/challenge-progress.png)

### Système de points

> [!NOTE]
> Gagnez des points en complétant les défis !

- 🥉 Défi débutant : 10 points
- 🥈 Défi intermédiaire : 25 points
- 🥇 Défi avancé : 50 points
- 💎 Défi expert : 100 points

**Bonus :**
- ⚡ Solution optimale : +20%
- 🏃 Premier essai : +10%
- 💡 Sans indice : +15%

## 📚 Bibliothèque d'exemples

### Explorer les exemples

Accédez à plus de **50 exemples** couvrant :

**Algorithmes :**
- Tri (bulles, insertion, rapide, fusion)
- Recherche (linéaire, dichotomique)
- Structures de données (piles, files, arbres)

**Merise :**
- E-commerce
- Bibliothèque
- Gestion scolaire
- Hôpital

**Graphes :**
- Plus court chemin
- Arbre couvrant
- Réseau social
- Ordonnancement

![Exemples](../images/screenshots/examples-library.png)

### Importer un exemple

1. Cliquez sur **Exemples** dans la barre latérale
2. Sélectionnez un exemple
3. Cliquez sur **Importer**
4. L'exemple s'ouvre dans un nouvel onglet

## 🔍 Recherche et aide

### Recherche intelligente

Utilisez `Ctrl+F` pour rechercher :
- Dans votre code
- Dans les exemples
- Dans la documentation

![Recherche](../images/screenshots/search.png)

### Aide contextuelle

> [!TIP]
> Survolez un mot-clé pour afficher l'aide contextuelle.

- Syntaxe du mot-clé
- Exemples d'utilisation
- Lien vers la documentation

![Aide contextuelle](../images/screenshots/help-tooltip.png)

### Documentation intégrée

Appuyez sur `F1` sur n'importe quel mot-clé pour ouvrir la documentation complète.

## 📊 Statistiques et progression

### Tableau de bord

Accédez à vos statistiques via **Vue** → **Tableau de bord**

![Tableau de bord](../images/screenshots/dashboard.png)

**Métriques affichées :**
- 📈 Défis complétés
- ⏱️ Temps total de pratique
- 🏆 Points gagnés
- 📊 Niveau actuel
- 🎯 Objectifs hebdomadaires

### Historique d'activité

Consultez votre historique :
- Projets récents
- Défis tentés
- Temps passé par catégorie

## 💾 Gestion des fichiers

### Sauvegarder votre travail

> [!IMPORTANT]
> Activez la sauvegarde automatique dans les paramètres.

```json
{
  "pseudoCode.autoSave": true,
  "pseudoCode.autoSaveDelay": 1000 // en ms
}
```

### Exporter vos projets

**Formats d'export disponibles :**
- **PDF** : Document imprimable
- **PNG** : Images des diagrammes
- **HTML** : Page web interactive
- **ZIP** : Archive complète du projet

### Partager votre code

1. Cliquez sur **Partager** 🔗
2. Choisissez la méthode :
   - Lien public
   - QR Code
   - Export GitHub Gist

![Partage](../images/screenshots/share.png)

## 🎨 Raccourcis clavier

### Raccourcis essentiels

| Action | Raccourci |
|--------|-----------|
| Nouvelle ligne | `Ctrl+Enter` |
| Commenter | `Ctrl+/` |
| Indenter | `Tab` |
| Désindenter | `Shift+Tab` |
| Dupliquer ligne | `Ctrl+D` |
| Supprimer ligne | `Ctrl+Shift+K` |
| Chercher/Remplacer | `Ctrl+H` |

### Raccourcis de navigation

| Action | Raccourci |
|--------|-----------|
| Aller à la ligne | `Ctrl+G` |
| Définition | `F12` |
| Retour | `Alt+←` |
| Avant | `Alt+→` |

### Raccourcis d'exécution

| Action | Raccourci |
|--------|-----------|
| Exécuter | `F5` |
| Pas à pas | `F10` |
| Entrer dans | `F11` |
| Stop | `Shift+F5` |

## 🎥 Tutoriel vidéo général

![Présentation complète](../videos/tutorials/general-overview.mp4)
*Durée : 15 minutes - Tour complet de l'application*

## 💡 Astuces et conseils

### Productivité

> [!TIP]
> **Multi-curseurs** : `Alt+Click` pour placer plusieurs curseurs

### Optimisation

- Utilisez les **snippets** pour coder plus vite
- Profitez de l'**auto-complétion** avec `Ctrl+Space`
- Activez le **formatage automatique** à la sauvegarde

### Apprentissage

- Commencez par les défis débutants
- Analysez les exemples fournis
- Consultez la complexité de vos algorithmes

## 🆘 Support et communauté

### Obtenir de l'aide

- 📖 [Documentation complète](../README.md)
- 💬 [Forum communautaire](https://forum.pseudocode.app)
- 🐛 [Signaler un bug](https://github.com/pseudocode/issues)
- ✉️ [Contact support](mailto:support@pseudocode.app)

### Contribuer

Vous souhaitez contribuer au projet ? Consultez notre [guide de contribution](../contributing.md).

---

[⬅️ Retour : Graphes](./graphe.md) | [Retour à l'accueil 🏠](../README.md)
