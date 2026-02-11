import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../theme.dart';

class ProfileModal extends StatelessWidget {
  const ProfileModal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: FutureBuilder<String>(
        future: rootBundle.loadString('assets/profile.json'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = json.decode(snapshot.data!);
          final contacts = data['contact'] as List;

          return Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: ThemeColors.sidebarBg(theme),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with Profile Pic
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blueAccent,
                              Colors.blueAccent.withValues(alpha: 0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -40,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: const AssetImage(
                              'assets/profile.png',
                            ),
                            backgroundColor: Colors.grey[300],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  // Name & Info
                  Text(
                    "${data['prenom']} ${data['nom']}",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.textBright(theme),
                    ),
                  ),
                  Text(
                    data['status'].toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 1.2,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      data['licence'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                  const Divider(height: 40, indent: 40, endIndent: 40),
                  // Contact Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: contacts.map<Widget>((c) {
                        final key = c.keys.first;
                        final value = c.values.first;
                        return _SocialChip(
                          icon: _getIconFor(key),
                          label: key.toString().toUpperCase(),
                          onTap: () => _launchURL(key, value),
                          theme: theme,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Donation Section
                  GestureDetector(
                    onTap: () async {
                      final donCode = data['me faire un don'].toString();
                      // Encode # as %23 for proper tel: URI handling
                      final encodedCode = donCode.replaceAll('#', '%23');
                      final uri = Uri.parse('tel:$encodedCode');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.redAccent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Soutenir le projet",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: ThemeColors.textBright(theme),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['me faire un don'],
                                  style: const TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orangeAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.copy,
                              color: ThemeColors.textMain(
                                theme,
                              ).withValues(alpha: 0.6),
                            ),
                            tooltip: "Copier le code",
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: data['me faire un don']),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Code copié !"),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Fermer"),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconFor(String key) {
    switch (key.toLowerCase()) {
      case 'telephone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'whatshap':
        return Icons.chat;
      case 'linkedin':
        return Icons.link;
      case 'github':
        return Icons.code;
      case 'portfolio':
        return Icons.public;
      default:
        return Icons.link;
    }
  }

  void _launchURL(String key, dynamic value) async {
    String url = "";
    if (key == 'telephone') {
      final list = value as List;
      url = "tel:${list.first.toString().replaceAll(' ', '')}";
    } else if (key == 'email') {
      url = "mailto:$value";
    } else if (key == 'whatshap') {
      url = "https://wa.me/$value";
    } else {
      url = value.toString();
      if (!url.startsWith('http')) {
        url = "https://$url";
      }
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _SocialChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppTheme theme;

  const _SocialChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: ThemeColors.textMain(theme)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: ThemeColors.textMain(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
