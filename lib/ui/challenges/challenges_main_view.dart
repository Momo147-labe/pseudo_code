import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme.dart';
import 'challenge_list_view.dart';
import 'leaderboard_view.dart';
import 'challenge_detail_view.dart';

class ChallengesMainView extends StatefulWidget {
  const ChallengesMainView({super.key});

  @override
  State<ChallengesMainView> createState() => _ChallengesMainViewState();
}

class _ChallengesMainViewState extends State<ChallengesMainView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final challengeProvider = context.watch<ChallengeProvider>();

    if (challengeProvider.activeChallenge != null) {
      return ChallengeDetailView(challenge: challengeProvider.activeChallenge!);
    }

    return Scaffold(
      backgroundColor: ThemeColors.editorBg(theme),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          decoration: BoxDecoration(
            color: ThemeColors.editorBg(theme),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: ThemeColors.vscodeBlue,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: "DÉFIS DISPONIBLES"),
              Tab(text: "CLASSEMENT AMIS"),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [ChallengeListView(), LeaderboardView()],
      ),
    );
  }
}
