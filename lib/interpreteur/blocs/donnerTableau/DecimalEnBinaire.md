fonction DecimalEnBinaire(n: entier) : chaine
variables
  binaire : chaine
  reste : entier
Début
  binaire <- ""
  si n = 0 alors
    DecimalEnBinaire <- "0"
  sinon
    tantque n > 0 faire
      reste <- n mod 2
      // On concatène le reste au DEBUT de la chaine
      binaire <- reste + binaire
      n <- n div 2
    finTantque
    DecimalEnBinaire <- binaire
  finSi
finfonction
