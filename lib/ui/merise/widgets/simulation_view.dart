import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../merise/mld_transformer.dart';
import '../../../merise/sql_engine.dart';
import '../../../providers/merise_provider.dart';
import '../../../theme.dart';

class SimulationView extends StatefulWidget {
  final AppTheme theme;
  final bool isMobile;

  const SimulationView({super.key, required this.theme, this.isMobile = false});

  @override
  State<SimulationView> createState() => _SimulationViewState();
}

class _SimulationViewState extends State<SimulationView> {
  String? _activeTableName;
  bool _isInitializing = false;
  List<Map<String, dynamic>> _tableData = [];
  final TextEditingController _sqlController = TextEditingController();
  QueryResult? _queryResult;
  final List<String> _queryHistory = [];

  @override
  void dispose() {
    _sqlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeriseProvider>();
    final scale = provider.textScaleFactor;
    final sqlEngine = provider.sqlEngine;
    final mld = provider.currentMld;

    if (provider.entities.isEmpty) {
      return _buildEmptyState(scale);
    }

    return Container(
      color: ThemeColors.editorBg(widget.theme),
      padding: EdgeInsets.all(widget.isMobile ? 12 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(scale),
          const SizedBox(height: 24),
          _buildToolbar(provider, sqlEngine, scale),
          const SizedBox(height: 24),
          Expanded(
            child: widget.isMobile
                ? SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildDataPanel(provider, mld, sqlEngine, scale),
                        const SizedBox(height: 24),
                        _buildSqlTerminal(provider, sqlEngine, scale),
                        const SizedBox(height: 100), // Extra space for FABs
                      ],
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Panneau gauche: Données des tables
                      Expanded(
                        flex: 1,
                        child: _buildDataPanel(provider, mld, sqlEngine, scale),
                      ),
                      const SizedBox(width: 24),
                      // Panneau droit: Terminal SQL
                      Expanded(
                        flex: 1,
                        child: _buildSqlTerminal(provider, sqlEngine, scale),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Simulation & Playground SQL",
          style: TextStyle(
            fontSize: (widget.isMobile ? 18 : 24) * scale,
            fontWeight: FontWeight.bold,
            color: ThemeColors.textMain(widget.theme),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Testez votre modèle avec des données réelles et exécutez des requêtes SQL.",
          style: TextStyle(
            fontSize: 14 * scale,
            color: ThemeColors.textMain(widget.theme).withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(
    MeriseProvider provider,
    SqlEngine? sqlEngine,
    double scale,
  ) {
    final isInitialized = sqlEngine?.isInitialized ?? false;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ElevatedButton.icon(
          onPressed: _isInitializing
              ? null
              : () async {
                  setState(() => _isInitializing = true);
                  try {
                    await provider.initializeSimulation();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Base de données initialisée avec succès',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isInitializing = false);
                  }
                },
          icon: _isInitializing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.power_settings_new),
          label: Text(isInitialized ? "Réinitialiser DB" : "Initialiser DB"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
          ),
        ),
        if (isInitialized)
          OutlinedButton.icon(
            onPressed: () async {
              await provider.clearAllTables();
              await _refreshTableData(provider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Toutes les tables ont été vidées'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete_sweep),
            label: Text(
              widget.isMobile ? "Tout vider" : "Vider toutes les tables",
            ),
          ),
      ],
    );
  }

  Widget _buildDataPanel(
    MeriseProvider provider,
    Mld? mld,
    SqlEngine? sqlEngine,
    double scale,
  ) {
    if (sqlEngine == null || !sqlEngine.isInitialized || mld == null) {
      return _buildNotInitializedPanel(scale);
    }

    final tables = mld.tables;
    if (tables.isEmpty) {
      return Center(
        child: Text(
          "Aucune table dans le MLD",
          style: TextStyle(color: Colors.grey, fontSize: 14 * scale),
        ),
      );
    }

    _activeTableName ??= tables.first.name;
    final activeTable = tables.firstWhere(
      (t) => t.name == _activeTableName,
      orElse: () => tables.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Données des Tables",
          style: TextStyle(
            fontSize: (widget.isMobile ? 16 : 18) * scale,
            fontWeight: FontWeight.bold,
            color: ThemeColors.textMain(widget.theme),
          ),
        ),
        const SizedBox(height: 16),
        _buildTableSelector(tables, scale),
        const SizedBox(height: 16),
        _buildTableActions(provider, activeTable, scale),
        const SizedBox(height: 16),
        if (widget.isMobile)
          SizedBox(
            height: 300,
            child: _buildDataTable(activeTable, _tableData, scale),
          )
        else
          Expanded(child: _buildDataTable(activeTable, _tableData, scale)),
      ],
    );
  }

  Widget _buildNotInitializedPanel(double scale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storage_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "Cliquez sur 'Initialiser DB' pour commencer",
            style: TextStyle(fontSize: 16 * scale, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSelector(List<MldTable> tables, double scale) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tables.map((table) {
          final isSelected = _activeTableName == table.name;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(table.name),
              selected: isSelected,
              onSelected: (val) async {
                if (val) {
                  setState(() => _activeTableName = table.name);
                  await _refreshTableData(context.read<MeriseProvider>());
                }
              },
              selectedColor: const Color(0xFF1E88E5).withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF1E88E5) : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTableActions(
    MeriseProvider provider,
    MldTable table,
    double scale,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showAddRecordDialog(provider, table),
          icon: const Icon(Icons.add),
          label: Text(
            widget.isMobile ? "Ajouter" : "Ajouter un enregistrement",
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            padding: widget.isMobile
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                : null,
          ),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            await provider.clearTableData(table.name);
            await _refreshTableData(provider);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Table ${table.name} vidée')),
              );
            }
          },
          icon: const Icon(Icons.delete),
          label: Text(widget.isMobile ? "Vider" : "Vider la table"),
          style: widget.isMobile
              ? OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                )
              : null,
        ),
      ],
    );
  }

  Future<void> _refreshTableData(MeriseProvider provider) async {
    if (_activeTableName != null) {
      final data = await provider.getTableData(_activeTableName!);
      if (mounted) {
        setState(() => _tableData = data);
      }
    }
  }

  Widget _buildDataTable(
    MldTable table,
    List<Map<String, dynamic>> data,
    double scale,
  ) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          "Aucune donnée dans cette table",
          style: TextStyle(color: Colors.grey, fontSize: 14 * scale),
        ),
      );
    }

    final isDark =
        widget.theme != AppTheme.light && widget.theme != AppTheme.papier;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(widget.theme),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: table.columns.map((col) {
              String label = col.name;
              if (col.isPrimaryKey) label += ' (PK)';
              if (col.isForeignKey) label += ' (FK)';

              return DataColumn(
                label: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: col.isPrimaryKey
                        ? const Color(0xFFFF9800)
                        : col.isForeignKey
                        ? const Color(0xFF9C27B0)
                        : const Color(0xFF1E88E5),
                  ),
                ),
              );
            }).toList(),
            rows: data.map((record) {
              return DataRow(
                cells: table.columns.map((col) {
                  final value = record[col.name];
                  return DataCell(Text(value?.toString() ?? "NULL"));
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSqlTerminal(
    MeriseProvider provider,
    SqlEngine? sqlEngine,
    double scale,
  ) {
    final isInitialized = sqlEngine?.isInitialized ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Terminal SQL",
          style: TextStyle(
            fontSize: 18 * scale,
            fontWeight: FontWeight.bold,
            color: ThemeColors.textMain(widget.theme),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeColors.sidebarBg(widget.theme),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.theme != AppTheme.light
                  ? Colors.white10
                  : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _sqlController,
                enabled: isInitialized,
                maxLines: 5,
                style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13 * scale),
                decoration: InputDecoration(
                  hintText: isInitialized
                      ? 'SELECT * FROM nom_table;'
                      : 'Initialisez la base de données d\'abord...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: ThemeColors.editorBg(widget.theme),
                ),
                onSubmitted: isInitialized
                    ? (_) => _executeQuery(provider)
                    : null,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: isInitialized
                        ? () => _executeQuery(provider)
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      widget.isMobile ? "Exécuter" : "Exécuter (Ctrl+Enter)",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _sqlController.clear(),
                    icon: const Icon(Icons.clear),
                    label: const Text("Effacer"),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.isMobile)
          _buildQueryResult(scale)
        else
          Expanded(child: _buildQueryResult(scale)),
      ],
    );
  }

  Widget _buildQueryResult(double scale) {
    if (_queryResult == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ThemeColors.sidebarBg(widget.theme),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.theme != AppTheme.light
                ? Colors.white10
                : Colors.grey[200]!,
          ),
        ),
        child: Center(
          child: Text(
            "Les résultats de la requête s'afficheront ici",
            style: TextStyle(color: Colors.grey, fontSize: 14 * scale),
          ),
        ),
      );
    }

    if (_queryResult!.hasError) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  "Erreur SQL",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16 * scale,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _queryResult!.error!,
              style: TextStyle(
                color: Colors.red[900],
                fontFamily: 'JetBrainsMono',
                fontSize: 13 * scale,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(widget.theme),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.theme != AppTheme.light
              ? Colors.white10
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                "${_queryResult!.rowCount} ligne(s) • ${_queryResult!.executionTime.inMilliseconds}ms",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14 * scale,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_queryResult!.isEmpty)
            const Center(
              child: Text(
                "Aucun résultat",
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: _queryResult!.columns.map((col) {
                      return DataColumn(
                        label: Text(
                          col,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                      );
                    }).toList(),
                    rows: _queryResult!.rows.map((row) {
                      return DataRow(
                        cells: _queryResult!.columns.map((col) {
                          final value = row[col];
                          return DataCell(Text(value?.toString() ?? "NULL"));
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _executeQuery(MeriseProvider provider) async {
    final sql = _sqlController.text.trim();
    if (sql.isEmpty) return;

    // Ajouter à l'historique
    _queryHistory.add(sql);

    final result = await provider.executeQuery(sql);
    if (mounted) {
      setState(() => _queryResult = result);
    }

    // Rafraîchir les données de la table active si c'était une modification
    if (sql.toUpperCase().startsWith('INSERT') ||
        sql.toUpperCase().startsWith('UPDATE') ||
        sql.toUpperCase().startsWith('DELETE')) {
      await _refreshTableData(provider);
    }
  }

  void _showAddRecordDialog(MeriseProvider provider, MldTable table) {
    showDialog(
      context: context,
      builder: (context) => _AddRecordDialog(
        table: table,
        mld: provider.currentMld!,
        onAdd: (data) async {
          try {
            await provider.addRecordToTable(table.name, data);
            await _refreshTableData(provider);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Enregistrement ajouté avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildEmptyState(double scale) {
    return Center(
      child: Text(
        "Créez au moins une entité dans le MCD pour utiliser la simulation.",
        style: TextStyle(fontSize: 16 * scale, color: Colors.grey),
      ),
    );
  }
}

// Dialog pour ajouter un enregistrement
class _AddRecordDialog extends StatefulWidget {
  final MldTable table;
  final Mld mld;
  final Function(Map<String, dynamic>) onAdd;

  const _AddRecordDialog({
    required this.table,
    required this.mld,
    required this.onAdd,
  });

  @override
  State<_AddRecordDialog> createState() => _AddRecordDialogState();
}

class _AddRecordDialogState extends State<_AddRecordDialog> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final col in widget.table.columns) {
      _controllers[col.name] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ajouter un enregistrement - ${widget.table.name}'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.table.columns.map((col) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildFieldForColumn(col),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
          ),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }

  Widget _buildFieldForColumn(MldColumn col) {
    String label = col.name;
    if (col.isPrimaryKey) label += ' (PK)';
    if (col.isForeignKey) label += ' (FK)';

    // Pour les clés primaires auto-incrémentées, on peut laisser vide
    if (col.isPrimaryKey && col.type.toUpperCase().contains('INT')) {
      return TextField(
        controller: _controllers[col.name],
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Auto (laisser vide)',
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
      );
    }

    // Pour les clés étrangères, on pourrait ajouter un dropdown
    // mais pour simplifier, on utilise un champ texte
    return TextField(
      controller: _controllers[col.name],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: _getKeyboardType(col.type),
    );
  }

  TextInputType _getKeyboardType(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('int') || lowerType.contains('entier')) {
      return TextInputType.number;
    }
    if (lowerType.contains('real') || lowerType.contains('double')) {
      return const TextInputType.numberWithOptions(decimal: true);
    }
    return TextInputType.text;
  }

  void _submitForm() {
    final data = <String, dynamic>{};

    for (final col in widget.table.columns) {
      final value = _controllers[col.name]!.text.trim();

      // Si c'est une PK auto et vide, on ne l'ajoute pas
      if (col.isPrimaryKey && value.isEmpty) {
        continue;
      }

      // Conversion selon le type
      if (value.isEmpty) {
        data[col.name] = null;
      } else {
        final lowerType = col.type.toLowerCase();
        if (lowerType.contains('int')) {
          data[col.name] = int.tryParse(value) ?? value;
        } else if (lowerType.contains('real') || lowerType.contains('double')) {
          data[col.name] = double.tryParse(value) ?? value;
        } else {
          data[col.name] = value;
        }
      }
    }

    widget.onAdd(data);
    Navigator.pop(context);
  }
}
