-- Script pour ajouter des défis initiaux dans la table public.challenges

-- Défi 1 : HelloWorld
INSERT INTO public.challenges (title, description, instructions, difficulty, xp_reward, initial_code, test_cases)
VALUES (
  'Hello World',
  'Le grand classique de la programmation.',
  'Écrivez un programme qui affiche exactement le message : "Bonjour le monde".',
  'Easy',
  10,
  'Algorithme HelloWorld
Début
  // Votre code ici
Fin',
  '[
    {"id": 1, "input": "", "output": "Bonjour le monde"}
  ]'::jsonb
);

-- Défi 2 : Addition simple
INSERT INTO public.challenges (title, description, instructions, difficulty, xp_reward, initial_code, test_cases)
VALUES (
  'Addition de deux nombres',
  'Calculer la somme de deux entrées.',
  'Le programme doit lire deux nombres entiers A et B, puis afficher leur somme.',
  'Easy',
  25,
  'Algorithme Addition
Variables
  a, b, somme : Entier
Début
  // Lire a et b
  // Calculer somme
  // Afficher somme
Fin',
  '[
    {"id": 1, "input": "5\n10", "output": "15"},
    {"id": 2, "input": "0\n0", "output": "0"},
    {"id": 3, "input": "-5\n5", "output": "0"}
  ]'::jsonb
);

-- Défi 3 : Calcul de factorielle
INSERT INTO public.challenges (title, description, instructions, difficulty, xp_reward, initial_code, test_cases)
VALUES (
  'Factorielle',
  'Calculer la factorielle d''un nombre N.',
  'Le programme reçoit un entier N et doit afficher sa factorielle (N!). On suppose N >= 0.',
  'Medium',
  100,
  'Algorithme Factorielle
Variables
  n, i, f : Entier
Début
  Lire n
  f <- 1
  // Votre boucle ici
  Afficher f
Fin',
  '[
    {"id": 1, "input": "0", "output": "1"},
    {"id": 2, "input": "5", "output": "120"},
    {"id": 3, "input": "10", "output": "3628800"}
  ]'::jsonb
);
