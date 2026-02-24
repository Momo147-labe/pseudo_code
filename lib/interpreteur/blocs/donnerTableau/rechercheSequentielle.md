fonction RechercheSequentielle(T: tableau, n: entier, val_recherchee: entier) : entier
variables
  i : entier
Début
  pour i de 1 a n faire
    si T[i] = val_recherchee alors
      RechercheSequentielle <- i
    finSi
  finPour
  RechercheSequentielle <- 0 
finfonction
