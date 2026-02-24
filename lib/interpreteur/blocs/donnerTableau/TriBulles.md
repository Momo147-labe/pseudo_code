procedure Tribulles(T: tableau, n: entier)
   variables
  i, j, temp : entier
DéBut
  pour i de 1 a n-1 faire
    pour j de 1 a n-i faire
      si T[j] > T[j+1] alors
        // Swap (Échange)
        temp <- T[j]
        T[j] <- T[j+1]
        T[j+1] <- temp
      finSi
    finPour
  finPour
finprocedure
