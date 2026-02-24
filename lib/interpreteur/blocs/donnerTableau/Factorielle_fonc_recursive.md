// Définition de la fonction récursive
Fonction Factorielle(n : entier) : entier
Début
    Si n <= 1 Alors
        Retourner 1
    Sinon
        // Appel récursif : n * (n-1)!
        Retourner n * Factorielle(n - 1)
    FinSi
finfonction