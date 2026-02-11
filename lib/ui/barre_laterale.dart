import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/file_provider.dart';
import '../theme.dart';
import 'package:path/path.dart' as p;
import 'variable_view.dart';
import 'merise/widgets/sidebar.dart';
import 'educational_panel.dart';
import 'profile_modal.dart';
import 'documentation_modal.dart';
import 'ai_assistant_view.dart';
import '../providers/graph_provider.dart';

class BarreLaterale extends StatefulWidget {
  const BarreLaterale({super.key});

  @override
  State<BarreLaterale> createState() => _BarreLateraleState();
}

class _BarreLateraleState extends State<BarreLaterale> {
  // VSCode-like collapsible sections
  bool _openFilesExpanded = true;
  bool _workspaceExpanded = true;

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final fileProvider = context.watch<FileProvider>();
    final theme = themeProvider.currentTheme;

    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme),
        border: const Border(right: BorderSide(color: Colors.black26)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header only for default/debug, or maybe MeriseSidebar has its own header?
            // MeriseSidebar HAS its own header.
            if (appProvider.activeSidebarTab != 'merise')
              _SidebarHeader(
                appProvider: appProvider,
                fileProvider: fileProvider,
                themeProvider: themeProvider,
              ),
            // Navigation Bar for mobile (integrated in Drawer)
            if (MediaQuery.of(context).size.width < 768)
              Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: ThemeColors.editorBg(theme).withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavIcon(
                        icon: Icons.copy,
                        isActive: appProvider.activeSidebarTab == 'explorer',
                        onTap: () =>
                            appProvider.setActiveSidebarTab('explorer'),
                        theme: theme,
                      ),
                      _NavIcon(
                        icon: Icons.schema_outlined,
                        isActive: appProvider.activeSidebarTab == 'merise',
                        onTap: () => appProvider.setActiveSidebarTab('merise'),
                        theme: theme,
                      ),
                      _NavIcon(
                        icon: Icons.auto_graph_outlined,
                        isActive: appProvider.activeSidebarTab == 'graph',
                        onTap: () => appProvider.setActiveSidebarTab('graph'),
                        theme: theme,
                      ),
                      _NavIcon(
                        icon: Icons.bug_report_outlined,
                        isActive: appProvider.activeSidebarTab == 'debug',
                        onTap: () => appProvider.setActiveSidebarTab('debug'),
                        theme: theme,
                      ),
                      _NavIcon(
                        icon: Icons.auto_awesome,
                        isActive: appProvider.activeSidebarTab == 'ai',
                        onTap: () => appProvider.setActiveSidebarTab('ai'),
                        theme: theme,
                      ),

                      _NavIcon(
                        icon: Icons.emoji_events_outlined,
                        isActive: appProvider.activeSidebarTab == 'challenges',
                        onTap: () =>
                            appProvider.setActiveSidebarTab('challenges'),
                        theme: theme,
                      ),
                      _NavIcon(
                        icon: Icons.terminal_outlined,
                        isActive: appProvider.isConsoleVisible,
                        onTap: () => appProvider.toggleConsole(),
                        theme: theme,
                      ),
                      _NavIcon(
                        icon: Icons.folder_open,
                        isActive: false,
                        onTap: () => fileProvider.pickDirectory(),
                        theme: theme,
                      ),
                      _NavIcon(
                        icon: theme == AppTheme.dark
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        isActive: false,
                        onTap: () => themeProvider.toggleTheme(),
                        theme: theme,
                      ),
                      _NavIcon(
                        icon: Icons.account_circle_outlined,
                        isActive: false,
                        onTap: () => showDialog(
                          context: context,
                          builder: (context) => const ProfileModal(),
                        ),
                        theme: theme,
                      ),
                      _NavIcon(
                        icon: Icons.help_outline,
                        isActive: false,
                        onTap: () => showDialog(
                          context: context,
                          builder: (context) => const DocumentationModal(),
                        ),
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: _buildBody(
                context,
                appProvider,
                fileProvider,
                themeProvider,
              ),
            ),
            if (MediaQuery.of(context).size.width < 768 &&
                appProvider.activeSidebarTab != 'ai') ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "RESSOURCES",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.textMain(
                          theme,
                        ).withValues(alpha: 0.5),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ResourceItem(
                      icon: Icons.assignment,
                      label: "Exercices",
                      onTap: () => _showEducationalPanel(context, 'exercice'),
                      theme: theme,
                    ),
                    _ResourceItem(
                      icon: Icons.import_contacts,
                      label: "Guide Pseudo-Code",
                      onTap: () => _showEducationalPanel(context, 'guide'),
                      theme: theme,
                    ),
                    _ResourceItem(
                      icon: Icons.lightbulb_outline,
                      label: "Exemples",
                      onTap: () => _showEducationalPanel(context, 'exemple'),
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEducationalPanel(BuildContext context, String tab) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'EducationalPanel',
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: EducationalPanel(initialTab: tab),
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

  Widget _buildBody(
    BuildContext context,
    AppProvider appProvider,
    FileProvider fileProvider,
    ThemeProvider themeProvider,
  ) {
    switch (appProvider.activeSidebarTab) {
      case 'ai':
        return const AiAssistantView();
      case 'debug':
        return const VariableView();

      case 'merise':
        return Column(
          children: [
            Expanded(
              flex: 4,
              child: _buildExplorer(
                context,
                appProvider,
                fileProvider,
                themeProvider,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              flex: 6,
              child: MeriseSidebar(
                theme: themeProvider.currentTheme,
                isMobile: MediaQuery.of(context).size.width < 768,
              ),
            ),
          ],
        );
      case 'graph':
      default:
        return _buildExplorer(
          context,
          appProvider,
          fileProvider,
          themeProvider,
        );
    }
  }

  // Helper to intercept file taps
  void _onFileTap(
    FileProvider fileProvider,
    AppProvider appProvider,
    String path,
  ) {
    fileProvider.selectFileInExplorer(path);
    fileProvider.openFile(path);
    final ext = path.split('.').last.toLowerCase();
    if (ext == 'csi') {
      appProvider.setActiveSidebarTab('merise');
    } else if (ext == 'alg') {
      appProvider.setActiveSidebarTab('explorer');
    } else if (ext == 'grp') {
      try {
        final content = File(path).readAsStringSync();
        context.read<GraphProvider>().loadFromContent(content, path);
      } catch (e) {
        debugPrint("Erreur de lecture du fichier graphe: $e");
      }
      appProvider.setActiveSidebarTab('graph');
    }
  }

  Widget _buildOpenFilesSection(
    BuildContext context,
    AppProvider appProvider,
    FileProvider fileProvider,
    ThemeProvider themeProvider,
  ) {
    final theme = themeProvider.currentTheme;
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _openFilesExpanded = !_openFilesExpanded),
          child: Row(
            children: [
              Icon(
                _openFilesExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right,
                size: 16,
                color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
              ),
              Expanded(
                child: _buildSectionHeader("FICHIERS OUVERTS", padding: 16),
              ),
            ],
          ),
        ),
        if (_openFilesExpanded) ...[
          ...fileProvider.openFiles.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            final isActive = index == fileProvider.activeTabIndex;
            return _FileItem(
              name: file.name,
              path: file.path,
              isActive: isActive,
              indent: 0,
              theme: themeProvider.currentTheme,
              isModified: file.isModified,
              onTap: () => _onFileTap(fileProvider, appProvider, file.path),
              onClose: () => fileProvider.closeFile(index),
            );
          }),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 16,
            endIndent: 16,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildExplorer(
    BuildContext context,
    AppProvider appProvider,
    FileProvider fileProvider,
    ThemeProvider themeProvider,
  ) {
    final theme = themeProvider.currentTheme;
    return ListView(
      children: [
        if (fileProvider.openFiles.isNotEmpty)
          _buildOpenFilesSection(
            context,
            appProvider,
            fileProvider,
            themeProvider,
          ),
        // VSCode-like workspace folder header (collapsible)
        InkWell(
          onTap: () => setState(() => _workspaceExpanded = !_workspaceExpanded),
          child: Row(
            children: [
              Icon(
                _workspaceExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right,
                size: 16,
                color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
              ),
              Expanded(
                child: _buildSectionHeader(
                  "DOSSIERS: ${p.basename(fileProvider.currentDirectory)}",
                  padding: 16,
                ),
              ),
            ],
          ),
        ),
        if (_workspaceExpanded)
          _buildDirectory(
            context,
            appProvider,
            fileProvider.currentDirectory,
            fileProvider,
            themeProvider,
            0,
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {double padding = 0}) {
    return Padding(
      padding: EdgeInsets.only(left: padding, top: 8, bottom: 4, right: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildDirectory(
    BuildContext context,
    AppProvider appProvider,
    String path,
    FileProvider fileProvider,
    ThemeProvider themeProvider,
    int indent,
  ) {
    final name = p.basename(path);
    final isRoot = path == fileProvider.currentDirectory;
    // Root expansion is controlled locally (VSCode-like workspace collapse).
    // Non-root directories use fileProvider.expandedFolders.
    final isExpanded = isRoot
        ? _workspaceExpanded
        : fileProvider.expandedFolders.contains(path);
    final theme = themeProvider.currentTheme;

    return Column(
      children: [
        if (!isRoot)
          _FolderItem(
            name: name,
            path: path,
            isExpanded: isExpanded,
            indent: indent,
            theme: theme,
            onTap: () => fileProvider.toggleFolder(path),
          ),
        if (isExpanded)
          StreamBuilder<List<FileSystemEntity>>(
            stream: Directory(path).list().toList().asStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final entities = snapshot.data!.where((entity) {
                if (entity is Directory) return true;
                if (entity is File) {
                  final ext = p.extension(entity.path).toLowerCase();
                  return ext == '.alg' || ext == '.csi' || ext == '.grp';
                }
                return false;
              }).toList();

              entities.sort((a, b) {
                if (a is Directory && b is File) return -1;
                if (a is File && b is Directory) return 1;
                return a.path.compareTo(b.path);
              });

              return Column(
                children: entities.map<Widget>((entity) {
                  if (entity is Directory) {
                    return _buildDirectory(
                      context,
                      appProvider,
                      entity.path,
                      fileProvider,
                      themeProvider,
                      indent + 1,
                    );
                  } else {
                    return _FileItem(
                      name: p.basename(entity.path),
                      path: entity.path,
                      isActive:
                          fileProvider.selectedFileInExplorer == entity.path,
                      indent: indent + 1,
                      theme: theme,
                      onTap: () =>
                          _onFileTap(fileProvider, appProvider, entity.path),
                    );
                  }
                }).toList(),
              );
            },
          ),
      ],
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  final AppProvider appProvider;
  final FileProvider fileProvider;
  final ThemeProvider themeProvider;

  const _SidebarHeader({
    required this.appProvider,
    required this.fileProvider,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = themeProvider.currentTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _getHeaderTitle(appProvider, fileProvider).toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ThemeColors.textMain(theme).withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: [
              _HeaderAction(
                icon: Icons.note_add_outlined,
                onPressed: () => _showNameDialog(context, "Nouveau Fichier", (
                  name,
                ) {
                  fileProvider.createFile(fileProvider.currentDirectory, name);
                }),
              ),
              _HeaderAction(
                icon: Icons.create_new_folder_outlined,
                onPressed: () =>
                    _showNameDialog(context, "Nouveau Dossier", (name) {
                      fileProvider.createDirectory(
                        fileProvider.currentDirectory,
                        name,
                      );
                    }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getHeaderTitle(AppProvider appProvider, FileProvider fileProvider) {
    switch (appProvider.activeSidebarTab) {
      case 'debug':
        return "Débogage";
      case 'merise':
        return "Modélisation Merise";
      default:
        return "Explorateur: ${p.basename(fileProvider.currentDirectory)}";
    }
  }

  void _showNameDialog(
    BuildContext context,
    String title,
    Function(String) onConfirm,
  ) {
    final theme = themeProvider.currentTheme;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.sidebarBg(theme),
        title: Text(
          title,
          style: TextStyle(color: ThemeColors.textBright(theme), fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: ThemeColors.textBright(theme)),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: ThemeColors.textMain(theme).withValues(alpha: 0.2),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onConfirm(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Créer"),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _HeaderAction({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
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
      ),
    );
  }
}

class _FolderItem extends StatelessWidget {
  final String name;
  final String path;
  final bool isExpanded;
  final int indent;
  final AppTheme theme;
  final VoidCallback onTap;

  const _FolderItem({
    required this.name,
    required this.path,
    required this.isExpanded,
    required this.indent,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fileProvider = context.read<FileProvider>();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(left: 16.0 + (indent * 12), top: 4, bottom: 4),
        child: Row(
          children: [
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_right,
              size: 16,
              color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
            ),
            const Icon(Icons.folder, size: 16, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ThemeColors.textMain(theme).withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 14,
                color: ThemeColors.textMain(theme).withValues(alpha: 0.4),
              ),
              padding: EdgeInsets.zero,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'rename', child: Text('Renommer')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                ),
              ],
              onSelected: (value) {
                if (value == 'rename') {
                  _showRenameDialog(context, name, (newName) {
                    fileProvider.renameDirectory(path, newName);
                  }, theme);
                } else if (value == 'delete') {
                  _showDeleteConfirmDialog(context, name, () {
                    fileProvider.deleteDirectory(path);
                  }, theme);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FileItem extends StatelessWidget {
  final String name;
  final String path;
  final bool isActive;
  final int indent;
  final AppTheme theme;
  final bool isModified;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  const _FileItem({
    required this.name,
    required this.path,
    required this.isActive,
    required this.indent,
    required this.theme,
    this.isModified = false,
    required this.onTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final extension = name.split('.').last.toLowerCase();
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    final fileProvider = context.read<FileProvider>();

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isActive
            ? (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05))
            : null,
        padding: EdgeInsets.only(
          left: 32.0 + (indent * 12),
          top: 4,
          bottom: 4,
          right: 8,
        ),
        child: Row(
          children: [
            if (extension == 'alg')
              Image.asset('assets/icone.png', width: 16, height: 16)
            else if (extension == 'csi')
              Image.asset('assets/csiIcon.png', width: 16, height: 16)
            else if (extension == 'grp')
              Image.asset('assets/grp.png', width: 16, height: 16)
            else
              Icon(
                Icons.description_outlined,
                size: 16,
                color: ThemeColors.textMain(theme).withValues(alpha: 0.7),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name + (isModified ? ' ●' : ''),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive
                      ? ThemeColors.textBright(theme)
                      : ThemeColors.textMain(theme).withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontStyle: isModified ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
            if (onClose != null)
              IconButton(
                icon: const Icon(Icons.close, size: 14),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onClose,
                color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
              )
            else
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz,
                  size: 14,
                  color: ThemeColors.textMain(theme).withValues(alpha: 0.4),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'rename', child: Text('Renommer')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Supprimer',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'rename') {
                    _showRenameDialog(context, name, (newName) {
                      fileProvider.renameFile(path, newName);
                    }, theme);
                  } else if (value == 'delete') {
                    _showDeleteConfirmDialog(context, name, () {
                      fileProvider.deleteFile(path);
                    }, theme);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final AppTheme theme;

  const _NavIcon({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        color: isActive
            ? Colors.blueAccent
            : ThemeColors.textMain(theme).withValues(alpha: 0.4),
        size: 20,
      ),
      onPressed: onTap,
    );
  }
}

class _ResourceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppTheme theme;

  const _ResourceItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: ThemeColors.textMain(theme).withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: ThemeColors.textMain(theme),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showRenameDialog(
  BuildContext context,
  String currentName,
  Function(String) onConfirm,
  AppTheme theme,
) {
  final controller = TextEditingController(text: currentName);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: ThemeColors.sidebarBg(theme),
      title: Text(
        "Renommer",
        style: TextStyle(color: ThemeColors.textBright(theme), fontSize: 16),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: TextStyle(color: ThemeColors.textBright(theme)),
        decoration: InputDecoration(
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: ThemeColors.textMain(theme).withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler"),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.isNotEmpty && controller.text != currentName) {
              onConfirm(controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text("Renommer"),
        ),
      ],
    ),
  );
}

void _showDeleteConfirmDialog(
  BuildContext context,
  String name,
  VoidCallback onConfirm,
  AppTheme theme,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: ThemeColors.sidebarBg(theme),
      title: Text(
        "Supprimer ?",
        style: TextStyle(color: ThemeColors.textBright(theme), fontSize: 16),
      ),
      content: Text(
        "Êtes-vous sûr de vouloir supprimer '$name' ?",
        style: TextStyle(color: ThemeColors.textMain(theme)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler"),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
