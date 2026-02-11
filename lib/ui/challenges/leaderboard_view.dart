import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme.dart';
import '../../models/challenge_model.dart';

class LeaderboardView extends StatelessWidget {
  const LeaderboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final challengeProvider = context.watch<ChallengeProvider>();
    final theme = context.watch<ThemeProvider>().currentTheme;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return StreamBuilder<List<UserProfile>>(
      stream: challengeProvider.leaderboardStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];

        return Column(
          children: [
            _buildHeader(theme, isMobile),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                itemCount: users.length,
                separatorBuilder: (context, index) =>
                    const Divider(color: Colors.white12, height: 1),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isMe = user.id == challengeProvider.myProfile?.id;
                  return _LeaderboardItem(
                    user: user,
                    rank: index + 1,
                    theme: theme,
                    isMe: isMe,
                    isMobile: isMobile,
                  );
                },
              ),
            ),
          ],
        );
      },
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "CLASSEMENT GÉNÉRAL",
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 16 : 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          Icon(
            Icons.emoji_events,
            color: Colors.amber,
            size: isMobile ? 24 : 28,
          ),
        ],
      ),
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  final UserProfile user;
  final int rank;
  final AppTheme theme;
  final bool isMe;
  final bool isMobile;

  const _LeaderboardItem({
    required this.user,
    required this.rank,
    required this.theme,
    required this.isMe,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 12 : 16,
        horizontal: isMobile ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: isMe
            ? ThemeColors.vscodeBlue.withValues(alpha: 0.1)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            alignment: Alignment.center,
            child: _buildRankBadge(rank),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            backgroundColor: ThemeColors.vscodeBlue.withValues(alpha: 0.2),
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Text(
                    (user.username ?? "U")[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username ?? "Utilisateur Anonyme",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
                Text(
                  "Niveau ${user.level}",
                  style: TextStyle(
                    color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${user.xp} XP",
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (isMe)
                const Text(
                  "VOUS",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank <= 3) {
      Color color;
      if (rank == 1)
        color = Colors.amber;
      else if (rank == 2)
        color = Colors.grey[300]!;
      else
        color = Colors.brown[300]!;

      return Icon(Icons.workspace_premium, color: color, size: 24);
    }
    return Text(
      "$rank",
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
