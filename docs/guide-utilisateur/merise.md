# 🗂️ Merise - Guide Complet de Modélisation

La méthode **Merise** est l'approche de référence pour la conception de bases de données relationnelles. L'application **Pseudo Code** vous permet de modéliser visuellement vos données et de générer automatiquement le code SQL nécessaire.

---

## 🎯 Modèle Conceptuel de Données (MCD)

Le MCD est la première étape du design. Il représente les objets du monde réel (Entités) et les liens qui les unissent (Associations).

### 1. Les Entités
Une entité regroupe des informations sur un sujet précis (ex: Client, Commande).
- **Identifiant** : Chaque entité doit avoir un attribut unique (souligné) qui permet de distinguer chaque occurrence (ex: `id_client`).
- **Attributs** : Les propriétés de l'entité (nom, date, prix).

### 2. Les Associations
Elles expriment une action ou un lien entre des entités (ex: "Passer", "Contenir").
- **Cardinalités** : Elles définissent combien de fois une entité peut participer à une association.
    - `0,1` : Au plus une fois.
    - `1,1` : Exactement une fois.
    - `0,N` : Zéro ou plusieurs fois.
    - `1,N` : Au moins une fois.

> [!TIP]
> **Bonne pratique** : Évitez les redondances ! Si une information peut être calculée, ne l'ajoutez pas comme attribut.

---

## 🔄 Transformation MCD → MLD

Le **Modèle Logique de Données (MLD)** est une représentation tabulaire prête pour le stockage. L'application automatise cette étape complexe selon ces règles :

1. **Entité simple** : Devient une table. L'identifiant devient la **Clé Primaire**.
2. **Association 1,N (Père-Fils)** : La clé primaire du côté "1" est ajoutée comme **Clé Étrangère** dans la table du côté "N".
3. **Association N,N** : L'association devient une **Table Intermédiaire** dont la clé primaire est composée des clés primaires des deux entités liées.
4. **Attributs d'association** : Sont ajoutés à la table de l'association (pour le N,N) ou à la table recevant la clé étrangère (pour le 1,N).

---

## 💾 Passage au Physique (MPD & SQL)

Une fois le MLD validé, l'application génère le **MPD** (Modèle Physique) spécifique à votre base de données.

### SGBD Supportés
L'application génère du SQL optimisé pour :
- **MySQL / MariaDB**
- **PostgreSQL**
- **SQLite**
- **SQL Server**

> [!IMPORTANT]
> L'export SQL inclut les contraintes d'intégrité (`PRIMARY KEY`, `FOREIGN KEY`) et les types de données correspondants (VARCHAR, INT, DATE, etc.).

---

## 🏆 Conseils de Modélisation (Normalisation)

Pour un schéma performant, suivez ces principes :
- **1ère Forme Normale** : Tous les attributs sont atomiques (pas de liste dans une case).
- **2ème Forme Normale** : Tout attribut dépend de la clé primaire entière.
- **3ème Forme Normale** : Pas de dépendance transitive entre attributs non-clés.

---

## 🆘 Troubleshooting Merise

- **Le texte de l'association est coupé** : Vous pouvez cliquer sur le nom de l'association pour le déplacer ou le renommer.
- **Erreur de génération MLD** : Vérifiez que toutes vos associations ont des cardinalités des deux côtés.
- **Identifiant manquant** : Une entité sans identifiant (clé primaire) ne peut pas être transformée en table.

---

[⬅️ Retour : Algorithmes](./algo.md) | [Suivant : Graphes ➡️](./graphe.md)
