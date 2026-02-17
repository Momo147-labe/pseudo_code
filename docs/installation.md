# 📥 Installation

## Prérequis

> [!IMPORTANT]
> Assurez-vous d'avoir les éléments suivants installés sur votre système :

- **Visual Studio Code** (version 1.60 ou supérieure)
- **Connexion Internet** (pour l'installation initiale)

## Installation depuis VSCode Marketplace

### Méthode 1 : Depuis l'interface VSCode

1. Ouvrez **Visual Studio Code**
2. Cliquez sur l'icône **Extensions** dans la barre latérale (ou `Ctrl+Shift+X`)

   ![Extensions Icon](./images/screenshots/extensions-icon.png)

3. Recherchez "**Pseudo Code**" dans la barre de recherche
4. Cliquez sur le bouton **Install**

   ![Installation](./images/screenshots/install-button.png)

5. Attendez la fin de l'installation
6. Rechargez VSCode si nécessaire

### Méthode 2 : Ligne de commande

```bash
code --install-extension pseudo-code
```

## Vérification de l'installation

> [!TIP]
> Pour vérifier que l'extension est bien installée :

1. Ouvrez la palette de commandes (`Ctrl+Shift+P`)
2. Tapez "Pseudo Code"
3. Vous devriez voir les commandes de l'extension apparaître

![Commandes disponibles](./images/screenshots/commands.png)

## Configuration initiale

Après l'installation, quelques paramètres sont à configurer :

### Thème de l'éditeur (optionnel)

```json
{
  "pseudoCode.theme": "dark",
  "pseudoCode.fontSize": 14
}
```

### Langue de l'interface

```json
{
  "pseudoCode.language": "fr"
}
```

## Mise à jour

L'extension se met à jour automatiquement. Pour forcer une mise à jour :

1. Allez dans **Extensions**
2. Trouvez **Pseudo Code**
3. Cliquez sur l'icône **⚙️**
4. Sélectionnez **Update**

## Désinstallation

Si vous souhaitez désinstaller l'extension :

1. Allez dans **Extensions**
2. Trouvez **Pseudo Code**
3. Cliquez sur **Uninstall**

---

[⬅️ Retour à l'accueil](./README.md) | [Suivant : Guide général ➡️](./guide-utilisateur/general.md)
