@echo off
echo ========================================
echo    BUILD WINDOWS - ALGORITHME UNIV LABE
echo ========================================

REM Nettoyage
echo [1/6] Nettoyage des builds precedents...
if exist "build\windows" rmdir /s /q "build\windows"
if exist "Output" rmdir /s /q "Output"

REM Dependencies
echo [2/6] Installation des dependances...
call flutter pub get

REM Build Release
echo [3/6] Build Flutter Windows Release...
call flutter build windows --release --verbose

REM Verification
echo [4/6] Verification du build...
if not exist "build\windows\x64\runner\Release\algorithme_univ_labe.exe" (
    echo ERREUR: Executable non trouve!
    pause
    exit /b 1
)

REM Copie des DLLs necessaires
echo [5/6] Copie des dependances systeme...
copy "C:\Windows\System32\vcruntime140.dll" "build\windows\x64\runner\Release\" 2>nul
copy "C:\Windows\System32\msvcp140.dll" "build\windows\x64\runner\Release\" 2>nul
copy "C:\Windows\System32\vcruntime140_1.dll" "build\windows\x64\runner\Release\" 2>nul

REM Creation installer
echo [6/6] Creation de l'installer...
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss
) else (
    echo ATTENTION: Inno Setup non trouve. Installer depuis: https://jrsoftware.org/isinfo.php
    echo Build termine. Executable disponible dans: build\windows\x64\runner\Release\
)

echo ========================================
echo           BUILD TERMINE!
echo ========================================
echo.
echo Executable: build\windows\x64\runner\Release\algorithme_univ_labe.exe
if exist "Output\Setup-Algorithme Univ Labé-1.0.0.exe" (
    echo Installer: Output\Setup-Algorithme Univ Labé-1.0.0.exe
)
echo.
pause