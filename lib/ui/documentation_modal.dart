import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../theme.dart';

class DocumentationModal extends StatelessWidget {
  const DocumentationModal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        decoration: BoxDecoration(
          color: ThemeColors.sidebarBg(theme),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ThemeColors.editorBg(theme),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book, color: Colors.blueAccent),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Documentation Complète de la Plateforme",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.textBright(theme),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: ThemeColors.textMain(theme)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: FutureBuilder<String>(
                future: rootBundle.loadString('assets/README.md'),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Markdown(
                    data: snapshot.data!,
                    styleSheet: MarkdownStyleSheet(
                      h1: TextStyle(
                        color: ThemeColors.textBright(theme),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      h2: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      h3: TextStyle(
                        color: ThemeColors.textBright(theme),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      p: TextStyle(
                        color: ThemeColors.textMain(theme),
                        fontSize: 15,
                        height: 1.5,
                      ),
                      listBullet: TextStyle(color: Colors.blueAccent),
                      code: TextStyle(
                        backgroundColor: isDark
                            ? Colors.black26
                            : Colors.grey[200],
                        fontFamily: 'JetBrainsMono',
                        color: isDark ? Colors.orangeAccent : Colors.deepOrange,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: isDark ? Colors.black38 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onTapLink: (text, href, title) {
                      if (href != null) {
                        launchUrl(Uri.parse(href));
                      }
                    },
                  );
                },
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "© 2026 - Plateforme d'Apprentissage Pseudo-Code",
                style: TextStyle(
                  fontSize: 12,
                  color: ThemeColors.textMain(theme).withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
