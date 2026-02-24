procedure InverserTableau(T: tableau, n: entier)
// n est la taille du tableau
variables
  i, temp : entier
Début
  pour i de 1 a (n div 2) faire
    temp <- T[i]
    T[i] <- T[n - i + 1]
    T[n - i + 1] <- temp
  finPour
finprocedure
