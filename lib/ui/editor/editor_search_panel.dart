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
      top: 40,
      right: isMobile ? 0 : 20,
      left: isMobile ? 0 : null,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: ThemeColors.sidebarBg(theme),
        child: Container(
          width: isMobile ? null : 300,
          margin: isMobile ? const EdgeInsets.symmetric(horizontal: 16) : null,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
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
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                    onPressed: onPrevMatch,
                    color: Colors.white70,
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                    onPressed: onNextMatch,
                    color: Colors.white70,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onClose,
                    color: Colors.white70,
                  ),
                ],
              ),
              const Divider(color: Colors.white12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: replaceController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
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
                    child: Text(
                      AppLocalizations.of(context)!.replaceAll,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: onReplaceCurrent,
                    child: Text(
                      AppLocalizations.of(context)!.replaceCurrent,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
