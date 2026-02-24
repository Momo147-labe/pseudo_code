procedure TransposerMatrice(M: tableau, M_Transp: tableau, n_lignes: entier, n_colonnes: entier)
variables
  i, j : entier
Début
  // M est de dimension (n_lignes, n_colonnes)
  // M_Transp sera de dimension (n_colonnes, n_lignes)
  pour i de 1 a n_lignes faire
    pour j de 1 a n_colonnes faire
      M_Transp[j, i] <- M[i, j]
    finPour
  finPour
finprocedure
