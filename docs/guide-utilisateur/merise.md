# 🗂️ Merise — Guide Complet de Modélisation

**MERISE Studio** est un outil de conception de bases de données relationnelles intégré à l'application. Il vous guide de l'idée initiale jusqu'au code SQL prêt à l'emploi.

---

## 🗺️ Navigation — La Barre Latérale

La navigation se fait via la barre latérale (sidebar) à gauche, organisée en 3 sections :

### Conception
| Vue | Description |
|---|---|
| 📋 **Règles de gestion** | Saisir et organiser les règles métier avant de modéliser |
| 🔷 **MCD** | Éditeur visuel du Modèle Conceptuel de Données |
| 📖 **Dictionnaire** | Répertoire complet de tous les attributs et entités |

### Conception Avancée
| Vue | Description |
|---|---|
| 🌿 **MLD** | Modèle Logique de Données généré automatiquement |
| 🗄️ **MPD** | Code SQL généré (avec coloration syntaxique) |

### Outils & Analyse
| Vue | Description |
|---|---|
| ≡ **Normalisation** | Analyse des formes normales (1FN, 2FN, 3FN) |
| 🔗 **Requêtes & jointures** | Générateur de requêtes SQL visuelles |
| ▶️ **Simulation** | Simulateur de données avec tables et export |

---

## 📋 Vue : Règles de Gestion

Les règles de gestion sont l'étape **zéro** de la méthode Merise. Avant de dessiner quoi que ce soit, vous listez les règles métier du système à modéliser (ex: *"Un client peut passer plusieurs commandes"*, *"Un article appartient à une seule catégorie"*).

Ces règles guident ensuite la conception du MCD.

---

## 🔷 Vue : MCD (Modèle Conceptuel de Données)

C'est le cœur de MERISE Studio. Le MCD représente les données du monde réel sous forme de diagramme.

### Concepts fondamentaux

#### Entités
- Une entité représente un objet du monde réel (ex: `CLIENT`, `COMMANDE`, `PRODUIT`).
- Elle est représentée par un **rectangle** avec son nom en en-tête.
- Elle possède des **attributs** (propriétés).
- Chaque entité doit avoir un **identifiant** (clé primaire), affiché souligné.

#### Associations
- Une association exprime un lien entre entités (ex: `Passer`, `Contenir`).
- Elle est représentée par une **ellipse** ou un losange.
- Elle possède des **cardinalités** aux deux extrémités.

#### Cardinalités

| Notation | Signification |
|---|---|
| `0,1` | Au plus une fois (0 ou 1) |
| `1,1` | Exactement une fois |
| `0,N` | Zéro ou plusieurs fois |
| `1,N` | Au moins une fois (1 ou plus) |

### Créer des éléments

#### Sur Desktop
| Action | Résultat |
|---|---|
| **Glisser "Nouvelle Entité"** depuis la palette | Créer une entité à l'emplacement déposé |
| **Glisser "Nouvelle Relation"** depuis la palette | Créer une association |
| **Cliquer "Outil Lien"** puis cliquer sur 2 éléments | Relier une entité et une association |
| **Double-clic** sur le canevas | Ajouter une entité rapidement |
| **Clic droit** sur un élément | Menu contextuel (Dupliquer, Supprimer, etc.) |

#### Sur Mobile
| Action | Résultat |
|---|---|
| Bouton FAB **+** (bas droit) | Menu pour créer entité, relation ou activer le lien |
| **⊕ Entité** | Créer une entité au centre |
| **⊕ Relation** | Créer une association au centre |
| **🔗 Outil Lien** | Activer le mode lien (appui sur 2 éléments puis lier) |

### Navigation sur le canevas

| Geste | Action |
|---|---|
| `Pinch` / Molette | Zoom avant / arrière |
| Glisser sur le fond | Déplacer la vue |
| Clic sur un élément | Sélectionner |
| `Ctrl+A` | Tout sélectionner |
| Glisser un élément | Déplacer |
| Flèches directionnelles | Déplacer la sélection de 10px |
| `Suppr` | Supprimer la sélection |
| `Ctrl+Z` / `Ctrl+Y` | Annuler / Rétablir |

### Panneau Propriétés (Détails d'un élément)

Quand vous sélectionnez une entité ou une association, le panneau de propriétés s'ouvre à droite (Desktop) ou en bas (Mobile) :

#### Pour une Entité
- **Nom** : Renommer l'entité
- **Identifiant** : Choisir ou créer l'attribut clé primaire (souligné)
- **Attributs** : Ajouter, supprimer, réorganiser (nom + type de données)
- **Types disponibles** : `VARCHAR`, `INT`, `DATE`, `BOOLEAN`, `FLOAT`, `TEXT`, `DATETIME`, `EMAIL`, `PHONE`...

#### Pour une Association
- **Nom** : Renommer l'association
- **Cardinalités** : Définir les cardinalités de chaque côté (ex: `1,N` côté Client, `0,N` côté Produit)
- **Attributs propres** : Ajouter des attributs à l'association (utile pour les N:N)

---

## 📖 Vue : Dictionnaire

Le dictionnaire est un répertoire **automatiquement généré** de tous les attributs de votre MCD.

Pour chaque attribut il indique :
- L'entité à laquelle il appartient
- Son nom
- Son type de données
- S'il est identifiant (clé primaire)

> Utile pour s'assurer de la cohérence des noms et des types avant de passer au MLD.

---

## 🌿 Vue : MLD (Modèle Logique de Données)

Le MLD est **généré automatiquement** depuis votre MCD. Il représente la structure en tables relationnelles.

### Règles de transformation appliquées

| Règle | Description |
|---|---|
| **Règle 1** | Toute entité → Table avec ses attributs et sa clé primaire |
| **Règle 2** | Association binaire `1,1` → Clé étrangère dans la table concernée |
| **Règle 3** | Association `N:N` ou n-aire → Table d'association avec clés composées |
| **Règle 4** | Association réflexive → Table distincte |

### Lecture du MLD

Chaque **table** est affichée sous forme de carte avec :
- 🗝️ **Clé primaire** (PK) — icône dorée
- 🔗 **Clé étrangère** (FK) — icône bleue, avec référence vers l'autre table
- Les autres colonnes avec leur type de données
- Section **CONTRAINTES** listant les `FOREIGN KEY` et leurs références

> Bouton **Règles de transformation** dans cette vue : affiche un rappel des 4 règles appliquées.

---

## 🗄️ Vue : MPD (Modèle Physique de Données — SQL)

Le MPD génère le **code SQL prêt à l'emploi** pour créer votre base de données.

### SGBD supportés

Sélectionnez votre dialecte SQL avec les boutons en haut de la vue :

| SGBD | Spécificités générées |
|---|---|
| **MySQL** | Syntaxe MySQL, types `INT`, `VARCHAR`, backticks pour les noms |
| **PostgreSQL** | Syntaxe PostgreSQL, types natifs, guillemets pour les noms |
| **SQLite** | Syntaxe allégée, `PRAGMA foreign_keys = ON`, types flexibles |
| **SQL Server** | Syntaxe T-SQL, types `NVARCHAR`, `IDENTITY` |

### Fonctionnalités du MPD
- **Coloration syntaxique** : Mots-clés en bleu, chaînes en vert, identifiants en violet, nombres en orange.
- **Sélectionnable** : Le code SQL peut être sélectionné et copié.
- **Bouton 📋 Copier** : Copie tout le code SQL dans le presse-papier en un clic.

### Exemple de sortie (MySQL)
```sql
CREATE TABLE `CLIENT` (
  `id_client` INT NOT NULL,
  `nom` VARCHAR(255),
  PRIMARY KEY (`id_client`)
);

CREATE TABLE `COMMANDE` (
  `id_commande` INT NOT NULL,
  `date_cmd` DATE,
  `id_client` INT,
  PRIMARY KEY (`id_commande`),
  FOREIGN KEY (`id_client`) REFERENCES `CLIENT`(`id_client`)
);
```

---

## ≡ Vue : Normalisation

Cet outil analyse automatiquement votre modèle et vérifie s'il respecte les **formes normales** de Codd.

| Forme Normale | Condition |
|---|---|
| **1ère Forme Normale (1FN)** | Tous les attributs sont atomiques (pas de groupes répétitifs) |
| **2ème Forme Normale (2FN)** | Tout attribut non-clé dépend de la **totalité** de la clé primaire |
| **3ème Forme Normale (3FN)** | Aucune dépendance transitive entre attributs non-clés |

Pour chaque entité, l'outil indique si elle est conforme à chaque forme normale et suggère des corrections si ce n'est pas le cas.

---

## 🔗 Vue : Requêtes & Jointures

Cet outil vous aide à **construire et comprendre** les requêtes SQL inter-tables.

### Types de jointures expliquées

| Type | Résultat |
|---|---|
| `INNER JOIN` | Lignes communes aux deux tables seulement |
| `LEFT JOIN` | Toutes les lignes de la table gauche + correspondances droite |
| `RIGHT JOIN` | Toutes les lignes de la table droite + correspondances gauche |
| `FULL OUTER JOIN` | Toutes les lignes des deux tables |

### Fonctionnalités
- Sélection visuelle des tables à joindre
- Choix des colonnes à afficher
- Condition de jointure (`ON table1.col = table2.col`)
- Génération SQL en temps réel avec coloration syntaxique

---

## ▶️ Vue : Simulation

Le simulateur vous permet de **peupler vos tables avec de fausses données** et de visualiser le résultat comme dans un vrai SGBD.

### Fonctionnalités
- **Génération automatique** de données cohérentes (noms, dates, emails, nombres)
- **Vue tableur** : Les données s'affichent table par table comme dans phpMyAdmin
- **Respect des contraintes** : Les clés étrangères pointent vers des enregistrements existants
- **Export** : Générer les instructions `INSERT INTO` correspondantes

---

## 💾 Sauvegarde et Format de Fichier

Les projets Merise sont sauvegardés dans des fichiers à l'extension `.csi` (Conception Système Informatique).

- Le fichier est **synchronisé en temps réel** avec l'éditeur de l'application.
- Vous pouvez ouvrir, fermer et rouvrir un `.csi` depuis le gestionnaire de fichiers intégré.
- L'historique **Annuler/Rétablir** (`Ctrl+Z` / `Ctrl+Y`) fonctionne sur toutes les actions de conception.

---

## 🏆 Bonnes Pratiques de Modélisation

> [!TIP]
> **Règle d'or** : Partez toujours des règles de gestion avant de dessiner le MCD.

- **Identifiants** : Préférez des identifiants techniques (`id_entite`) plutôt que des données métier instables (ex: le nom peut changer).
- **Attributs** : Ne stockez que ce qui ne peut pas être calculé.
- **Cardinalités** : Définissez-les en vous posant la question dans chaque sens : *"Un CLIENT peut passer combien de COMMANDES ?"* et *"Une COMMANDE appartient à combien de CLIENTS ?"*.
- **Normalisation** : Visez au minimum la 3FN pour éviter les anomalies d'insertion et de mise à jour.

---

## 🆘 Problèmes fréquents

| Problème | Solution |
|---|---|
| *"Le MLD est vide"* | Vérifier que le MCD contient au moins une entité avec un identifiant |
| *"Erreur de génération SQL"* | S'assurer que toutes les associations ont des cardinalités des deux côtés |
| *"L'attribut n'apparaît pas dans le dictionnaire"* | Rafraîchir la vue (changer de vue et revenir) |
| *"Le lien ne se crée pas"* | Vérifier que l'Outil Lien est actif (surligné) avant de cliquer sur les deux éléments |
| *"Identifiant manquant"* | Chaque entité doit avoir exactement un attribut identifiant défini dans le panneau de propriétés |

---

[⬅️ Retour : Algorithmes](./algo.md) | [Suivant : Graphes ➡️](./graphe.md)
