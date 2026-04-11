import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../theme.dart';
import 'profile_modal.dart';
import 'documentation_page.dart';
import 'auth/auth_choice_modal.dart';
import 'auth/user_profile_modal.dart';
import '../providers/challenge_provider.dart';

import '../services/update_service.dart';

class ActivityBar extends StatelessWidget {
  const ActivityBar({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final challengeProvider = context.watch<ChallengeProvider>();
    final theme = themeProvider.currentTheme;
    final profile = challengeProvider.myProfile;

    return Container(
      width: 45,
      color: ThemeColors.activityBarBg(theme),
      child: Column(
        children: [
          _ActivityIcon(
            icon: Icons.copy,
            isActive: appProvider.activeSidebarTab == 'explorer',
            onTap: () => appProvider.setActiveSidebarTab('explorer'),
            tooltip: "Algorithme",
          ),
          _ActivityIcon(
            icon: Icons.schema_outlined,
            isActive: appProvider.activeSidebarTab == 'merise',
            onTap: () => appProvider.setActiveSidebarTab('merise'),
            tooltip: "Modélisation Merise",
          ),
          _ActivityIcon(
            icon: Icons.auto_graph_outlined,
            isActive: appProvider.activeSidebarTab == 'graph',
            onTap: () => appProvider.setActiveSidebarTab('graph'),
            tooltip: "Graph Studio",
          ),
          _ActivityIcon(
            icon: Icons.auto_awesome,
            isActive: appProvider.activeSidebarTab == 'ai',
            onTap: () => appProvider.setActiveSidebarTab('ai'),
            tooltip: "Assistant IA",
          ),

          _ActivityIcon(
            icon: Icons.emoji_events_outlined,
            isActive: appProvider.activeSidebarTab == 'challenges',
            onTap: () => appProvider.setActiveSidebarTab('challenges'),
            tooltip: "Compétitions & Défis",
          ),

          _ActivityIcon(
            icon: Icons.terminal_outlined,
            isActive: appProvider.isConsoleVisible,
            onTap: () => appProvider.toggleConsole(),
            tooltip: "Afficher/Masquer la console",
          ),
          _ActivityIcon(
            icon: Icons.system_update_alt,
            onTap: () =>
                UpdateService.instance.checkForUpdate(context, isManual: true),
            tooltip: "Vérifier les mises à jour",
          ),
          const Spacer(),
          _ActivityIcon(
            icon: _getThemeIcon(theme),
            onTap: () => themeProvider.toggleTheme(),
            tooltip: 'Changer de thème',
          ),
          _ActivityIcon(
            icon: Icons.help_outline,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DocumentationPage(),
              ),
            ),
            tooltip: "Documentation Plateforme",
          ),
          _ActivityIcon(
            icon: Icons.code,
            onTap: () => showDialog(
              context: context,
              builder: (context) => const ProfileModal(),
            ),
            tooltip: "Profil Développeur",
          ),
        ],
      ),
    );
  }

  IconData _getThemeIcon(AppTheme theme) {
    switch (theme) {
      case AppTheme.dark:
        return Icons.dark_mode;
      case AppTheme.light:
        return Icons.light_mode;
      case AppTheme.dracula:
        return Icons.bloodtype_outlined;
      case AppTheme.oneDark:
        return Icons.code;
      case AppTheme.papier:
        return Icons.description_outlined;
      case AppTheme.nord:
        return Icons.ac_unit;
      case AppTheme.aura:
        return Icons.auto_awesome;
      case AppTheme.genese:
        return Icons.rocket_launch_outlined;
    }
  }
}

class _ActivityIcon extends StatelessWidget {
  final IconData icon;
  final String? imageUrl;
  final bool isActive;
  final VoidCallback? onTap;
  final String? tooltip;

  const _ActivityIcon({
    required this.icon,
    this.imageUrl,
    this.isActive = false,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: isActive
                ? const Border(left: BorderSide(color: Colors.white, width: 2))
                : null,
          ),
          child: imageUrl != null
              ? Center(
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                )
              : Icon(
                  icon,
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                  size: 24,
                ),
        ),
      ),
    );
  }
}
