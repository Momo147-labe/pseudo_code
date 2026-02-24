// On suppose M1 de dimension (L1, C1) et M2 de dimension (L2, C2)
// avec obligatoirement C1 = L2. M_Resultat sera de dimension (L1, C2)
procedure ProduitMatrices(M1: tableau, M2: tableau, M_Result: tableau, L1: entier, C1: entier, C2: entier)
variables
  i, j, k : entier
  somme : reel
Début
  pour i de 1 a L1 faire
    pour j de 1 a C2 faire
      somme <- 0
      // La ligne i de M1 * La colonne j de M2
      pour k de 1 a C1 faire
        somme <- somme + (M1[i, k] * M2[k, j])
      finPour
      M_Result[i, j] <- somme
    finPour
  finPour
finprocedure
