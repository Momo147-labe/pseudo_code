Algorithme Combinaisons_Nombres

// Cet algorithme trouve toutes les combinaisons de K nombres
// extraits de l'ensemble {1, 2, 3, ..., 99}.

Variables
    k : entier
    nbComb : entier
    selection : Tableau[1..100] d'Entier

// Procédure récursive pour générer les combinaisons
// index : position actuelle dans le tableau 'selection'
// debut : nombre à partir duquel on commence à chercher
// restant : nombre d'éléments encore à choisir
Procedure GenererCombinaisons(index : entier, debut : entier, restant : entier)
Variables
    i : entier
Début
    // Si nous avons choisi tous les nombres nécessaires
    Si restant = 0 Alors
        nbComb <- nbComb + 1
        Afficher("Combinaison ", nbComb, " : ")
        
        Pour i <- 1 A index - 1 FAIRE
            Afficher(selection[i], " ")
        FinPour
        
        AfficherLigne("")
    Sinon
        // On parcourt les nombres de 'debut' à 99
        Pour i <- debut A 99 FAIRE
            selection[index] <- i
            // Appel récursif pour le nombre suivant
            GenererCombinaisons(index + 1, i + 1, restant - 1)
        FinPour
    FinSi
FinProcedure

Début
    AfficherLigne("--- Générateur de Combinaisons (1 à 99) ---")
    Afficher("Combien de nombres voulez-vous combiner ? ")
    Lire(k)

    // Vérification de la validité de K
    Si k < 0 OU k > 99 Alors
        AfficherLigne("Erreur : K doit être compris entre 0 et 99.")
    Sinon
        nbComb <- 0
        AfficherLigne("Génération des combinaisons de ", k, " nombres...")
        AfficherLigne("------------------------------------------")
        
        // Note: Pour de grandes valeurs de k, le nombre de combinaisons
        // peut être extrêmement élevé et l'exécution longue.
        
        GenererCombinaisons(1, 1, k)
        
        AfficherLigne("------------------------------------------")
        AfficherLigne("Nombre total de combinaisons trouvées : ", nbComb)
    FinSi
Fin
