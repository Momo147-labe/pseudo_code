fonction Factorielle(n: entier) : entier
variables
  i, resultat : entier
Début
  resultat <- 1
  pour i de 1 a n faire
    resultat <- resultat * i
  finPour
  Factorielle <- resultat
finfonction
