Algorithme Gestion_de_classe

//la declaration de la constante
const ef <- 100

//la declaration de la structure
type etudiant = structure
   matricule : chaine
    nom : chaine
    prenom : chaine
    note1, note2, note3 : reel
    moyenne : reel
    mention : chaine
finstructure
  
 //la declaration du tableau
  type tabEtudiant = tableau[1..ef] de etudiant

//la procedure de creation de eleve
procedure saisir(v:tabEtudiant,n:entier)
  Variables
   i:entier
    Début
      i <-1
       afficher("Donnez le numero matricule ",i," : ");
       lire(v[i].matricule);
        tantque v[i].matricule <> "*" faire
          afficher("Donnez le nom :");
          lire(v[i].nom)
          
          afficher("Donnez le prénom : ")
          lire(v[i].prenom);
          
          afficher("Donnez la note 1 avec coeficient 1 :");
          lire(v[i].note1);
          
          afficher("Donnez la note 2 avec coeficient 2 : ");
          lire(v[i].note2)
          
          afficher("Donnez la note 3 avec coefficient 3 : ");
          lire(v[i].note3)
          
          v[i].moyenne <- (v[i].note1*1 + v[i].note2*2 + v[i].note3*3)/6
          
            Si (v[i].moyenne >= 9) Alors 
              v[i].mention <- "Excellent"
            Sinon Si (v[i].moyenne >= 7) Alors 
              v[i].mention <- "TBien"
            Sinon Si (v[i].moyenne >= 6) Alors 
              v[i].mention <- "Bien"
            Sinon Si (v[i].moyenne >= 5) Alors 
              v[i].mention <- "Passable"
            Sinon v[i].mention <- "Redouble"
        finsi
         finsi
         finsi
         finsi  
          i <- i + 1;
          afficher("Donnez le numero matricule");
          lire(v[i].matricule);
        fintantque
       n <- i- 1;
 finprocedure
 

 
 
 Variables
  choix,n:entier
  v : tabEtudiant
  //le programme principale
  Début
    Repeter
        afficher("--- MENU GESTION DES ELEVES---");
        afficher("1. Saisir les donnees");
        afficher("2. Afficher la liste des élèves");
        afficher("0. Quitter");
        afficher("Tapez un numero :");
        lire(choix)
        selon choix faire
          cas 0:
             effacer
             afficher("Mercie beaucoup a plus");
          cas 1:
            effacer
             saisir(v,n)
          cas 2:
             effacer;
             afficherTabStructure(v)
          sinon:
            afficher("Taper un bon nombre pour continuer");      
        
          finselon
    jusqua (choix = 0)
Fin
 
 
 
 
 
  
  
  
  