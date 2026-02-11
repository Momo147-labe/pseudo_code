import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/os_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../models/os_model.dart';
import '../../../theme.dart';

class TheoryView extends StatefulWidget {
  const TheoryView({super.key});

  @override
  State<TheoryView> createState() => _TheoryViewState();
}

class _TheoryViewState extends State<TheoryView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final osProvider = context.watch<OSProvider>();
    final theme = context.watch<ThemeProvider>().currentTheme;
    final data = osProvider.theoryData;

    if (osProvider.isLoadingTheory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (data == null) {
      return const Center(
        child: Text(
          "Erreur lors du chargement des données théoriques.",
          style: TextStyle(color: Colors.redAccent),
        ),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white30,
          tabs: const [
            Tab(text: "RÉSUMÉ"),
            Tab(text: "QUIZ"),
            Tab(text: "FLASHCARDS"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildResumeView(data, theme),
              _buildQuizView(osProvider, theme),
              _buildFlashcardsView(osProvider, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlashcardsView(OSProvider p, AppTheme theme) {
    if (p.flashcards.isEmpty)
      return const Center(child: Text("Aucune flashcard disponible."));

    final f = p.currentFlashcard!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Carte ${p.currentFlashcardIndex + 1} / ${p.flashcards.length}",
              style: const TextStyle(color: Colors.white30, fontSize: 12),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: p.toggleFlashcard,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    RotationTransition(turns: animation, child: child),
                child: Container(
                  key: ValueKey(p.isFlipped),
                  width: double.infinity,
                  height: 250,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: p.isFlipped
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: p.isFlipped
                          ? Colors.blue.withValues(alpha: 0.5)
                          : Colors.amber.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        p.isFlipped ? "DÉFINITION" : "TERME",
                        style: TextStyle(
                          color: p.isFlipped ? Colors.blue : Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        p.isFlipped ? f.definition : f.term,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: p.isFlipped ? 16 : 24,
                          fontWeight: p.isFlipped
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Clique sur la carte pour la retourner",
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: p.previousFlashcard,
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
                const SizedBox(width: 32),
                IconButton(
                  onPressed: p.nextFlashcard,
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeView(Map<String, dynamic> data, AppTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(data['titre'], data['auteur'], theme),
          const SizedBox(height: 32),
          _buildCategory("DÉFINITIONS DE BASE", Icons.info_outline, theme),
          _buildBaseDefinitions(data['definitions_de_base'], theme),
          const SizedBox(height: 32),
          _buildCategory(
            "SYSTÈME D'EXPLOITATION",
            Icons.settings_input_component,
            theme,
          ),
          _buildOSSection(data['systeme_exploitation'], theme),
          const SizedBox(height: 32),
          _buildCategory("ORDONNANCEMENT", Icons.reorder, theme),
          _buildSchedulingSection(data['ordonnancement_processeur'], theme),
          const SizedBox(height: 32),
          _buildCategory("GESTION DE LA MÉMOIRE", Icons.memory, theme),
          _buildMemorySection(data['gestion_memoire'], theme),
          const SizedBox(height: 32),
          _buildCategory("ARCHITECTURES", Icons.account_tree_outlined, theme),
          _buildArchitectureSection(data['architectures'], theme),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQuizView(OSProvider p, AppTheme theme) {
    if (p.quizQuestions.isEmpty) {
      return const Center(child: Text("Aucune question disponible."));
    }

    if (p.quizFinished) {
      return _buildQuizResults(p, theme);
    }

    final q = p.currentQuizQuestion!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "QUESTION ${p.currentQuizIndex + 1} SUR ${p.quizQuestions.length}",
                style: const TextStyle(
                  color: Colors.white30,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                "Score: ${p.quizScore}",
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            q.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          ...List.generate(q.options.length, (index) {
            final isCorrect = index == q.correctIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => p.answerQuestion(index),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: p.showExplanation
                        ? (isCorrect
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1))
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: p.showExplanation
                          ? (isCorrect
                                ? Colors.green.withValues(alpha: 0.5)
                                : Colors.red.withValues(alpha: 0.5))
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        String.fromCharCode(65 + index),
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          q.options[index],
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      if (p.showExplanation && isCorrect)
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (p.showExplanation) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "EXPLICATION :",
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q.explanation,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: p.nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  p.currentQuizIndex == p.quizQuestions.length - 1
                      ? "VOIR LES RÉSULTATS"
                      : "QUESTION SUIVANTE",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuizResults(OSProvider p, AppTheme theme) {
    final percentage = (p.quizScore / p.quizQuestions.length) * 100;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            percentage >= 50
                ? Icons.emoji_events
                : Icons.sentiment_very_dissatisfied,
            size: 80,
            color: percentage >= 50 ? Colors.amber : Colors.redAccent,
          ),
          const SizedBox(height: 24),
          const Text(
            "QUIZ TERMINÉ !",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Ton score : ${p.quizScore} / ${p.quizQuestions.length}",
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: p.startQuiz,
            icon: const Icon(Icons.refresh),
            label: const Text("RECOMMENCER LE QUIZ"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(String titre, String auteur, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.2),
            Colors.purple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Par $auteur",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(String title, IconData icon, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
        ],
      ),
    );
  }

  Widget _buildBaseDefinitions(Map<String, dynamic> defs, AppTheme theme) {
    return Column(
      children: [
        _buildConceptCard("Informatique", defs['informatique'], theme),
        _buildConceptCard("Ordinateur", defs['ordinateur'], theme),
        const SizedBox(height: 16),
        _buildSubCategory("Types de Périphériques", theme),
        ...(defs['peripherique']['types'] as List).map(
          (t) => _buildConceptCard(
            t['nom'],
            t['description'],
            theme,
            isSmall: true,
          ),
        ),
      ],
    );
  }

  Widget _buildOSSection(Map<String, dynamic> os, AppTheme theme) {
    return Column(
      children: [
        _buildConceptCard("Définition", os['definition'], theme),
        const SizedBox(height: 16),
        _buildSubCategory("Générations", theme),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: (os['generations'] as List)
                .map((g) => _buildGenerationCard(g, theme))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        _buildSubCategory("Tâches Principales", theme),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (os['taches_principales'] as List)
              .map(
                (t) => Chip(
                  label: Text(
                    t,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildMemorySection(Map<String, dynamic> mem, AppTheme theme) {
    return Column(
      children: (mem['concepts_cles'] as List)
          .map((c) => _buildConceptCard(c['nom'], c['description'], theme))
          .toList(),
    );
  }

  Widget _buildSchedulingSection(Map<String, dynamic> ord, AppTheme theme) {
    return Column(
      children: [
        _buildConceptCard("Définition", ord['definition'], theme),
        const SizedBox(height: 16),
        _buildSubCategory("Composantes", theme),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (ord['composantes'] as List)
              .map(
                (c) => Chip(
                  label: Text(
                    c,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  backgroundColor: Colors.blue.withValues(alpha: 0.05),
                  side: BorderSide(color: Colors.blue.withValues(alpha: 0.2)),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        _buildSubCategory("États des Processus", theme),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (ord['etats_processus'] as List)
              .map(
                (e) => Chip(
                  label: Text(
                    e,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  backgroundColor: Colors.green.withValues(alpha: 0.05),
                  side: BorderSide(color: Colors.green.withValues(alpha: 0.2)),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        _buildDemoPrompt(context, theme),
      ],
    );
  }

  Widget _buildDemoPrompt(BuildContext context, AppTheme theme) {
    final osProvider = context.read<OSProvider>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "EXPÉRIMENTER LA THÉORIE",
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Lancez une simulation pré-configurée pour voir ces concepts en action.",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDemoButton(
                label: "Démos FCFS",
                icon: Icons.play_circle_filled,
                onTap: () =>
                    osProvider.loadPresetSimulation(SchedulingAlgorithm.fcfs),
              ),
              _buildDemoButton(
                label: "Démos SJF",
                icon: Icons.play_circle_filled,
                onTap: () =>
                    osProvider.loadPresetSimulation(SchedulingAlgorithm.sjf),
              ),
              _buildDemoButton(
                label: "Démos Round Robin",
                icon: Icons.play_circle_filled,
                onTap: () => osProvider.loadPresetSimulation(
                  SchedulingAlgorithm.roundRobin,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemoButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildArchitectureSection(List<dynamic> archs, AppTheme theme) {
    return Column(
      children: archs
          .map((a) => _buildConceptCard(a['type'], a['description'], theme))
          .toList(),
    );
  }

  Widget _buildConceptCard(
    String title,
    String content,
    AppTheme theme, {
    bool isSmall = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              fontSize: isSmall ? 13 : 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: isSmall ? 12 : 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerationCard(Map<String, dynamic> g, AppTheme theme) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Génération ${g['numero']}",
            style: const TextStyle(
              color: Colors.purpleAccent,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            g['periode'],
            style: const TextStyle(color: Colors.white30, fontSize: 10),
          ),
          const SizedBox(height: 8),
          Text(
            g['technologie'],
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategory(String title, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
