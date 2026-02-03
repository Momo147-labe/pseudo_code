import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../merise/mld_transformer.dart';
import '../../../merise/query_generator.dart';
import '../../../providers/merise_provider.dart';
import '../../../theme.dart';

class QueryView extends StatelessWidget {
  final AppTheme theme;
  final bool isMobile;

  const QueryView({super.key, required this.theme, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeriseProvider>();
    final mcd = provider.mcd;
    final scale = provider.textScaleFactor;

    final mld = MldTransformer.transform(mcd);
    final queries = QueryGenerator.generateCommonQueries(
      mld,
      dialect: provider.sqlDialect,
    );

    return Container(
      color: ThemeColors.editorBg(theme),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Requêtes & Jointures",
            style: TextStyle(
              fontSize: 24 * scale,
              fontWeight: FontWeight.bold,
              color: ThemeColors.textMain(theme),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Requêtes SQL générées automatiquement à partir de votre modèle.",
            style: TextStyle(
              fontSize: 14 * scale,
              color: ThemeColors.textMain(theme).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: queries.isEmpty
                ? _buildEmptyState(scale, theme)
                : ListView.builder(
                    itemCount: queries.length,
                    itemBuilder: (context, index) {
                      return _QueryCard(
                        query: queries[index],
                        theme: theme,
                        scale: scale,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double scale, AppTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.query_stats,
            size: 64 * scale,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "Aucune requête disponible",
            style: TextStyle(fontSize: 18 * scale, color: Colors.grey),
          ),
          Text(
            "Ajoutez des entités et des relations pour générer des requêtes.",
            style: TextStyle(
              fontSize: 14 * scale,
              color: Colors.grey.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueryCard extends StatelessWidget {
  final MeriseQuery query;
  final AppTheme theme;
  final double scale;

  const _QueryCard({
    required this.query,
    required this.theme,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              query.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16 * scale,
                color: ThemeColors.textMain(theme),
              ),
            ),
            subtitle: Text(
              query.description,
              style: TextStyle(
                fontSize: 13 * scale,
                color: ThemeColors.textMain(theme).withOpacity(0.6),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: query.sql));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Requête SQL copiée")),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText.rich(
              _buildHighlightedSql(query.sql, isDark),
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 13 * scale,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _buildHighlightedSql(String sql, bool isDark) {
    final keywords = {
      'SELECT',
      'FROM',
      'WHERE',
      'JOIN',
      'ON',
      'AND',
      'OR',
      'IN',
      'IS',
      'NOT',
      'NULL',
      'ORDER',
      'BY',
      'GROUP',
      'HAVING',
      'LIMIT',
      'OFFSET',
      'AS',
      'INNER',
      'LEFT',
      'RIGHT',
      'OUTER',
      'CROSS',
      'NATURAL',
      'UNION',
      'ALL',
      'DISTINCT',
      'COUNT',
      'SUM',
      'AVG',
      'MIN',
      'MAX',
    };

    final List<TextSpan> spans = [];

    // RegExp similaire à SqlView pour la cohérence
    final regExp = RegExp(
      r'(`[^`]*`|"([^"]|"")*"|' + // Identifiants quotés
          r"'(?:''|[^'])*'|" + // Littéraux chaînes
          r'[a-zA-Z_]\w*(?:\.\w+)?|' + // Mots, mots-clés et schema.table
          r'\d+|' + // Nombres
          r'\s+|' + // Espaces
          r'[(),.;=<>!]+)', // Ponctuation et opérateurs
    );

    final matches = regExp.allMatches(sql);
    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: sql.substring(lastMatchEnd, match.start),
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
        );
      }

      final text = match.group(0)!;
      final upperText = text.toUpperCase();

      Color color = isDark ? Colors.white : Colors.black;
      FontWeight weight = FontWeight.normal;

      if (text.startsWith('`') || text.startsWith('"')) {
        color = const Color(0xFFC678DD);
      } else if (text.startsWith("'")) {
        color = const Color(0xFF98C379);
      } else if (keywords.contains(upperText)) {
        color = const Color(0xFF61AFEF);
        weight = FontWeight.bold;
      } else if (RegExp(r'^\d+$').hasMatch(text)) {
        color = const Color(0xFFD19A66);
      } else if (RegExp(r'^[(),.;=<>!]+$').hasMatch(text)) {
        color = Colors.grey;
      }

      spans.add(
        TextSpan(
          text: text,
          style: TextStyle(color: color, fontWeight: weight),
        ),
      );
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < sql.length) {
      spans.add(
        TextSpan(
          text: sql.substring(lastMatchEnd),
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
      );
    }

    return TextSpan(children: spans);
  }
}
