import 'package:pseudo_code/outils/traducteur.dart';

void main() {
  final code = """
Algorithme TestStruct
Type Etudiant = Structure
   nom : chaine
   age : entier
FinStructure

Fonction creerEtudiant(n: chaine, a: entier) : Etudiant
Variables
   e : Etudiant
Debut
   e.nom <- n
   e.age <- a
   Retourner e
FinFonction

Variables
   monEtudiant : Etudiant
Debut
   monEtudiant <- creerEtudiant("Toto", 20)
   Afficher("Nom: ", monEtudiant.nom)
Fin
""";

  print("--- C CODE ---");
  print(Traducteur.traduire(code, 'c'));
  print("\n--- JS CODE ---");
  print(Traducteur.traduire(code, 'js'));
}
