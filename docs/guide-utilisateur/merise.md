# 🗂️ Merise - Guide utilisateur

## Introduction à la méthode Merise

La méthode **Merise** est une méthode d'analyse et de conception des systèmes d'information. Elle permet de modéliser les données et les traitements d'une organisation.

![Exemple MCD](../images/screenshots/merise-example.png)

## 🎯 Créer un diagramme Merise

### Ouvrir l'éditeur Merise

1. Ouvrez la palette de commandes (`Ctrl+Shift+P`)
2. Tapez `Pseudo Code: Nouveau diagramme Merise`
3. Choisissez le type de modèle :
   - **MCD** (Modèle Conceptuel de Données)
   - **MLD** (Modèle Logique de Données)
   - **MPD** (Modèle Physique de Données)

![Nouveau MCD](../images/screenshots/new-mcd.png)

## 📐 Modèle Conceptuel de Données (MCD)

### Créer une entité

> [!TIP]
> Une entité représente un objet du monde réel (Client, Produit, Commande, etc.)

1. Cliquez sur l'outil **Entité** dans la barre d'outils
2. Cliquez sur le canvas pour placer l'entité
3. Nommez l'entité
4. Ajoutez des attributs

![Création d'entité](../images/screenshots/create-entity.png)

**Exemple :**
```
┌─────────────────┐
│    CLIENT       │
├─────────────────┤
│ #numeroClient   │
│  nom            │
│  prenom         │
│  email          │
│  telephone      │
└─────────────────┘
```

### Créer une association

Les associations relient les entités entre elles.

1. Cliquez sur l'outil **Association**
2. Cliquez sur la première entité
3. Cliquez sur la deuxième entité
4. Définissez les cardinalités (0,1 - 1,1 - 0,N - 1,N)

![Création d'association](../images/screenshots/create-association.png)

**Cardinalités :**
- **0,1** : Zéro ou une fois
- **1,1** : Exactement une fois
- **0,N** : Zéro ou plusieurs fois
- **1,N** : Au moins une fois

### Exemple complet de MCD

```
        1,N                    0,N
CLIENT ──────── PASSER ──────── COMMANDE
                   │
                   │ dateCommande
                   
         1,1                    1,N
COMMANDE ──────── CONTENIR ──────── PRODUIT
                      │
                      │ quantite
                      │ prixUnitaire
```

![MCD complet](../images/screenshots/mcd-complete.png)

## 🔄 Modèle Logique de Données (MLD)

### Transformation MCD → MLD

> [!IMPORTANT]
> Le MLD est généré automatiquement à partir du MCD.

1. Créez votre MCD complet
2. Cliquez sur **Générer MLD**
3. L'extension transforme automatiquement votre MCD

![Transformation MLD](../images/screenshots/mcd-to-mld.png)

**Règles de transformation :**
- Chaque entité devient une table
- Les associations 1,N deviennent des clés étrangères
- Les associations N,N deviennent des tables intermédiaires

**Exemple de MLD :**
```
CLIENT (#numeroClient, nom, prenom, email, telephone)
COMMANDE (#numeroCommande, dateCommande, #numeroClient)
PRODUIT (#numeroProduit, libelle, prix)
CONTENIR (#numeroCommande, #numeroProduit, quantite, prixUnitaire)
```

## 💾 Modèle Physique de Données (MPD)

### Génération du MPD

Le MPD définit la structure physique de la base de données.

1. À partir du MLD, cliquez sur **Générer MPD**
2. Choisissez le SGBD cible :
   - MySQL
   - PostgreSQL
   - SQLite
   - Oracle
   - SQL Server

![Génération MPD](../images/screenshots/generate-mpd.png)

### Script SQL généré

```sql
CREATE TABLE CLIENT (
    numeroClient INT PRIMARY KEY AUTO_INCREMENT,
    nom VARCHAR(50) NOT NULL,
    prenom VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    telephone VARCHAR(20)
);

CREATE TABLE COMMANDE (
    numeroCommande INT PRIMARY KEY AUTO_INCREMENT,
    dateCommande DATE NOT NULL,
    numeroClient INT NOT NULL,
    FOREIGN KEY (numeroClient) REFERENCES CLIENT(numeroClient)
);

CREATE TABLE PRODUIT (
    numeroProduit INT PRIMARY KEY AUTO_INCREMENT,
    libelle VARCHAR(100) NOT NULL,
    prix DECIMAL(10, 2) NOT NULL
);

CREATE TABLE CONTENIR (
    numeroCommande INT,
    numeroProduit INT,
    quantite INT NOT NULL,
    prixUnitaire DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (numeroCommande, numeroProduit),
    FOREIGN KEY (numeroCommande) REFERENCES COMMANDE(numeroCommande),
    FOREIGN KEY (numeroProduit) REFERENCES PRODUIT(numeroProduit)
);
```

## 🎨 Fonctionnalités avancées

### Validation du modèle

> [!NOTE]
> L'extension vérifie automatiquement la cohérence de votre modèle.

Erreurs détectées :
- ✅ Entités sans identifiant
- ✅ Associations sans cardinalités
- ✅ Cardinalités incorrectes
- ✅ Noms d'attributs en double

![Validation](../images/screenshots/validation.png)

### Export du diagramme

Exportez votre MCD/MLD/MPD en :
- **PNG** : Image haute résolution
- **SVG** : Format vectoriel
- **PDF** : Document imprimable
- **SQL** : Script de création de base de données

### Thèmes visuels

Personnalisez l'apparence de vos diagrammes :

![Thèmes](../images/screenshots/merise-themes.png)

### Mode collaboratif

> [!TIP]
> Partagez vos diagrammes en temps réel avec Live Share.

## 🎥 Tutoriel vidéo

![Tutoriel Merise](../videos/tutorials/merise-tutorial.mp4)
*Durée : 8 minutes - Créer un MCD complet et générer le SQL*

## 💡 Exemples fournis

L'extension inclut des exemples complets :

- 📚 **Bibliothèque** : Gestion de livres et emprunts
- 🏪 **E-commerce** : Boutique en ligne avec panier
- 🏥 **Hôpital** : Gestion des patients et rendez-vous
- 🎓 **École** : Étudiants, cours et inscriptions

## 🆘 Problèmes courants

### Le diagramme ne s'affiche pas

Rechargez la fenêtre : `Ctrl+Shift+P` → `Reload Window`

### Impossible de créer une association

> [!WARNING]
> Vérifiez que les deux entités existent et ont des identifiants.

---

[⬅️ Retour : Algorithmes](./algo.md) | [Suivant : Graphes ➡️](./graphe.md)
