fonction CompterVoyelles(mot: chaine) : entier
variables
  i, compteur, taille : entier
  lettre : chaine
Début
  taille <- Longueur(mot)
  compteur <- 0
  
  pour i de 1 a taille faire
    lettre <- maj(car(mot,i)) // Hypothèse d'une fonction Majuscule existante
    si lettre = "A" ou lettre = "E" ou lettre = "I" ou lettre = "O" ou lettre = "U" ou lettre = "Y" alors
      compteur <- compteur + 1
    finSi
  finPour
  
  CompterVoyelles <- compteur
finfonction
