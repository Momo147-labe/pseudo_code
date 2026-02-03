import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../merise/mld_transformer.dart';
import '../../../merise/mpd_generator.dart';
import '../../../providers/merise_provider.dart';
import '../../../theme.dart';

class SqlView extends StatefulWidget {
  final AppTheme theme;
  final bool isMld; // true for MLD table view, false for MPD SQL view
  final bool isMobile;

  const SqlView({
    super.key,
    required this.theme,
    this.isMld = true,
    this.isMobile = false,
  });

  @override
  State<SqlView> createState() => _SqlViewState();
}

class _SqlViewState extends State<SqlView> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeriseProvider>();
    final mcd = provider.mcd;
    final scale = provider.textScaleFactor;
    final dialect = provider.sqlDialect;

    // Transformer le MCD en MLD
    final mld = MldTransformer.transform(mcd);

    return Container(
      color: ThemeColors.editorBg(widget.theme),
      padding: EdgeInsets.all(widget.isMobile ? 12 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(scale),
          SizedBox(height: widget.isMobile ? 12 : 24),
          if (!widget.isMld) _buildDialectSelector(scale),
          SizedBox(height: widget.isMobile ? 12 : 24),
          Expanded(
            child: widget.isMld
                ? _buildMldView(mld, scale)
                : _buildMpdView(mld, dialect, scale),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.isMld
                ? "Modèle Logique de Données (MLD)"
                : "Modèle Physique de Données (MPD)",
            style: TextStyle(
              fontSize: (widget.isMobile ? 18 : 24) * scale,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: ThemeColors.textMain(widget.theme),
            ),
          ),
        ),
        if (!widget.isMld)
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: "Copier le code SQL",
            onPressed: () {
              final mcd = context.read<MeriseProvider>().mcd;
              final dialect = context.read<MeriseProvider>().sqlDialect;
              final mld = MldTransformer.transform(mcd);
              final sql = MpdGenerator.generate(mld, dialect);
              Clipboard.setData(ClipboardData(text: sql));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Code SQL copié dans le presse-papier"),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildDialectSelector(double scale) {
    final provider = context.watch<MeriseProvider>();
    return widget.isMobile
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ThemeColors.sidebarBg(widget.theme),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.theme != AppTheme.light
                    ? Colors.white10
                    : Colors.grey[200]!,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SqlDialect>(
                value: provider.sqlDialect,
                onChanged: (d) => provider.setSqlDialect(d!),
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                style: TextStyle(
                  color: ThemeColors.textMain(widget.theme),
                  fontSize: 14,
                ),
                dropdownColor: ThemeColors.sidebarBg(widget.theme),
                items: SqlDialect.values
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(d.name.toUpperCase()),
                      ),
                    )
                    .toList(),
              ),
            ),
          )
        : Row(
            children: SqlDialect.values.map((d) {
              final isSelected = provider.sqlDialect == d;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilterChip(
                  label: Text(d.name.toUpperCase()),
                  selected: isSelected,
                  onSelected: (_) => provider.setSqlDialect(d),
                  selectedColor: const Color(0xFF1E88E5).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF1E88E5),
                ),
              );
            }).toList(),
          );
  }

  Widget _buildMldView(Mld mld, double scale) {
    return ListView.builder(
      itemCount: mld.tables.length,
      itemBuilder: (context, index) {
        final table = mld.tables[index];
        return _TableCard(table: table, theme: widget.theme, scale: scale);
      },
    );
  }

  Widget _buildMpdView(Mld mld, SqlDialect dialect, double scale) {
    final sql = MpdGenerator.generate(mld, dialect);
    final isDark =
        widget.theme != AppTheme.light && widget.theme != AppTheme.papier;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: SelectableText.rich(
            _buildHighlightedSql(sql, isDark),
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: (widget.isMobile ? 13 : 14) * scale,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }

  TextSpan _buildHighlightedSql(String sql, bool isDark) {
    final keywords = {
      'CREATE',
      'TABLE',
      'SELECT',
      'FROM',
      'WHERE',
      'JOIN',
      'ON',
      'AND',
      'OR',
      'INT',
      'VARCHAR',
      'TEXT',
      'DATE',
      'DATETIME',
      'PRIMARY',
      'KEY',
      'FOREIGN',
      'REFERENCES',
      'NOT',
      'NULL',
      'DEFAULT',
      'INDEX',
      'UNIQUE',
      'INSERT',
      'INTO',
      'VALUES',
      'PRAGMA',
      'INTEGER',
      'REAL',
      'TINYINT',
      'DOUBLE',
      'PRECISION',
      'CASCADE',
      'UPDATE',
      'DELETE',
      'SET',
    };

    final List<TextSpan> spans = [];

    // RegExp pour capturer les différents tokens SQL :
    // 1. Identifiants quotés (MySQL backticks, Postgres/SQLite double quotes)
    // 2. Littéraux chaînes (simple quotes)
    // 3. Mots-clés et identifiants non quotés
    // 4. Ponctuation et opérateurs
    // 5. Espaces blancs (pour préserver la mise en forme)
    final regExp = RegExp(
      r'(`[^`]*`|"([^"]|"")*"|' + // Identifiants quotés
          r"'(?:''|[^'])*'|" + // Littéraux chaînes
          r'[a-zA-Z_]\w*|' + // Mots et mots-clés
          r'\d+|' + // Nombres
          r'\s+|' + // Espaces
          r'[(),.;=])', // Ponctuation
    );

    final matches = regExp.allMatches(sql);
    int lastMatchEnd = 0;

    for (final match in matches) {
      // S'il y a du texte entre deux matches (théoriquement non si le RegExp est exhaustif)
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
        color = const Color(0xFFC678DD); // Violet pour les identifiants quotés
      } else if (text.startsWith("'")) {
        color = const Color(0xFF98C379); // Vert pour les chaînes
      } else if (keywords.contains(upperText)) {
        color = const Color(0xFF61AFEF); // Bleu pour les mots-clés
        weight = FontWeight.bold;
      } else if (RegExp(r'^\d+$').hasMatch(text)) {
        color = const Color(0xFFD19A66); // Orange pour les nombres
      } else if (RegExp(r'^[(),.;=]$').hasMatch(text)) {
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

    // Ajouter le reste du texte si nécessaire
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

class _TableCard extends StatelessWidget {
  final MldTable table;
  final AppTheme theme;
  final double scale;

  const _TableCard({
    required this.table,
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la table
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E88E5).withOpacity(0.15),
                  const Color(0xFF1E88E5).withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.table_chart,
                  size: 20,
                  color: Color(0xFF1E88E5),
                ),
                const SizedBox(width: 12),
                Text(
                  table.name,
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: ThemeColors.textMain(theme),
                  ),
                ),
              ],
            ),
          ),

          // Colonnes
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...table.columns.map(
                  (col) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        if (col.isPrimaryKey)
                          const Icon(Icons.key, size: 14, color: Colors.amber),
                        if (col.isForeignKey)
                          const Icon(
                            Icons.link,
                            size: 14,
                            color: Color(0xFF1E88E5),
                          ),
                        if (!col.isPrimaryKey && !col.isForeignKey)
                          const SizedBox(width: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            col.name,
                            style: TextStyle(
                              fontSize: 14 * scale,
                              fontWeight: col.isPrimaryKey
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: ThemeColors.textMain(theme),
                            ),
                          ),
                        ),
                        Text(
                          col.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12 * scale,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (table.foreignKeys.isNotEmpty) ...[
                  const Divider(height: 32),
                  const Text(
                    "CONTRAINTES",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...table.foreignKeys.map(
                    (fk) => Text(
                      "FK: ${fk.columnName} -> ${fk.referencedTable}(${fk.referencedColumn})",
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: const Color(0xFF1E88E5).withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
