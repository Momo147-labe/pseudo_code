import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/file_provider.dart';
import '../theme.dart';
import 'educational_panel.dart';
import '../outils/traducteur.dart';
import '../outils/exportateur.dart';
import 'package:flutter/services.dart';

class BarreHaut extends StatelessWidget {
  final VoidCallback onExecuter;
  final VoidCallback onDebug;
  final bool isMobile;

  const BarreHaut({
    super.key,
    required this.onExecuter,
    required this.onDebug,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final fileProvider = context.watch<FileProvider>();
    final activeFile = fileProvider.activeFile;
    final theme = themeProvider.currentTheme;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: ThemeColors.topbarBg(theme),
        border: const Border(bottom: BorderSide(color: Colors.black26)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu, size: 20),
              onPressed: () => Scaffold.of(context).openDrawer(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: ThemeColors.textMain(theme),
            ),
          if (isMobile) const SizedBox(width: 8),
          _MenuText(
            'Fichier',
            theme: theme,
            onTap: () => _showFileMenu(context),
          ),
          if (!isMobile)
            _MenuText(
              'Exporter',
              theme: theme,
              onTap: () => _showExportMenu(context),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Center(
              child: Text(
                _buildTitleText(appProvider, activeFile),
                style: TextStyle(
                  color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (!isMobile) ...[
            _HeaderAction(
              icon: Icons.text_increase,
              onPressed: () =>
                  appProvider.setFontSize(appProvider.fontSize + 1),
              tooltip: 'Augmenter la police',
              theme: theme,
            ),
            Text(
              "${appProvider.fontSize.toInt()}",
              style: TextStyle(
                color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
            _HeaderAction(
              icon: Icons.text_decrease,
              onPressed: () =>
                  appProvider.setFontSize(appProvider.fontSize - 1),
              tooltip: 'Diminuer la police',
              theme: theme,
            ),
            const SizedBox(width: 16),
          ],
          if (!isMobile) ...[
            _HeaderAction(
              icon: Icons.assignment,
              onPressed: () => _showEducationalPanel(context, 'exercice'),
              tooltip: 'Exercices',
              theme: theme,
            ),
            _HeaderAction(
              icon: Icons.import_contacts,
              onPressed: () => _showEducationalPanel(context, 'guide'),
              tooltip: 'Guide Pseudo-Code',
              theme: theme,
            ),
            _HeaderAction(
              icon: Icons.lightbulb_outline,
              onPressed: () => _showEducationalPanel(context, 'exemple'),
              tooltip: 'Exemples d\'algorithmes',
              theme: theme,
            ),
            _HeaderAction(
              icon: Icons.help_outline,
              onPressed: () => _showEducationalPanel(context, 'guide'),
              tooltip: 'Aide & Syntaxe',
              theme: theme,
            ),
            const SizedBox(width: 8),
          ],
          _HeaderAction(
            icon: Icons.save_outlined,
            onPressed: () => fileProvider.saveCurrentFile(),
            tooltip: 'Sauvegarder le fichier (Ctrl+S)',
            theme: theme,
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onDebug,
            icon: const Icon(
              Icons.bug_report,
              size: 18,
              color: Colors.blueAccent,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Lancer en mode pas-à-pas',
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onExecuter,
            icon: const Icon(
              Icons.play_arrow,
              size: 18,
              color: Colors.greenAccent,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Exécuter le code',
          ),
          SizedBox(width: isMobile ? 8 : 16),
        ],
      ),
    );
  }

  String _buildTitleText(AppProvider provider, AppFile? activeFile) {
    final isInMeriseMode = provider.activeMainView == ActiveMainView.merise;

    if (isInMeriseMode) {
      return 'Merise — Pseudo-Code IDE';
    } else {
      // Mode Algorithme (mode normal)
      if (activeFile != null) {
        return '${activeFile.name}${activeFile.isModified ? " •" : ""} — Algorithme — Pseudo-Code IDE';
      } else {
        return 'Algorithme — Pseudo-Code IDE';
      }
    }
  }

  void _showEducationalPanel(BuildContext context, String tab) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'EducationalPanel',
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: EducationalPanel(initialTab: tab, isMobile: isMobile),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(anim1),
          child: child,
        );
      },
    );
  }

  void _showFileMenu(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final fileProvider = context.read<FileProvider>();
    final theme = themeProvider.currentTheme;
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;

    showMenu<dynamic>(
      context: context,
      position: const RelativeRect.fromLTRB(0, 36, 0, 0),
      color: ThemeColors.sidebarBg(theme),
      items: [
        PopupMenuItem(
          child: Text(
            "Nouveau Fichier",
            style: TextStyle(color: ThemeColors.textMain(theme)),
          ),
          onTap: () => fileProvider.createFile(
            fileProvider.currentDirectory,
            "nouveau.alg",
          ),
        ),
        PopupMenuItem(
          child: Text(
            "Nouveau Dossier",
            style: TextStyle(color: ThemeColors.textMain(theme)),
          ),
          onTap: () => fileProvider.createDirectory(
            fileProvider.currentDirectory,
            "nouveau_dossier",
          ),
        ),
        PopupMenuItem(
          child: Text(
            "Ouvrir un Dossier",
            style: TextStyle(color: ThemeColors.textMain(theme)),
          ),
          onTap: () => fileProvider.pickDirectory(),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          child: Text(
            isDark ? "Thème Clair" : "Thème Sombre",
            style: TextStyle(color: ThemeColors.textMain(theme)),
          ),
          onTap: () => themeProvider.toggleTheme(),
        ),
        if (isMobile) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            child: Text(
              "Exporter",
              style: TextStyle(color: ThemeColors.textMain(theme)),
            ),
            onTap: () =>
                Future.delayed(Duration.zero, () => _showExportMenu(context)),
          ),
          PopupMenuItem(
            child: Text(
              "Aide & Exercices",
              style: TextStyle(color: ThemeColors.textMain(theme)),
            ),
            onTap: () => Future.delayed(
              Duration.zero,
              () => _showEducationalPanel(context, 'guide'),
            ),
          ),
        ],
      ],
    );
  }

  void _showExportMenu(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final fileProvider = context.read<FileProvider>();
    final theme = themeProvider.currentTheme;
    final activeFile = fileProvider.activeFile;

    showMenu<dynamic>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 36, 0, 0),
      color: ThemeColors.sidebarBg(theme),
      items: [
        PopupMenuItem(
          enabled: activeFile != null,
          child: Text(
            "Traduire en Python",
            style: TextStyle(color: ThemeColors.textMain(theme)),
          ),
          onTap: () =>
              _showTranslationDialog(context, activeFile!.content, 'Python'),
        ),
        PopupMenuItem(
          enabled: activeFile != null,
          child: Text(
            "Traduire en C",
            style: TextStyle(color: ThemeColors.textMain(theme)),
          ),
          onTap: () =>
              _showTranslationDialog(context, activeFile!.content, 'C'),
        ),
        PopupMenuItem(
          enabled: activeFile != null,
          child: Text(
            "Traduire en JavaScript",
            style: TextStyle(color: ThemeColors.textMain(theme)),
          ),
          onTap: () =>
              _showTranslationDialog(context, activeFile!.content, 'JS'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          enabled: activeFile != null,
          child: Text(
            "Exporter en PDF",
            style: TextStyle(color: ThemeColors.textMain(theme)),
          ),
          onTap: () => Exportateur.exporterPDF(
            activeFile?.name ?? "Algorithme",
            activeFile?.content ?? "",
          ),
        ),
        PopupMenuItem(
          enabled: activeFile != null,
          child: Text(
            "Exporter en Image (PNG)",
            style: TextStyle(color: ThemeColors.textMain(theme)),
          ),
          onTap: () => Exportateur.exporterImage(
            context,
            activeFile?.content ?? "",
            titre: activeFile?.name ?? "Algorithme",
          ),
        ),
      ],
    );
  }

  void _showTranslationDialog(BuildContext context, String code, String lang) {
    final translated = Traducteur.traduire(code, lang);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Traduction en $lang"),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black12,
                child: Text(
                  translated,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: translated));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Code copié !")));
              },
              child: const Text("Copier"),
            ),
            TextButton(
              onPressed: () {
                Exportateur.exporterPDF("Traduction $lang", translated);
              },
              child: const Text("PDF"),
            ),
            TextButton(
              onPressed: () {
                Exportateur.exporterImage(
                  context,
                  translated,
                  titre: "Code $lang",
                );
              },
              child: const Text("Image"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fermer"),
            ),
          ],
        );
      },
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final AppTheme theme;
  const _HeaderAction({
    required this.icon,
    required this.onPressed,
    required this.theme,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          size: 16,
          color: ThemeColors.textMain(theme).withValues(alpha: 0.6),
        ),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

class _MenuText extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final AppTheme theme;
  const _MenuText(this.text, {this.onTap, this.theme = AppTheme.dark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          style: TextStyle(color: ThemeColors.textMain(theme), fontSize: 12),
        ),
      ),
    );
  }
}
