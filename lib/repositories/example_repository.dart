import 'dart:convert';
import 'package:flutter/services.dart';

class ExampleRepository {
  Future<List<dynamic>> loadExercices() async {
    int attempts = 0;
    while (attempts < 5) {
      try {
        attempts++;
        final String response = await rootBundle.loadString(
          'assets/exercices.json',
        );
        return json.decode(response);
      } catch (e) {
        if (attempts < 5) {
          await Future.delayed(Duration(milliseconds: 1000 * attempts));
        }
      }
    }
    return [];
  }

  final List<Map<String, String>> builtInExamples = [
    {
      "title": "Calcul Moyenne",
      "code": """Algorithme Moyenne
Variables
  note1, note2, moy : reel
Debut
  Afficher("Entrez note 1 :" )
  Lire(note1)
  Afficher("Entrez note 2 :" )
  Lire(note2)
  moy <- (note1 + note2) / 2
  Afficher("Moyenne : " , moy)
Fin""",
    },
    {
      "title": "Table de Multiplication",
      "code": """Algorithme TableMultiplication
Variables
  N, i : entier
Debut
  Afficher("Quelle table ?")
  Lire(N)
  Pour i de 1 à 10 Faire
    Afficher(N , " x " , i , " = " , N*i)
  FinPour
Fin""",
    },
    {
      "title": "Somme Tableau (1D)",
      "code": """Algorithme SommeTab
Variables
  T : Tableau[1..5] de entier
  i, s : entier
Debut
  s <- 0
  Pour i de 1 à 5 Faire
    T[i] <- i * 10
    Afficher("Case " , i , " = " , T[i])
    s <- s + T[i]
  FinPour
  Afficher("Somme totale : " , s)
Fin""",
    },
    {
      "title": "Matrice d'Identité (2D)",
      "code": """Algorithme MatriceIdentite
Type Matrice = Tableau[1..3, 1..3] de entier
Variables
  M : Matrice
  i, j : entier
Debut
  Pour i de 1 à 3 Faire
    Pour j de 1 à 3 Faire
      Si i = j Alors
        M[i, j] <- 1
      Sinon
        M[i, j] <- 0
      FinSi
    FinPour
  FinPour
  Afficher("Matrice 3x3 générée")
Fin""",
    },
    {
      "title": "PGCD (Récursif)",
      "code": """Algorithme PgcdRecursif
Fonction calculerPGCD(a, b : entier) : entier
Debut
  Si b = 0 Alors
    Retourner a
  Sinon
    Retourner calculerPGCD(b, a Mod b)
  FinSi
FinFonction

Variables
  x, y : entier
Debut
  Afficher("Entrez x et y :")
  Lire(x, y)
  Afficher("Le PGCD est : ", calculerPGCD(x, y))
Fin""",
    },
    {
      "title": "Structure Étudiant",
      "code": """Algorithme GestionEtudiant
Type Etudiant = Structure
  nom : chaine
  age : entier
FinStructure

Variables
  e : Etudiant
Debut
  e.nom <- "Momo"
  e.age <- 20
  Afficher("Nom: ", e.nom, ", Age: ", e.age)
Fin""",
    },
  ];
}
