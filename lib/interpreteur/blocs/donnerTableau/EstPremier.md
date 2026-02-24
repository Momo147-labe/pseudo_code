fonction EstPremier(n: entier) : booleen
variables
  i : entier
  premier : booleen
Début
  si n <= 1 alors
    premier <- faux
  sinon
    premier <- vrai
    i <- 2
    tantque i <= (n div 2) et premier = vrai faire
      si n mod i = 0 alors
        premier <- faux
      finSi
      i <- i + 1
    finTantque
  finSi
  EstPremier <- premier
finfonction
