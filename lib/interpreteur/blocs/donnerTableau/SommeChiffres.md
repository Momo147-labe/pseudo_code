fonction SommeChiffres(n: entier) : entier
variables
  somme, reste : entier
Début
  somme <- 0
  tantque n > 0 faire
    reste <- n mod 10
    somme <- somme + reste
    n <- n div 10
  finTantque
  SommeChiffres <- somme
finfonction
