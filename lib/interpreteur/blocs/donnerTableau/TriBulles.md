*/
 si c'est un tableau de structure
  le type de la variable temp est doit etre le type de structure
  ex: type info = struture
        puis : entier
        nom : chaine
      finstruture
/*

procedure Tribulles_par_puis(v: tab, n: entier)
Variables
  i, j : entier
  temp : info   
Début
  pour i de 1 a n-1 faire
    pour j de 1 a n-i faire
      
      // On compare sur la puissance (ordre décroissant)
      // v[j].puis remplacer le puis par element sur lequel vous souhaitez trier le tableau
      si v[j].puis < v[j+1].puis alors
        
        // On échange toujours la structure entière
        temp <- v[j]
        v[j] <- v[j+1]
        v[j+1] <- temp
        
      finsi
      
    finpour
  finpour
finprocedure
