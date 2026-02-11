import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/example_provider.dart';
import '../providers/file_provider.dart';
import '../theme.dart';

class EducationalPanel extends StatefulWidget {
  final String initialTab; // 'exercice', 'guide', 'exemple'
  final bool isMobile;

  const EducationalPanel({
    super.key,
    this.initialTab = 'exercice',
    this.isMobile = false,
  });

  @override
  State<EducationalPanel> createState() => _EducationalPanelState();
}

class _EducationalPanelState extends State<EducationalPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialTab == 'guide') initialIndex = 1;
    if (widget.initialTab == 'exemple') initialIndex = 2;

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = widget.isMobile ? screenWidth * 0.85 : 350.0;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: panelWidth,
        height: double.infinity,
        color: ThemeColors.sidebarBg(theme),
        child: Column(
          children: [
            Container(
              color: ThemeColors.editorBg(theme),
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.blueAccent,
                      unselectedLabelColor: ThemeColors.textMain(
                        theme,
                      ).withValues(alpha: 0.5),
                      indicatorColor: Colors.blueAccent,
                      tabs: const [
                        Tab(icon: Icon(Icons.assignment), text: "Exercices"),
                        Tab(icon: Icon(Icons.import_contacts), text: "Guide"),
                        Tab(icon: Icon(Icons.lightbulb), text: "Exemples"),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 24,
                      color: ThemeColors.textMain(theme),
                    ),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Fermer',
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ExercisesTab(theme: theme),
                  _GuideTab(theme: theme),
                  _ExamplesTab(theme: theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExercisesTab extends StatelessWidget {
  final AppTheme theme;

  const _ExercisesTab({required this.theme});

  @override
  Widget build(BuildContext context) {
    final exampleProvider = context.watch<ExampleProvider>();
    final fileProvider = context.read<FileProvider>();
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;

    if (exampleProvider.exercices.isEmpty) {
      if (exampleProvider.isLoading) {
        return Center(
          child: CircularProgressIndicator(color: ThemeColors.textMain(theme)),
        );
      }
      return Center(
        child: Text(
          "Aucun exercice chargé.",
          style: TextStyle(color: ThemeColors.textMain(theme)),
        ),
      );
    }
    return ListView.builder(
      itemCount: exampleProvider.exercices.length,
      itemBuilder: (context, index) {
        final ex = exampleProvider.exercices[index];
        return Card(
          color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ExpansionTile(
            title: Text(
              ex['titre'] ?? 'Exercice ${index + 1}',
              style: TextStyle(
                color: ThemeColors.textBright(theme),
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "Difficulté: ${ex['difficulte'] ?? '?'}",
              style: TextStyle(
                color: ThemeColors.textMain(theme).withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  ex['enonce'] ?? '',
                  style: TextStyle(color: ThemeColors.textMain(theme)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 24),
                      tooltip: "Copier l'énoncé",
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: ex['enonce'] ?? ''),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Énoncé copié !")),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.play_circle_outline, size: 24),
                      label: const Text("Initialiser l'exo"),
                      onPressed: () {
                        final titre = ex['titre'] ?? 'Exercice';
                        final code =
                            "Algorithme $titre\nVariables\n\nDebut\n  // Votre code ici\nFin";
                        fileProvider.insertCode(code);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Boilerplate inséré dans l'éditeur"),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GuideTab extends StatelessWidget {
  final AppTheme theme;

  const _GuideTab({required this.theme});

  @override
  Widget build(BuildContext context) {
    final fileProvider = context.read<FileProvider>();
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    final concepts = [
      {
        "titre": "Variables & Types de base",
        "description":
            "Déclarez vos variables avec leur type (entier, réel, chaine, booleen).",
        "code":
            "Variables\n  age : entier\n  prix : reel\n  nom : chaine\n  estVrai : booleen",
      },
      {
        "titre": "Constantes",
        "description":
            "Valeurs dont la valeur ne change jamais durant l'exécution.",
        "code": "Const\n  PI = 3.14\n  TVA = 0.20",
      },
      {
        "titre": "Affichage / Lecture",
        "description": "Entrées/sorties pour interagir avec l'utilisateur.",
        "code": "Afficher(\"Quel est ton nom ?\")\nLire(nom)",
      },
      {
        "titre": "Conditions (Si ... Alors)",
        "description": "Exécuter des instructions selon une condition logique.",
        "code":
            "Si age >= 18 Alors\n  Afficher(\"Majeur\")\nSinon\n  Afficher(\"Mineur\")\nFinSi",
      },
      {
        "titre": "Choix Multiples (Selon)",
        "description": "Gérer plusieurs cas pour une seule variable.",
        "code":
            "Selon note Faire\n  Cas 20 : Afficher(\"Parfait\")\n  Cas 10 : Afficher(\"Moyen\")\n  Sinon : Afficher(\"Autre\")\nFinSelon",
      },
      {
        "titre": "Boucle Pour",
        "description": "Répéter un bloc pour un intervalle de valeurs connu.",
        "code": "Pour i de 1 à 10 Faire\n  Afficher(\"Tour : \", i)\nFinPour",
      },
      {
        "titre": "Boucle TantQue",
        "description": "Répéter tant qu'une condition est satisfaite.",
        "code": "TantQue i < 10 Faire\n  i <- i + 1\nFinTantQue",
      },
      {
        "titre": "Boucle Répéter ... Jusqu'à",
        "description":
            "Répéter au moins une fois jusqu'à ce que la condition soit vraie.",
        "code": "Repeter\n  Lire(choix)\nJusqua choix = 0",
      },
      {
        "titre": "Tableaux 1D",
        "description":
            "Liste d'éléments de même type définie avec le mot-clé Type.",
        "code":
            "Type MonTableau = Tableau[1..5] de entier\n\nVariables\n  T : MonTableau\nDebut\n  T[1] <- 10",
      },
      {
        "titre": "Tableaux 2D (Matrices)",
        "description": "Grille de données définie avec le mot-clé Type.",
        "code":
            "Type MaMatrice = Tableau[1..3, 1..3] de reel\n\nVariables\n  M : MaMatrice\nDebut\n  M[1, 1] <- 1.5",
      },
      {
        "titre": "Structures",
        "description": "Regrouper plusieurs données sous un même nom.",
        "code":
            "Type Etudiant = Structure\n  nom : chaine\n  moyenne : reel\nFinStructure\n\nVariables\n  e : Etudiant",
      },
      {
        "titre": "Tableaux de Structures",
        "description": "Liste d'objets complexes.",
        "code":
            "Variables\n  classe : Tableau[1..30] de Etudiant\nDebut\n  classe[1].nom <- \"Momo\"",
      },
      {
        "titre": "Fonctions",
        "description":
            "Sous-programme qui effectue un calcul et RETOURNE une valeur.",
        "code":
            "Fonction Somme(a, b : entier) : entier\nDebut\n  Retourner a + b\nFinFonction",
      },
      {
        "titre": "Procédures",
        "description":
            "Sous-programme qui effectue des actions sans retourner de valeur.",
        "code":
            "Procedure Saluer(nom : chaine)\nDebut\n  Afficher(\"Bonjour \", nom)\nFinProcedure",
      },
    ];

    return ListView.builder(
      itemCount: concepts.length,
      itemBuilder: (context, index) {
        final c = concepts[index];
        return Card(
          color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ExpansionTile(
            title: Text(
              c['titre']!,
              style: TextStyle(
                color: ThemeColors.textBright(theme),
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      c['description']!,
                      style: TextStyle(
                        color: ThemeColors.textMain(theme),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        c['code']!,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          color: ThemeColors.textBright(theme),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, size: 24),
                          tooltip: "Copier le code",
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: c['code']!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Code copié !")),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 24),
                          tooltip: "Insérer dans l'éditeur",
                          onPressed: () {
                            fileProvider.insertCode(c['code']!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Code inséré")),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExamplesTab extends StatelessWidget {
  final AppTheme theme;

  const _ExamplesTab({required this.theme});

  @override
  Widget build(BuildContext context) {
    final exampleProvider = context.watch<ExampleProvider>();
    final fileProvider = context.read<FileProvider>();
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;

    return ListView.builder(
      itemCount: exampleProvider.builtInExamples.length,
      itemBuilder: (context, index) {
        final ex = exampleProvider.builtInExamples[index];
        return Card(
          color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ExpansionTile(
            title: Text(
              ex['title']!,
              style: TextStyle(
                color: ThemeColors.textBright(theme),
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ex['code']!,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          color: ThemeColors.textBright(theme),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, size: 24),
                          tooltip: "Copier le code",
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: ex['code']!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Code copié !")),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          tooltip: "Insérer dans l'éditeur",
                          onPressed: () {
                            fileProvider.insertCode(ex['code']!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Code inséré")),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
