import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/merise_provider.dart';
import '../../../theme.dart';
import '../../../merise/mcd_models.dart';

class DictionnaireView extends StatefulWidget {
  final AppTheme theme;
  final bool isMobile;
  const DictionnaireView({
    super.key,
    required this.theme,
    this.isMobile = false,
  });

  @override
  State<DictionnaireView> createState() => _DictionnaireViewState();
}

class _DictionnaireViewState extends State<DictionnaireView> {
  String _searchQuery = '';
  String _typeFilter = 'Tous';
  String _entityFilter = 'Toutes';
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeriseProvider>();
    final mcd = provider.mcd;
    final isDark =
        widget.theme != AppTheme.light && widget.theme != AppTheme.papier;
    final scale = provider.textScaleFactor;

    // Collecter toutes les clés de colonnes personnalisées uniques
    final Set<String> customColumnKeys = {};
    for (final entity in mcd.entities) {
      for (final attr in entity.attributes) {
        customColumnKeys.addAll(attr.customFields.keys);
      }
    }
    for (final rel in mcd.relations) {
      for (final attr in rel.attributes) {
        customColumnKeys.addAll(attr.customFields.keys);
      }
    }

    // Collecter tous les attributs avec leurs métadonnées
    final List<Map<String, dynamic>> allAttributes = [];
    for (final entity in mcd.entities) {
      for (int i = 0; i < entity.attributes.length; i++) {
        final attr = entity.attributes[i];
        allAttributes.add({
          'name': attr.name,
          'type': attr.type,
          'isPK': attr.isPrimaryKey,
          'description': attr.description,
          'length': attr.length,
          'constraints': attr.constraints,
          'rules': attr.rules,
          'customFields': attr.customFields,
          'entity': entity.name,
          'entityId': entity.id,
          'attrIndex': i,
          'itemId': entity.id,
        });
      }
    }
    for (final rel in mcd.relations) {
      for (int i = 0; i < rel.attributes.length; i++) {
        final attr = rel.attributes[i];
        allAttributes.add({
          'name': attr.name,
          'type': attr.type,
          'isPK': attr.isPrimaryKey,
          'description': attr.description,
          'length': attr.length,
          'constraints': attr.constraints,
          'rules': attr.rules,
          'customFields': attr.customFields,
          'entity': rel.name,
          'entityId': rel.id,
          'attrIndex': i,
          'itemId': rel.id,
        });
      }
    }

    // Filtrage
    var filteredAttributes = allAttributes.where((attr) {
      final matchesSearch =
          attr['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          attr['description'].toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          attr['entity'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType =
          _typeFilter == 'Tous' ||
          attr['type'].toLowerCase() == _typeFilter.toLowerCase();
      final matchesEntity =
          _entityFilter == 'Toutes' || attr['entity'] == _entityFilter;
      return matchesSearch && matchesType && matchesEntity;
    }).toList();

    // Tri
    if (_sortColumnIndex != null) {
      filteredAttributes.sort((a, b) {
        dynamic valA, valB;
        switch (_sortColumnIndex) {
          case 0:
            valA = a['name'];
            valB = b['name'];
            break;
          case 1:
            valA = a['type'];
            valB = b['type'];
            break;
          case 2:
            valA = a['entity'];
            valB = b['entity'];
            break;
          default:
            valA = '';
            valB = '';
        }
        return _sortAscending
            ? Comparable.compare(valA, valB)
            : Comparable.compare(valB, valA);
      });
    }

    final entitiesList = [
      'Toutes',
      ...mcd.entities.map((e) => e.name),
      ...mcd.relations.map((r) => r.name),
    ];
    final typesList = ['Tous', 'ENTIER', 'CHAINE', 'DATE', 'BOOLEEN', 'REEL'];

    return Container(
      color: ThemeColors.editorBg(widget.theme),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          widget.isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Dictionnaire des Données",
                      style: TextStyle(
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.textMain(widget.theme),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _InfoCard(
                          label: "Données",
                          value: allAttributes.length.toString(),
                          icon: Icons.inventory_2,
                          theme: widget.theme,
                          scale: scale,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () =>
                              _showAddAttributeDialog(provider, mcd),
                          icon: const Icon(Icons.add_chart, size: 24),
                          color: Colors.blueAccent,
                          tooltip: "Nouvelle Donnée",
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dictionnaire des Données",
                          style: TextStyle(
                            fontSize: 24 * scale,
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.textMain(widget.theme),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Gestion technique et dictionnaire exhaustif du modèle",
                          style: TextStyle(
                            fontSize: 13 * scale,
                            color: ThemeColors.textMain(
                              widget.theme,
                            ).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _InfoCard(
                          label: "Données",
                          value: allAttributes.length.toString(),
                          icon: Icons.inventory_2,
                          theme: widget.theme,
                          scale: scale,
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showAddAttributeDialog(provider, mcd),
                          icon: const Icon(Icons.add_chart, size: 16),
                          label: const Text("Nouvelle Donnée"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          const SizedBox(height: 24),

          // Barre de recherche et Filtres
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ThemeColors.sidebarBg(widget.theme),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey[200]!,
              ),
            ),
            child: widget.isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: TextStyle(
                          color: ThemeColors.textMain(widget.theme),
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: "Rechercher...",
                          hintStyle: TextStyle(
                            color: ThemeColors.textMain(
                              widget.theme,
                            ).withOpacity(0.4),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 18,
                            color: ThemeColors.textMain(
                              widget.theme,
                            ).withOpacity(0.5),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.black26 : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFilterDropdown(
                              "Type",
                              _typeFilter,
                              typesList,
                              (v) => setState(() => _typeFilter = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFilterDropdown(
                              "Source",
                              _entityFilter,
                              entitiesList,
                              (v) => setState(() => _entityFilter = v!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: TextStyle(
                            color: ThemeColors.textMain(widget.theme),
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: "Rechercher...",
                            hintStyle: TextStyle(
                              color: ThemeColors.textMain(
                                widget.theme,
                              ).withOpacity(0.4),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 18,
                              color: ThemeColors.textMain(
                                widget.theme,
                              ).withOpacity(0.5),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: isDark ? Colors.black26 : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildFilterDropdown(
                        "Type",
                        _typeFilter,
                        typesList,
                        (v) => setState(() => _typeFilter = v!),
                      ),
                      const SizedBox(width: 12),
                      _buildFilterDropdown(
                        "Source",
                        _entityFilter,
                        entitiesList,
                        (v) => setState(() => _entityFilter = v!),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _showAddColumnDialog(),
                        icon: const Icon(Icons.view_column, size: 20),
                        tooltip: "Ajouter une colonne personnalisée",
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _exportToCSV(
                          filteredAttributes,
                          customColumnKeys,
                          context,
                        ),
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text("CSV"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.teal,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            _exportToJSON(filteredAttributes, context),
                        icon: const Icon(Icons.code, size: 16),
                        label: const Text("JSON"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),

          // Tableau Principal
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: ThemeColors.sidebarBg(widget.theme),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      headingRowColor: WidgetStateProperty.all(
                        isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey[50],
                      ),
                      columns: [
                        _buildSortableColumn("Nom", 0),
                        _buildSortableColumn("Type", 1),
                        const DataColumn(label: Text("Description")),
                        const DataColumn(label: Text("Format")),
                        const DataColumn(label: Text("Contraintes")),
                        const DataColumn(label: Text("Règles")),
                        ...customColumnKeys.map(
                          (key) => DataColumn(label: Text(key)),
                        ),
                        _buildSortableColumn("Provenance", 2),
                        const DataColumn(label: Text("")),
                      ],
                      rows: filteredAttributes.map((attr) {
                        return DataRow(
                          cells: [
                            DataCell(
                              InkWell(
                                onTap: () => _showEditDialog(
                                  attr['name'],
                                  "Nom",
                                  (v) => provider.updateAttributeName(
                                    attr['itemId'],
                                    attr['attrIndex'],
                                    v,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    if (attr['isPK'])
                                      const Icon(
                                        Icons.key,
                                        size: 12,
                                        color: Colors.amber,
                                      ),
                                    if (attr['isPK']) const SizedBox(width: 6),
                                    Text(
                                      attr['name'],
                                      style: TextStyle(
                                        fontWeight: attr['isPK']
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: ThemeColors.textMain(
                                          widget.theme,
                                        ),
                                        fontFamily: 'JetBrainsMono',
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.edit,
                                      size: 10,
                                      color: ThemeColors.textMain(
                                        widget.theme,
                                      ).withOpacity(0.2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              InkWell(
                                onTap: () => _showTypePicker(
                                  attr['type'],
                                  (v) => provider.updateAttributeType(
                                    attr['itemId'],
                                    attr['attrIndex'],
                                    v,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildTypeBadge(attr['type']),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.edit,
                                      size: 10,
                                      color: ThemeColors.textMain(
                                        widget.theme,
                                      ).withOpacity(0.2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              _buildEditableCell(
                                attr['description'],
                                "Description",
                                (v) => provider.updateAttributeDescription(
                                  attr['itemId'],
                                  attr['attrIndex'],
                                  v,
                                ),
                              ),
                            ),
                            DataCell(
                              _buildEditableCell(
                                attr['length'],
                                "Format",
                                (v) => provider.updateAttributeLength(
                                  attr['itemId'],
                                  attr['attrIndex'],
                                  v,
                                ),
                              ),
                            ),
                            DataCell(
                              _buildEditableCell(
                                attr['constraints'],
                                "Contraintes",
                                (v) => provider.updateAttributeConstraints(
                                  attr['itemId'],
                                  attr['attrIndex'],
                                  v,
                                ),
                              ),
                            ),
                            DataCell(
                              _buildEditableCell(
                                attr['rules'],
                                "Règles",
                                (v) => provider.updateAttributeRules(
                                  attr['itemId'],
                                  attr['attrIndex'],
                                  v,
                                ),
                              ),
                            ),
                            ...customColumnKeys.map((key) {
                              final value =
                                  (attr['customFields']
                                      as Map<String, String>)[key] ??
                                  '';
                              return DataCell(
                                _buildEditableCell(
                                  value,
                                  key,
                                  (v) => provider.updateAttributeCustomField(
                                    attr['itemId'],
                                    attr['attrIndex'],
                                    key,
                                    v,
                                  ),
                                ),
                              );
                            }),
                            DataCell(
                              Text(
                                attr['entity'],
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(
                                  Icons.open_in_new,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  provider.setActiveView('mcd');
                                  final List<dynamic> allSources = [
                                    ...mcd.entities,
                                    ...mcd.relations,
                                  ];
                                  final item = allSources.firstWhere(
                                    (e) => e.id == attr['entityId'],
                                    orElse: () => null,
                                  );
                                  if (item != null) provider.selectItem(item);
                                },
                                tooltip: "Voir dans le MCD",
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAttributeDialog(MeriseProvider provider, Mcd mcd) {
    if (mcd.entities.isEmpty && mcd.relations.isEmpty) return;
    String selectedSource = mcd.entities.isNotEmpty
        ? mcd.entities.first.name
        : mcd.relations.first.name;
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: ThemeColors.sidebarBg(widget.theme),
          title: Text(
            "Ajouter une donnée",
            style: TextStyle(color: ThemeColors.textMain(widget.theme)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedSource,
                dropdownColor: ThemeColors.sidebarBg(widget.theme),
                decoration: const InputDecoration(
                  labelText: "Cible (Entité/Relation)",
                  labelStyle: TextStyle(color: Colors.blue),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
                items:
                    [
                          ...mcd.entities.map((e) => e.name),
                          ...mcd.relations.map((r) => r.name),
                        ]
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s,
                            child: Text(
                              s,
                              style: TextStyle(
                                color: ThemeColors.textMain(widget.theme),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setDialogState(() => selectedSource = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                style: TextStyle(color: ThemeColors.textMain(widget.theme)),
                decoration: const InputDecoration(
                  labelText: "Nom de l'attribut",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  provider.addAttributeToEntityByName(
                    selectedSource,
                    nameController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text("Ajouter"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddColumnDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.sidebarBg(widget.theme),
        title: Text(
          "Nouvelle Colonne",
          style: TextStyle(color: ThemeColors.textMain(widget.theme)),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: TextStyle(color: ThemeColors.textMain(widget.theme)),
          decoration: const InputDecoration(
            labelText: "Nom de la colonne (ex: Alias, Source...)",
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text("Créer"),
          ),
        ],
      ),
    );
  }

  void _showTypePicker(String currentType, Function(String) onSave) {
    final types = ['ENTIER', 'CHAINE', 'DATE', 'BOOLEEN', 'REEL'];
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: ThemeColors.sidebarBg(widget.theme),
        title: const Text("Choisir un Type"),
        children: types
            .map(
              (t) => SimpleDialogOption(
                onPressed: () {
                  onSave(t);
                  Navigator.pop(context);
                },
                child: _buildTypeBadge(t),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: widget.theme != AppTheme.light
            ? Colors.white10
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          icon: const Icon(Icons.arrow_drop_down, size: 16),
          style: TextStyle(
            color: ThemeColors.textMain(widget.theme),
            fontSize: 12,
          ),
          dropdownColor: ThemeColors.sidebarBg(widget.theme),
          items: items
              .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
              .toList(),
        ),
      ),
    );
  }

  DataColumn _buildSortableColumn(String label, int index) {
    return DataColumn(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      onSort: (col, asc) => setState(() {
        _sortColumnIndex = index;
        _sortAscending = asc;
      }),
    );
  }

  Widget _buildTypeBadge(String type) {
    final color = _getTypeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEditableCell(String text, String hint, Function(String) onSave) {
    return Tooltip(
      message: "Cliquer pour modifier",
      child: InkWell(
        onTap: () => _showEditDialog(text, hint, onSave),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            text.isEmpty ? "..." : text,
            style: TextStyle(
              fontSize: 12,
              color: text.isEmpty
                  ? Colors.grey
                  : ThemeColors.textMain(widget.theme),
              fontStyle: text.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  void _showEditDialog(
    String initialText,
    String label,
    Function(String) onSave,
  ) {
    final controller = TextEditingController(text: initialText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.sidebarBg(widget.theme),
        title: Text(
          "Modifier $label",
          style: TextStyle(color: ThemeColors.textMain(widget.theme)),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: ThemeColors.textMain(widget.theme)),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.blue),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
          ),
          maxLines: label == "Description" ? 3 : 1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  void _exportToCSV(
    List<Map<String, dynamic>> data,
    Set<String> customKeys,
    BuildContext context,
  ) {
    String headers = "Attribut,Type,Description,Format,Contraintes,Regles";
    for (var k in customKeys) headers += ",$k";
    headers += ",Entite\n";
    String csv = headers;
    for (var row in data) {
      csv +=
          "${row['name']},${row['type']},\"${row['description']}\",\"${row['length']}\",\"${row['constraints']}\",\"${row['rules']}\"";
      for (var k in customKeys) {
        final val = (row['customFields'] as Map<String, String>)[k] ?? '';
        csv += ",\"$val\"";
      }
      csv += ",${row['entity']}\n";
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Exportation CSV générée")));
    debugPrint(csv);
  }

  void _exportToJSON(List<Map<String, dynamic>> data, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Exportation JSON générée (Console)")),
    );
    debugPrint(JsonEncoder.withIndent('  ').convert(data));
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'ENTIER':
        return Colors.blue;
      case 'CHAINE':
        return Colors.green;
      case 'DATE':
        return Colors.orange;
      case 'BOOLEEN':
        return Colors.purple;
      case 'REEL':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final AppTheme theme;
  final double scale;
  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.theme,
    required this.scale,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    const primaryColor = Color(0xFF1E88E5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryColor, size: 18 * scale),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.textMain(theme),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9 * scale,
                  color: ThemeColors.textMain(theme).withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
