# Configuration Build Windows - Gestion Moderne de Magasin

# Variables d'environnement pour le build
$env:FLUTTER_BUILD_MODE = "release"
$env:FLUTTER_TARGET_PLATFORM = "windows-x64"

# Configuration spécifique Windows
Write-Host "Configuration du build Windows..." -ForegroundColor Green

# Vérifier Flutter
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Error "Flutter n'est pas installé ou pas dans le PATH"
    exit 1
}

# Vérifier Visual Studio Build Tools
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsWhere) {
    $vsPath = & $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($vsPath) {
        Write-Host "Visual Studio Build Tools trouvés: $vsPath" -ForegroundColor Green
    } else {
        Write-Warning "Visual Studio Build Tools non trouvés. Installation recommandée."
    }
}

# Configuration Flutter pour Windows
Write-Host "Configuration Flutter Windows..." -ForegroundColor Blue
flutter config --enable-windows-desktop

# Nettoyage
Write-Host "Nettoyage des builds précédents..." -ForegroundColor Yellow
flutter clean

# Récupération des dépendances
Write-Host "Installation des dépendances..." -ForegroundColor Blue
flutter pub get

Write-Host "Configuration terminée! Exécutez build_windows.bat pour builder." -ForegroundColor Green