fonction TrouverPosition(T: tab, n: entier, nouvelle: reel) : entier
Variables
  i: entier
Début
  i <- 1
  tantque (i <= n) et (T[i].puis < nouvelle) faire
    i <- i + 1
  fintantque
  // À la fin de la boucle, 'i' est l'indice précis où insérer !
  TrouverPosition <- i
finfonction

// n est le nombre actuel d'éléments remplis dans le tableau (n < taille maximale)
Procedure Inserer( T: Tableau, n: Entier, elem: Entier)
Variables
  j,k : Entier
Début
   //appel de la fonction trouvepostion
   k <- TrouverPosition(T,n,elem)
  // Décalage vers la droite
  pour j de n-1 a k  faire
    T[j+1] <- T[j]
  finPour
  T[k] <- elem
  n <- n + 1
finprocedure
