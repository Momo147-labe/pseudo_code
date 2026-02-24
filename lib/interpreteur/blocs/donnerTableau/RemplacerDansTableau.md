procedure RemplacerDansTableau(T: tableau, n: entier, ancien_val: entier, nouveau_val: entier)
variables
  i : entier
Début
  pour i de 1 a n faire
    si T[i] = ancien_val alors
      T[i] <- nouveau_val
    finSi
  finPour
finprocedure
