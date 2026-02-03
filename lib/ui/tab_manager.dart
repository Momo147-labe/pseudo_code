import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../providers/theme_provider.dart';
import '../theme.dart';

class TabManager extends StatelessWidget {
  const TabManager({super.key});

  @override
  Widget build(BuildContext context) {
    final fileProvider = context.watch<FileProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final theme = themeProvider.currentTheme;
    final algFiles = fileProvider.openFiles
        .where((f) => f.extension == 'alg')
        .toList();

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme),
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.1)),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: algFiles.length,
        itemBuilder: (context, index) {
          final file = algFiles[index];
          // Trouver l'index original dans fileProvider.openFiles
          final originalIndex = fileProvider.openFiles.indexOf(file);
          final isActive = fileProvider.activeTabIndex == originalIndex;

          return _TabItem(
            file: file,
            isActive: isActive,
            theme: theme,
            onTap: () => fileProvider.setActiveTab(originalIndex),
            onClose: () => fileProvider.closeFile(originalIndex),
          );
        },
      ),
    );
  }
}

class _TabItem extends StatefulWidget {
  final AppFile file;
  final bool isActive;
  final AppTheme theme;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabItem({
    required this.file,
    required this.isActive,
    required this.theme,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isActive = widget.isActive;
    final file = widget.file;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 100, maxWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isActive
                ? ThemeColors.editorBg(theme)
                : (_isHovered
                      ? ThemeColors.editorBg(theme).withOpacity(0.5)
                      : ThemeColors.sidebarBg(theme)),
            border: Border(
              right: BorderSide(color: Colors.black.withOpacity(0.1)),
              top: BorderSide(
                color: isActive ? ThemeColors.vscodeBlue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (file.extension == 'alg')
                Image.asset('assets/icone.png', width: 14, height: 14)
              else
                const Icon(
                  Icons.description_outlined,
                  size: 14,
                  color: ThemeColors.vscodeBlue,
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  file.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive
                        ? ThemeColors.textBright(theme)
                        : ThemeColors.textMain(theme).withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (file.isModified && !_isHovered)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: ThemeColors.textMain(theme).withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                )
              else if (_isHovered || isActive)
                GestureDetector(
                  onTap: () {
                    widget.onClose();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _isHovered && !isActive ? Colors.white10 : null,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: _isHovered || isActive
                          ? ThemeColors.textMain(theme).withOpacity(0.8)
                          : Colors.transparent,
                    ),
                  ),
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
