procedure EliminerDoublonsTries(T: tableau, n: entier)
variables
  i, j : entier
Début
  si n > 1 alors
    j <- 1 // Index du dernier élément unique validé
    pour i de 2 a n faire
      si T[i] <> T[j] alors
        j <- j + 1
        T[j] <- T[i]
      finSi
    finPour
    n <- j // La nouvelle taille du tableau sans doublons
  finSi
finprocedure
