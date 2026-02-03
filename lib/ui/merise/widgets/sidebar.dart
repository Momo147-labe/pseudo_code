import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/merise_provider.dart';
import '../../../theme.dart';

class MeriseSidebar extends StatelessWidget {
  final AppTheme theme;
  final bool isMobile;
  const MeriseSidebar({super.key, required this.theme, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeriseProvider>();
    final scale = provider.textScaleFactor;
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;

    return Container(
      width: 270,
      constraints: const BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme),
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(scale, isDark),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildSectionLabel("Conception", scale),
                _NavItem(
                  icon: Icons.gavel,
                  label: "Règles de gestion",
                  isActive: provider.activeView == 'regles',
                  theme: theme,
                  scale: scale,
                  onTap: () => provider.setActiveView('regles'),
                ),
                _NavItem(
                  icon: Icons.schema,
                  label: "MCD",
                  isActive: provider.activeView == 'mcd',
                  theme: theme,
                  scale: scale,
                  onTap: () => provider.setActiveView('mcd'),
                ),
                _NavItem(
                  icon: Icons.menu_book,
                  label: "Dictionnaire",
                  isActive: provider.activeView == 'dictionnaire',
                  theme: theme,
                  scale: scale,
                  onTap: () => provider.setActiveView('dictionnaire'),
                ),
                _NavItem(
                  icon: Icons.alt_route,
                  label: "GDF (Dépendances)",
                  isActive: provider.activeView == 'gdf',
                  theme: theme,
                  scale: scale,
                  onTap: () => provider.setActiveView('gdf'),
                ),
                if (!isMobile) ...[
                  const SizedBox(height: 24),
                  _buildSectionLabel("Palette MCD", scale),
                  _DraggableItem(
                    icon: Icons.rectangle_outlined,
                    label: "Nouvelle Entité",
                    data: "new_entity",
                    theme: theme,
                    scale: scale,
                  ),
                  _DraggableItem(
                    icon: Icons.circle_outlined,
                    label: "Nouvelle Relation",
                    data: "new_relation",
                    theme: theme,
                    scale: scale,
                  ),
                  _LinkToolItem(theme: theme, scale: scale),
                ],
                const SizedBox(height: 24),
                _buildSectionLabel("Conception Avancée", scale),
                _NavItem(
                  icon: Icons.account_tree,
                  label: "MLD",
                  isActive: provider.activeView == 'mld',
                  theme: theme,
                  scale: scale,
                  onTap: () => provider.setActiveView('mld'),
                ),
                _NavItem(
                  icon: Icons.storage,
                  label: "MPD",
                  isActive: provider.activeView == 'mpd',
                  theme: theme,
                  scale: scale,
                  onTap: () => provider.setActiveView('mpd'),
                ),
                const SizedBox(height: 24),
                _buildSectionLabel("Outils & Analyse", scale),
                _NavItem(
                  icon: Icons.align_horizontal_center,
                  label: "Normalisation",
                  isActive: provider.activeView == 'normalisation',
                  theme: theme,
                  scale: scale,
                  onTap: () => provider.setActiveView('normalisation'),
                ),
                _NavItem(
                  icon: Icons.join_inner,
                  label: "Requêtes & jointures",
                  isActive: provider.activeView == 'requetes',
                  theme: theme,
                  scale: scale,
                  onTap: () => provider.setActiveView('requetes'),
                ),
                _NavItem(
                  icon: Icons.play_circle_outline,
                  label: "Simulation",
                  isActive: provider.activeView == 'simulation',
                  theme: theme,
                  scale: scale,
                  onTap: () => provider.setActiveView('simulation'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double scale, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.pie_chart_outline,
              color: Color(0xFF1E88E5),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "MERISE Studio",
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: ThemeColors.textMain(theme),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, double scale) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10 * scale,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final AppTheme theme;
  final double scale;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.theme,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1E88E5);
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;

    return Padding(
      padding: const EdgeInsets.only(right: 0),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? primaryColor.withOpacity(0.1) : Colors.transparent,
          border: isActive
              ? Border(right: BorderSide(color: primaryColor, width: 4))
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20 * scale,
                  color: isActive
                      ? primaryColor
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13 * scale,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? primaryColor
                          : ThemeColors.textMain(theme).withOpacity(0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DraggableItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String data;
  final AppTheme theme;
  final double scale;

  const _DraggableItem({
    required this.icon,
    required this.label,
    required this.data,
    required this.theme,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1E88E5);
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    final color = isDark ? Colors.grey[300] : Colors.grey[700];

    return Draggable<String>(
      data: data,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20 * scale),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.5, child: _buildItem(color)),
      child: _buildItem(color),
    );
  }

  Widget _buildItem(Color? color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20 * scale, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13 * scale,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.drag_indicator,
            size: 14 * scale,
            color: color?.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

class _LinkToolItem extends StatelessWidget {
  final AppTheme theme;
  final double scale;
  const _LinkToolItem({required this.theme, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Consumer<MeriseProvider>(
      builder: (context, provider, child) {
        final isActive = provider.isLinkMode;
        final primaryColor = const Color(0xFF1E88E5);
        final isDark = theme != AppTheme.light && theme != AppTheme.papier;
        final color = isDark ? Colors.grey[300] : Colors.grey[700];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: InkWell(
            onTap: () => provider.toggleLinkMode(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? primaryColor.withOpacity(0.1)
                    : Colors.transparent,
                border: Border.all(
                  color: isActive ? primaryColor : Colors.transparent,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isActive ? Icons.link : Icons.add_link,
                    size: 18 * scale,
                    color: isActive ? primaryColor : color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Outil Lien",
                      style: TextStyle(
                        fontSize: 12 * scale,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isActive ? primaryColor : color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
