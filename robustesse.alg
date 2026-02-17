Algorithme RobustesseTotale

// 1. Déclaration des constantes
const VERSION <- 1.1, AUTEUR = "Antigravity", MAX_ENTREES = 5

// 2. Définition des types et structures
type Point = structure
    x, y : reel
finstructure

type Coordonnees = Point

// 3. Déclaration des variables globales (principales)
variables
    p1, p2 : Point
    points : tableau [1..MAX_ENTREES] de Point
    grille : tableau [1..3, 1..3] d'entier
    compteur, i, j : entier
    choix : entier
    continuer : booleen

// 4. Définition des sous-programmes
fonction calculerDistance(a : Point, b : Point) : reel
variables
    dx, dy : reel
début
    dx <- b.x - a.x
    dy <- b.y - a.y
    calculerDistance <- racine_carree(dx * dx + dy * dy)
finfonction

procedure afficherEntete()
début
    effacer("")
    afficher("========================================")
    afficher("   TEST ROBUSTESSE PSEUDO-CODE V", VERSION)
    afficher("   Auteur: ", AUTEUR)
    afficher("========================================")
finprocedure

procedure initialiserPoints(tab : tableau [1..5] de Point)
début
    pour i de 1 à 5 faire
        tab[i].x <- i * 1.5
        tab[i].y <- i * 2.5
    finpour
finprocedure

procedure initialiserGrille()
début
    pour i de 1 à 3 faire
        pour j de 1 à 3 faire
            grille[i, j] <- i * j
        finpour
    finpour
finprocedure

// 5. Corps principal de l'algorithme
Début
    afficherEntete()
    
    compteur <- 0
    continuer <- Vrai
    
    initialiserPoints(points)
    initialiserGrille()
    
    repeter
        afficher("")
        afficher("1. Afficher un point")
        afficher("2. Calculer distance entre deux points")
        afficher("3. Test boucles et conditions")
        afficher("4. Afficher la grille 2D (Test Tableau 2D)")
        afficher("0. Quitter")
        ecrire("Votre choix : ")
        lire(choix)
        
        selon choix faire
            cas 1:
                ecrire("Index du point (1-5) : ")
                lire(i)
                si i >= 1 et i <= 5 alors
                    afficher("Point ", i, " : (", points[i].x, ", ", points[i].y, ")")
                sinon
                    afficher("Index invalide !")
                finsi
            
            cas 2:
                p1.x <- 0
                p1.y <- 0
                ecrire("Entrez X du point 2 : ")
                lire(p2.x)
                ecrire("Entrez Y du point 2 : ")
                lire(p2.y)
                afficher("Distance de l'origine : ", calculerDistance(p1, p2))
            
            cas 3:
                afficher("Décompte :")
                pour i de 5 à 1 pas -1 faire
                    ecrire(i, "... ")
                finpour
                afficher("Partez !")
                
                i <- 3
                tantque i > 0 faire
                    afficher("Tantque : ", i)
                    i <- i - 1
                fintantque
                
            cas 4:
                afficher("Contenu de la grille 3x3 :")
                pour i de 1 à 3 faire
                    pour j de 1 à 3 faire
                        ecrire(grille[i, j], "  ")
                    finpour
                    afficher("")
                finpour

            cas 0:
                continuer <- Faux
                afficher("Au revoir !")
            
            sinon:
                afficher("Option inconnue.")
        finselon
   
    jusqua continuer = Faux ou choix = 0
Fin
