// n est le nombre actuel d'éléments remplis dans le tableau (n < taille maximale)
Procedure Inserer(Var T: Tableau, Var n: Entier, elem: Entier, k: Entier)
//k est la position d'insertion
//n est la taille du tableau
//elem est element a inserer
Variables
  j : Entier
Début
  // Décalage vers la droite
  pour j de n-1 a k  faire
    T[j+1] <- T[j]
  finPour
  T[k] <- elem
  n <- n + 1
finprocedure
