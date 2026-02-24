Algorithme LaboratoireDesNatives
Variables
    texte : chaine
    nombre : reel
    saisie : chaine
    alea : entier
Début
    Afficher "--- TEST DES CHAINES ---"
    texte <- "Pseudo-Code est Cool"
    Afficher "Texte original : ", texte
    Afficher "Longueur : ", long(texte)
    Afficher "En MAJUSCULES : ", maj(texte)
    Afficher "en minuscules : ", minus(texte)
    Afficher ""

    Afficher "--- TEST DES MATHS ---"
    nombre <- -16.64
    Afficher "Nombre original : ", nombre
    Afficher "Valeur Absolue : ", abs(nombre)
    Afficher "Racine de 25 : ", racine(25)
    Afficher "Arrondi de ", nombre, " : ", arrondi(nombre)
    Afficher "Tronqué : ", tronque(nombre)
    
    alea <- hasard(1, 100)
    Afficher "Nombre au hasard entre 1 et 100 : ", alea
    Afficher ""

    Afficher "--- TEST DES CONVERSIONS ---"
    saisie <- "42"
    Afficher "Saisie (chaine) : ", saisie
    Afficher "Est numérique ? ", est_numerique(saisie)
    Afficher "En entier : ", en_entier(saisie) + 8 // Doit afficher 50
    
    saisie <- "3.14"
    Afficher "En réel : ", en_reel(saisie)
    Afficher "42 en chaine : ", en_chaine(42)
    Afficher ""

    Afficher "--- TEST DES TYPES ---"
    Afficher "Type de 'Bonjour' : ", typeVar("Bonjour")
    Afficher "Type de 100 : ", typeVar(100)
    Afficher "Type de vrai : ", typeVar(vrai)
    Afficher "Type de 4.5 : ", typeVar(4.5)
Fin
