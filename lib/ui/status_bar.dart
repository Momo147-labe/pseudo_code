import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/file_provider.dart';
import '../theme.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final fileProvider = context.watch<FileProvider>();
    final theme = context.watch<ThemeProvider>().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (provider.activeMainView == ActiveMainView.merise) {
      return const SizedBox.shrink();
    }

    return Container(
      height: isMobile ? 55 : 22,
      color: ThemeColors.topbarBg(theme),
      child: Column(
        children: [
          if (isMobile)
            Expanded(child: _buildOperatorBar(context, fileProvider, theme)),
          Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _StatusItem(
                  icon: Icons.terminal_outlined,
                  label: 'Console',
                  theme: theme,
                  onTap: () => provider.toggleConsole(),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 16),
                  Text(
                    'Police: ',
                    style: TextStyle(
                      color: ThemeColors.textMain(theme),
                      fontSize: 11,
                    ),
                  ),
                  _FontSizeControl(
                    label: '-',
                    theme: theme,
                    onPressed: () =>
                        provider.setFontSize(provider.fontSize - 1),
                  ),
                  Text(
                    '${provider.fontSize.toInt()}',
                    style: TextStyle(
                      color: ThemeColors.textMain(theme),
                      fontSize: 11,
                    ),
                  ),
                  _FontSizeControl(
                    label: '+',
                    theme: theme,
                    onPressed: () =>
                        provider.setFontSize(provider.fontSize + 1),
                  ),
                ],
                const Spacer(),
                if (!isMobile)
                  Text(
                    'Fode Momo soumah',
                    style: TextStyle(
                      color: ThemeColors.textMain(theme),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorBar(
    BuildContext context,
    FileProvider fileProvider,
    AppTheme theme,
  ) {
    final operators = [
      // Arithmétique
      '<-', '+', '-', '*', '/', '%',
      '|', // Séparateur visuel simple
      // Comparaison
      '=', '<>', '<', '>', '<=', '>=',
      '|',
      // Logique
      'ET', 'OU', 'NON',
      '|',
      // Signes
      '(', ')', '[', ']', '{', '}', ',', ':', ';', '"', '..',
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: operators.map((op) {
            if (op == '|') {
              return Container(
                width: 1,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.white.withValues(alpha: 0.1),
              );
            }
            return _OperatorButton(
              label: op,
              onTap: () => fileProvider.insertText(op),
              theme: theme,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _OperatorButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final AppTheme theme;

  const _OperatorButton({
    required this.label,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(36, 30),
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: ThemeColors.textBright(theme),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'JetBrainsMono',
          ),
        ),
      ),
    );
  }
}

class _FontSizeControl extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final AppTheme theme;

  const _FontSizeControl({
    required this.label,
    required this.onPressed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          label,
          style: TextStyle(
            color: ThemeColors.textMain(theme),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppTheme theme;
  final VoidCallback? onTap;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.theme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        Icon(icon, color: ThemeColors.textMain(theme), size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: ThemeColors.textMain(theme), fontSize: 11),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: content,
        ),
      );
    }
    return content;
  }
}
