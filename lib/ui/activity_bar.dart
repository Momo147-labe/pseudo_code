import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../theme.dart';
import 'profile_modal.dart';
import 'documentation_modal.dart';

class ActivityBar extends StatelessWidget {
  const ActivityBar({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final theme = themeProvider.currentTheme;

    return Container(
      width: 48,
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
            icon: Icons.bug_report_outlined,
            isActive: appProvider.activeSidebarTab == 'debug',
            onTap: () => appProvider.setActiveSidebarTab('debug'),
            tooltip: "Débogage",
          ),
          _ActivityIcon(
            icon: Icons.auto_awesome,
            isActive: appProvider.activeSidebarTab == 'ai',
            onTap: () => appProvider.setActiveSidebarTab('ai'),
            tooltip: "Assistant IA",
          ),
          _ActivityIcon(
            icon: Icons.terminal_outlined,
            isActive: appProvider.isConsoleVisible,
            onTap: () => appProvider.toggleConsole(),
            tooltip: "Afficher/Masquer la console",
          ),
          const _ActivityIcon(
            icon: Icons.grid_view_outlined,
            tooltip: "Extensions (Bientôt)",
          ),
          const Spacer(),
          _ActivityIcon(
            icon: _getThemeIcon(theme),
            onTap: () => themeProvider.toggleTheme(),
            tooltip: 'Changer de thème',
          ),
          _ActivityIcon(
            icon: Icons.account_circle_outlined,
            onTap: () => showDialog(
              context: context,
              builder: (context) => const ProfileModal(),
            ),
            tooltip: "Profil Développeur",
          ),
          _ActivityIcon(
            icon: Icons.help_outline,
            onTap: () => showDialog(
              context: context,
              builder: (context) => const DocumentationModal(),
            ),
            tooltip: "Documentation Plateforme",
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
    }
  }
}

class _ActivityIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;
  final String? tooltip;

  const _ActivityIcon({
    required this.icon,
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
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
            size: 24,
          ),
        ),
      ),
    );
  }
}
