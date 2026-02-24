fonction EstPalindrome(mot: chaine) : booleen
variables
  i, taille : entier
  palindrome : booleen
Début
  taille <- Longueur(mot)
  palindrome <- vrai
  i <- 1
  
  tantque i <= (taille div 2) et palindrome = vrai faire
    si mot[i] <> mot[taille - i + 1] alors
      palindrome <- faux
    finSi
    i <- i + 1
  finTantque
  
  EstPalindrome <- palindrome
finfonction
