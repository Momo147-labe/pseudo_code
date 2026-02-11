import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/merise_provider.dart';
import '../../../theme.dart';

class MeriseStatusFooter extends StatelessWidget {
  final AppTheme theme;
  final bool isMobile;
  const MeriseStatusFooter({
    super.key,
    required this.theme,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeriseProvider>();
    final primaryColor = const Color(0xFF1E88E5);
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey[200]!;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme),
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatsGroup(provider, theme),
            if (!isMobile) ...[
              const SizedBox(width: 24),
              _buildActionsGroup(primaryColor, provider, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGroup(MeriseProvider provider, AppTheme theme) {
    final scale = provider.textScaleFactor;
    return Row(
      children: [
        _buildStatItem("Entités ${provider.entities.length}", scale, theme),
        _buildStatItem(
          "Associations ${provider.relations.length}",
          scale,
          theme,
        ),
        _buildStatItem("Zoom ${(provider.zoom * 100).toInt()}%", scale, theme),
      ],
    );
  }

  Widget _buildStatItem(String text, double scale, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10 * scale,
          fontWeight: FontWeight.w600,
          color: ThemeColors.textMain(theme).withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildActionsGroup(
    Color primaryColor,
    MeriseProvider provider,
    AppTheme theme,
  ) {
    final scale = provider.textScaleFactor;
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;

    return Row(
      children: [
        // Contrôles de taille de police
        _FontSizeControl(provider: provider, theme: theme),
        const SizedBox(width: 16),
        Container(
          width: 1,
          height: 16,
          color: isDark ? Colors.white10 : Colors.grey[300],
        ),
        const SizedBox(width: 16),
        _FooterButton(
          icon: Icons.grid_view,
          label: "Auto-Layout",
          color: primaryColor,
          scale: scale,
          theme: theme,
          onTap: () => provider.autoLayout(),
        ),
        const SizedBox(width: 12),
        _FooterButton(
          icon: Icons.bubble_chart,
          label: "Force Layout",
          color: primaryColor,
          scale: scale,
          theme: theme,
          onTap: () => provider.forceDirectedLayout(),
        ),
        const SizedBox(width: 16),
        Container(
          width: 1,
          height: 16,
          color: isDark ? Colors.white10 : Colors.grey[300],
        ),
        const SizedBox(width: 16),
        _FooterButton(
          icon: Icons.save_outlined,
          label: "Sauvegarder",
          color: primaryColor,
          scale: scale,
          theme: theme,
          onTap: () => provider.requestSave(),
        ),
        const SizedBox(width: 12),
        _FooterButton(
          icon: Icons.storage,
          label: "Exporter SQL",
          color: primaryColor,
          scale: scale,
          theme: theme,
          onTap: () {},
        ),
      ],
    );
  }
}

class _FontSizeControl extends StatelessWidget {
  final MeriseProvider provider;
  final AppTheme theme;

  const _FontSizeControl({required this.provider, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    final color = isDark ? Colors.grey[400] : Colors.grey[700];
    final scale = provider.textScaleFactor;

    return Row(
      children: [
        Text(
          "Police ",
          style: TextStyle(
            fontSize: 9 * scale,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        _TextScaleButton(
          icon: Icons.remove,
          onTap: provider.decreaseTextScale,
          theme: theme,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            "${(scale * 100).toInt()}%",
            style: TextStyle(
              fontSize: 10 * scale,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _TextScaleButton(
          icon: Icons.add,
          onTap: provider.increaseTextScale,
          theme: theme,
        ),
      ],
    );
  }
}

class _TextScaleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final AppTheme theme;

  const _TextScaleButton({
    required this.icon,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Icon(
          icon,
          size: 14,
          color: isDark ? Colors.blue[300] : Colors.blue[700],
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double scale;
  final AppTheme theme;
  final VoidCallback onTap;

  const _FooterButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.scale,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 12 * scale,
            color: ThemeColors.textMain(theme).withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10 * scale,
              fontWeight: FontWeight.w600,
              color: ThemeColors.textMain(theme).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
