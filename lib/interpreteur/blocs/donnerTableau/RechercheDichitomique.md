fonction RechercheDichotomique(T: tableau, n: entier, val: entier) : entier
variables
  inf, fin, milieu : entier
  trouve : booleen
Début
  inf <- 1
  fin <- n
  trouve <- faux
  
  tantque inf <= fin et trouve = faux faire
    milieu <- (inf + fin) div 2
    
    si T[milieu] = val alors
      trouve <- vrai
    sinon si T[milieu] < val alors
      inf <- milieu + 1
    sinon
      fin <- milieu - 1
    finSi
  finTantque
  
  si trouve = vrai alors
     RechercheDichotomique <- milieu
  sinon
    RechercheDichotomique <- 0;
  finSi
finfonction
