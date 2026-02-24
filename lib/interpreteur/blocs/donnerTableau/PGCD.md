fonction PGCD(a: entier, b: entier) : entier
variables
  reste : entier
Début
  tantque b <> 0 faire
    reste <- a mod b
    a <- b
    b <- reste
  finTantque
  PGCD <- a
finfonction
