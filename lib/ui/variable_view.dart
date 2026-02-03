import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/debug_provider.dart';
import '../theme.dart';
import '../interpreteur/blocs/tableaux.dart';

class VariableView extends StatelessWidget {
  const VariableView({super.key});

  @override
  Widget build(BuildContext context) {
    final debugProvider = context.watch<DebugProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final variables = debugProvider.debugVariables;
    final theme = themeProvider.currentTheme;

    if (variables.isEmpty) {
      return Center(
        child: Text(
          "Lancez l'algorithme pour voir les variables",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ThemeColors.textMain(theme).withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            "VARIABLES",
            style: TextStyle(
              color: ThemeColors.textMain(theme).withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Toolbar de débogage
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          color: Colors.black12,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.play_arrow_outlined,
                  color: Colors.green,
                  size: 20,
                ),
                tooltip: "Continuer",
                onPressed: debugProvider.isPaused
                    ? () {
                        debugProvider.setPaused(false);
                        debugProvider.triggerNextStep();
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(
                  Icons.redo_outlined,
                  color: Colors.blue,
                  size: 20,
                ),
                tooltip: "Pas suivant",
                onPressed: debugProvider.isPaused
                    ? () {
                        debugProvider.triggerNextStep();
                      }
                    : null,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: variables.length,
            itemBuilder: (context, index) {
              final key = variables.keys.elementAt(index);
              final val = variables[key];
              return _VariableItem(name: key, value: val, theme: theme);
            },
          ),
        ),
      ],
    );
  }
}

class _VariableItem extends StatelessWidget {
  final String name;
  final dynamic value;
  final AppTheme theme;

  const _VariableItem({
    required this.name,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    String valueStr = value.toString();
    if (value is PseudoTableau) {
      valueStr = "Tableau ${value.mins.length}D";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$name : ",
            style: TextStyle(
              color: Colors.blueAccent.shade100,
              fontFamily: 'JetBrainsMono',
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              valueStr,
              style: TextStyle(
                color: ThemeColors.textMain(theme).withOpacity(0.9),
                fontFamily: 'JetBrainsMono',
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
