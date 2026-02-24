procedure Supprimer(T: Tableau, n: entier, k: entier)
//k est la position de l'element a supprimer
//n est la taille du tableau
Variables
  j : entier
Début
  // Décalage vers la gauche
  pour j de k a n-1 faire
    T[j] <- T[j+1]
  finPour
  n <- n - 1
finprocedure
