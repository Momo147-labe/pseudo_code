# ❓ FAQ - Questions fréquentes

## Installation et configuration

### Q: Comment installer l'extension ?

Ouvrez VSCode, allez dans Extensions (`Ctrl+Shift+X`), recherchez "Pseudo Code" et cliquez sur Install. [Guide complet](./installation.md)

### Q: L'extension est-elle gratuite ?

Oui, l'extension est complètement gratuite et open-source sous licence MIT.

### Q: Quelles sont les versions de VSCode compatibles ?

L'extension fonctionne avec VSCode version 1.60 ou supérieure.

## Algorithmes

### Q: Comment exécuter mon algorithme ?

Cliquez sur l'icône **▶️ Exécuter** en haut à droite ou appuyez sur `F5`.

### Q: Puis-je importer du code Python/Java/C++ ?

Pas directement, mais vous pouvez convertir manuellement en pseudo-code. Une fonctionnalité d'import est prévue dans une future version.

### Q: Comment afficher la complexité de mon algorithme ?

Après l'exécution, cliquez sur **Analyser la complexité** dans le panneau de résultats.

## Merise

### Q: Comment générer le SQL depuis mon MCD ?

Créez votre MCD, puis : **Générer MLD** → **Générer MPD** → Sélectionnez votre SGBD → Le script SQL est généré automatiquement.

### Q: Puis-je importer une base de données existante ?

Oui ! Utilisez **Fichier** → **Importer depuis SQL** et sélectionnez votre fichier .sql

### Q: Les cardinalités sont-elles validées ?

Oui, l'extension vérifie automatiquement la cohérence des cardinalités et affiche des avertissements si nécessaire.

## Graphes

### Q: Quelle est la différence entre DFS et BFS ?

- **DFS** (Depth-First Search) : explore en profondeur d'abord
- **BFS** (Breadth-First Search) : explore niveau par niveau

[En savoir plus](./guide-utilisateur/graphe.md#algorithmes-sur-les-graphes)

### Q: Comment créer un graphe pondéré ?

Lors de la création, sélectionnez **Type** → **Pondéré**, puis entrez les poids pour chaque arête.

### Q: Puis-je exporter mon graphe en image ?

Oui ! Clic droit sur le graphe → **Exporter** → Choisissez PNG, SVG ou PDF.

## Défis et progression

### Q: Comment débloquer de nouveaux défis ?

Complétez les défis précédents dans chaque catégorie pour débloquer les suivants.

### Q: Mes points sont-ils sauvegardés ?

Oui, votre progression est automatiquement sauvegardée localement et synchronisée si vous êtes connecté.

### Q: Puis-je créer mes propres défis ?

Oui ! Allez dans **Défis** → **Créer un défi personnalisé**.

## Support technique

### Q: L'extension ne démarre pas

1. Vérifiez que VSCode est à jour
2. Désactivez temporairement les autres extensions
3. Rechargez la fenêtre : `Ctrl+Shift+P` → `Reload Window`

### Q: Mon code ne s'exécute pas

Vérifiez :
- ✅ Syntaxe correcte (tous les DEBUT ont un FIN)
- ✅ Variables déclarées
- ✅ Pas d'erreurs affichées dans le panneau Problèmes

### Q: Comment signaler un bug ?

Ouvrez une issue sur [GitHub](https://github.com/pseudocode/issues) avec :
- Description du problème
- Étapes pour reproduire
- Captures d'écran si possible

---

[⬅️ Retour à l'accueil](./README.md)
