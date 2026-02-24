procedure TriInsertion(T: tableau, n: entier)
variables
  i, j, cle : entier
Début
  pour i de 2 a n faire
    cle <- T[i]
    j <- i - 1
    // On décale les éléments plus grands que la clé vers la droite
    tantque j >= 1 et T[j] > cle faire
      T[j+1] <- T[j]
      j <- j - 1
    finTantque
    T[j+1] <- cle
  finPour
finprocedure
