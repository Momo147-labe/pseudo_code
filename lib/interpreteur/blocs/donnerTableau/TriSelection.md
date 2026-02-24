procedure TriSelection(T: Tableau, n: entier)
Variables
  i, j, min_idx, temp : entier
Début
  pour i de 1 a n-1 faire
    min_idx <- i
    pour j de i+1 a n faire
      si T[j] < T[min_idx] alors
        min_idx <- j
      finSi
    finPour
    // Swap (Permutation)
    temp <- T[i]
    T[i] <- T[min_idx]
    T[min_idx] <- temp
  finPour
finprocedure
