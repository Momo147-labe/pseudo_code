import 'package:flutter/material.dart';
import '../../theme.dart';
import 'package:pseudo_code/l10n/app_localizations.dart';

class EditorSearchPanel extends StatelessWidget {
  final TextEditingController searchController;
  final TextEditingController replaceController;
  final List<int> searchMatches;
  final int currentMatchIndex;
  final bool isMobile;
  final AppTheme theme;
  final VoidCallback onSearchChanged;
  final VoidCallback onNextMatch;
  final VoidCallback onPrevMatch;
  final VoidCallback onReplaceCurrent;
  final VoidCallback onReplaceAll;
  final VoidCallback onClose;

  const EditorSearchPanel({
    super.key,
    required this.searchController,
    required this.replaceController,
    required this.searchMatches,
    required this.currentMatchIndex,
    required this.isMobile,
    required this.theme,
    required this.onSearchChanged,
    required this.onNextMatch,
    required this.onPrevMatch,
    required this.onReplaceCurrent,
    required this.onReplaceAll,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: isMobile ? 36 : 40,
      right: isMobile ? 0 : 20,
      left: isMobile ? 0 : null,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: ThemeColors.sidebarBg(theme),
        child: Container(
          width: isMobile ? null : 300,
          margin: isMobile ? const EdgeInsets.symmetric(horizontal: 8) : null,
          padding: EdgeInsets.all(isMobile ? 8 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.search,
                    size: isMobile ? 14 : 16,
                    color: Colors.white38,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 12 : 13,
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchHint,
                        hintStyle: const TextStyle(color: Colors.white38),
                        isDense: true,
                        border: InputBorder.none,
                      ),
                      onChanged: (val) => onSearchChanged(),
                    ),
                  ),
                  Text(
                    searchMatches.isEmpty
                        ? '0/0'
                        : '${currentMatchIndex + 1}/${searchMatches.length}',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: isMobile ? 10 : 11,
                    ),
                  ),
                  _CompactIconButton(
                    icon: Icons.keyboard_arrow_up,
                    onPressed: onPrevMatch,
                    isMobile: isMobile,
                  ),
                  _CompactIconButton(
                    icon: Icons.keyboard_arrow_down,
                    onPressed: onNextMatch,
                    isMobile: isMobile,
                  ),
                  _CompactIconButton(
                    icon: Icons.close,
                    onPressed: onClose,
                    isMobile: isMobile,
                  ),
                ],
              ),
              if (!isMobile ||
                  replaceController.text.isNotEmpty ||
                  searchMatches.isNotEmpty) ...[
                const Divider(color: Colors.white12, height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: replaceController,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 12 : 13,
                        ),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.replaceHint,
                          hintStyle: const TextStyle(color: Colors.white38),
                          isDense: true,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onReplaceAll,
                      style: TextButton.styleFrom(
                        padding: isMobile
                            ? const EdgeInsets.symmetric(horizontal: 4)
                            : null,
                        minimumSize: isMobile ? Size.zero : null,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.replaceAll,
                        style: TextStyle(fontSize: isMobile ? 11 : 12),
                      ),
                    ),
                    TextButton(
                      onPressed: onReplaceCurrent,
                      style: TextButton.styleFrom(
                        padding: isMobile
                            ? const EdgeInsets.symmetric(horizontal: 4)
                            : null,
                        minimumSize: isMobile ? Size.zero : null,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.replaceCurrent,
                        style: TextStyle(fontSize: isMobile ? 11 : 12),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isMobile;

  const _CompactIconButton({
    required this.icon,
    required this.onPressed,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isMobile ? 30 : 40,
      height: isMobile ? 30 : 40,
      child: IconButton(
        icon: Icon(icon, size: isMobile ? 16 : 18),
        onPressed: onPressed,
        color: Colors.white70,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}
