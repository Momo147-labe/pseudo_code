INSERT INTO enseignants_info (user_id, nom, prenom, email, etablissement, matiere_principale, specialites)
VALUES (
    'prof_1', 
    'Dupont',
    'Jean',
    'jean.dupont@universite.edu',
    'Université de Technologie',
    'Algorithmique',
    ARRAY['Algorithmique', 'Structures de données', 'Complexité']
)
ON CONFLICT (user_id) DO UPDATE SET
    nom = EXCLUDED.nom,
    prenom = EXCLUDED.prenom,
    email = EXCLUDED.email,
    etablissement = EXCLUDED.etablissement,
    matiere_principale = EXCLUDED.matiere_principale,
    specialites = EXCLUDED.specialites;
