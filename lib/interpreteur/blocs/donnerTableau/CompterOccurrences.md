fonction CompterOccurrences(T: tableau, n: entier, val_recherchee: entier) : entier
variables
  i, compteur : entier
Début
  compteur <- 0
  pour i de 1 a n faire
    si T[i] = val_recherchee alors
      compteur <- compteur + 1
    finSi
  finPour
  CompterOccurrences <- compteur
finfonction
