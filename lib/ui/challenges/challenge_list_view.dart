import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme.dart';
import '../../models/challenge_model.dart';

class ChallengeListView extends StatefulWidget {
  const ChallengeListView({super.key});

  @override
  State<ChallengeListView> createState() => _ChallengeListViewState();
}

class _ChallengeListViewState extends State<ChallengeListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChallengeProvider>().loadChallenges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final challengeProvider = context.watch<ChallengeProvider>();
    final theme = context.watch<ThemeProvider>().currentTheme;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    if (challengeProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildHeader(theme, isMobile),
        Expanded(
          child: challengeProvider.challenges.isEmpty
              ? _buildEmptyState(theme)
              : GridView.builder(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: isMobile ? width : 400,
                    mainAxisExtent: isMobile ? 180 : 200,
                    crossAxisSpacing: isMobile ? 12 : 16,
                    mainAxisSpacing: isMobile ? 12 : 16,
                  ),
                  itemCount: challengeProvider.challenges.length,
                  itemBuilder: (context, index) {
                    final challenge = challengeProvider.challenges[index];
                    return _ChallengeCard(challenge: challenge, theme: theme);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(AppTheme theme, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: ThemeColors.editorBg(theme),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "COMPÉTITIONS & DÉFIS",
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Relevez des défis, gagnez de l'XP et devenez un maître du pseudo-code.",
            style: TextStyle(
              color: ThemeColors.textMain(theme).withValues(alpha: 0.7),
              fontSize: isMobile ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppTheme theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: ThemeColors.textMain(theme).withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            "Aucun défi disponible pour le moment.",
            style: TextStyle(
              color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final AppTheme theme;

  const _ChallengeCard({required this.challenge, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.read<ChallengeProvider>().setActiveChallenge(challenge);
          // Navigation logic will be handled in a DetailView
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252526) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _DifficultyTag(difficulty: challenge.difficulty),
                  Text(
                    "${challenge.xpReward} XP",
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                challenge.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  challenge.description,
                  style: TextStyle(
                    color: ThemeColors.textMain(theme).withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "COMMENCER",
                    style: TextStyle(
                      color: ThemeColors.vscodeBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: ThemeColors.vscodeBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyTag extends StatelessWidget {
  final ChallengeDifficulty difficulty;

  const _DifficultyTag({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (difficulty) {
      case ChallengeDifficulty.Easy:
        color = Colors.greenAccent;
        break;
      case ChallengeDifficulty.Medium:
        color = Colors.orangeAccent;
        break;
      case ChallengeDifficulty.Hard:
        color = Colors.redAccent;
        break;
      case ChallengeDifficulty.Expert:
        color = Colors.purpleAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        difficulty.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
