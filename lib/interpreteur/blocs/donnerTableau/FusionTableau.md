procedure FusionnerTableaux(T1: tableau, n1: entier, T2: tableau, n2: entier, T_Fusion: tableau, n_total: entier)
variables
  i : entier
Début
  n_total <- n1 + n2
  
  pour i de 1 a n1 faire
    T_Fusion[i] <- T1[i]
  finPour
  
  pour i de 1 a n2 faire
    T_Fusion[n1 + i] <- T2[i]
  finPour
finprocedure
