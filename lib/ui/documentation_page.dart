import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../theme.dart';

class DocumentationPage extends StatefulWidget {
  const DocumentationPage({super.key});

  @override
  State<DocumentationPage> createState() => _DocumentationPageState();
}

class _DocumentationPageState extends State<DocumentationPage> {
  String _selectedDoc = 'README';
  final Map<String, String> _docFiles = {
    'README': 'docs/README.md',
    'Installation': 'docs/installation.md',
    'Algorithmes': 'docs/guide-utilisateur/algo.md',
    'Merise': 'docs/guide-utilisateur/merise.md',
    'Graphes': 'docs/guide-utilisateur/graphe.md',
    'Guide Général': 'docs/guide-utilisateur/general.md',
    'FAQ': 'docs/faq.md',
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 800;

    return Scaffold(
      backgroundColor: ThemeColors.editorBg(theme),
      appBar: AppBar(
        backgroundColor: ThemeColors.sidebarBg(theme),
        elevation: 0,
        leading: isMobile
            ? Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu, color: ThemeColors.textBright(theme)),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: ThemeColors.textBright(theme),
                ),
                onPressed: () => Navigator.pop(context),
              ),
        title: Row(
          children: [
            const Icon(Icons.menu_book, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Text(
              'Documentation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ThemeColors.textBright(theme),
              ),
            ),
          ],
        ),
        actions: [
          if (isMobile)
            IconButton(
              icon: Icon(Icons.close, color: ThemeColors.textBright(theme)),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
      drawer: isMobile
          ? Drawer(
              backgroundColor: ThemeColors.sidebarBg(theme),
              child: _buildSidebar(theme),
            )
          : null,
      body: Row(
        children: [
          // Sidebar menu (only on desktop)
          if (!isMobile) _buildSidebar(theme),
          // Content area
          Expanded(child: _buildMarkdownContent(context, theme, isDark)),
        ],
      ),
    );
  }

  Widget _buildSidebar(AppTheme theme) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme),
        border: Border(
          right: BorderSide(color: ThemeColors.editorBg(theme), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'SECTIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: ThemeColors.textMain(theme).withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: _docFiles.keys.map((docName) {
                final isSelected = _selectedDoc == docName;
                return _buildMenuItem(
                  docName,
                  isSelected,
                  _getIconForDoc(docName),
                  theme,
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(
                  color: ThemeColors.textMain(theme).withValues(alpha: 0.2),
                ),
                const SizedBox(height: 8),
                Text(
                  '© 2026 - Pseudo Code',
                  style: TextStyle(
                    fontSize: 11,
                    color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(
    BuildContext context,
    AppTheme theme,
    bool isDark,
  ) {
    return FutureBuilder<String>(
      key: ValueKey(_selectedDoc),
      future: rootBundle.loadString(_docFiles[_selectedDoc]!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontSize: 18,
                    color: ThemeColors.textMain(theme),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: ThemeColors.textMain(theme).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }

        final isMobile = MediaQuery.of(context).size.width < 800;

        return Container(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Markdown(
            data: snapshot.data ?? '',
            styleSheet: MarkdownStyleSheet(
              h1: TextStyle(
                color: ThemeColors.textBright(theme),
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
              h2: TextStyle(
                color: Colors.blueAccent,
                fontSize: isMobile ? 20 : 26,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
              h3: TextStyle(
                color: ThemeColors.textBright(theme),
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
              h4: TextStyle(
                color: ThemeColors.textBright(theme),
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              p: TextStyle(
                color: ThemeColors.textMain(theme),
                fontSize: isMobile ? 14 : 16,
                height: 1.6,
              ),
              listBullet: const TextStyle(color: Colors.blueAccent),
              a: const TextStyle(
                color: Colors.blueAccent,
                decoration: TextDecoration.underline,
              ),
              code: TextStyle(
                backgroundColor: isDark ? Colors.black26 : Colors.grey[200],
                fontFamily: 'JetBrainsMono',
                color: isDark ? Colors.orangeAccent : Colors.deepOrange,
                fontSize: isMobile ? 12 : 14,
              ),
              codeblockDecoration: BoxDecoration(
                color: isDark ? Colors.black38 : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey[300]!,
                ),
              ),
              blockquote: TextStyle(
                color: ThemeColors.textMain(theme).withValues(alpha: 0.8),
                fontSize: isMobile ? 14 : 15,
              ),
              blockquoteDecoration: BoxDecoration(
                color: isDark
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.05),
                border: const Border(
                  left: BorderSide(color: Colors.blueAccent, width: 4),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              tableBorder: TableBorder.all(
                color: ThemeColors.textMain(theme).withValues(alpha: 0.2),
              ),
              tableHead: TextStyle(
                fontWeight: FontWeight.bold,
                color: ThemeColors.textBright(theme),
                fontSize: isMobile ? 12 : 14,
              ),
              tableBody: TextStyle(
                color: ThemeColors.textMain(theme),
                fontSize: isMobile ? 11 : 14,
              ),
            ),
            onTapLink: (text, href, title) {
              if (href != null) {
                if (href.startsWith('./') || href.startsWith('../')) {
                  final docName = _getDocNameFromPath(href);
                  if (docName != null && _docFiles.containsKey(docName)) {
                    setState(() {
                      _selectedDoc = docName;
                    });
                    if (isMobile) {
                      Navigator.pop(context); // Close drawer
                    }
                    return;
                  }
                }
                launchUrl(Uri.parse(href));
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
    String title,
    bool isSelected,
    IconData icon,
    AppTheme theme,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDoc = title;
        });
        if (MediaQuery.of(context).size.width < 800) {
          Navigator.pop(context); // Close drawer
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? ThemeColors.editorBg(theme).withValues(alpha: 0.5)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? Colors.blueAccent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.blueAccent
                  : ThemeColors.textMain(theme).withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? ThemeColors.textBright(theme)
                      : ThemeColors.textMain(theme),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForDoc(String docName) {
    switch (docName) {
      case 'README':
        return Icons.home;
      case 'Installation':
        return Icons.download;
      case 'Algorithmes':
        return Icons.code;
      case 'Merise':
        return Icons.schema;
      case 'Graphes':
        return Icons.account_tree;
      case 'Guide Général':
        return Icons.book;
      case 'FAQ':
        return Icons.help_outline;
      default:
        return Icons.description;
    }
  }

  String? _getDocNameFromPath(String path) {
    // Map relative paths to doc names
    final pathMapping = {
      './installation.md': 'Installation',
      './guide-utilisateur/algo.md': 'Algorithmes',
      './guide-utilisateur/merise.md': 'Merise',
      './guide-utilisateur/graphe.md': 'Graphes',
      './guide-utilisateur/general.md': 'Guide Général',
      './faq.md': 'FAQ',
      '../README.md': 'README',
      '../installation.md': 'Installation',
      '../faq.md': 'FAQ',
      './README.md': 'README',
    };
    return pathMapping[path];
  }
}
