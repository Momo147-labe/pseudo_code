import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/merise_provider.dart';
import '../../../merise/mcd_models.dart';
import '../../../theme.dart';

const List<String> allowedTypes = [
  'ENTIER',
  'CHAINE',
  'TEXTE',
  'MONNAIE',
  'REEL',
  'DECIMAL',
  'DATE',
  'HEURE',
  'DATE_HEURE',
  'BOOLEEN',
  'BLOB',
];

class MerisePropertiesPanel extends StatefulWidget {
  final AppTheme theme;
  final bool isMobile;
  const MerisePropertiesPanel({
    super.key,
    required this.theme,
    this.isMobile = false,
  });

  @override
  State<MerisePropertiesPanel> createState() => _MerisePropertiesPanelState();
}

class _MerisePropertiesPanelState extends State<MerisePropertiesPanel> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeriseProvider>();
    final selectedItem = provider.selectedItem;
    final primaryColor = const Color(0xFF1E88E5);
    final theme = widget.theme;
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    final scale = provider.textScaleFactor;

    if (selectedItem == null) {
      return _buildEmptyState(theme, primaryColor, scale);
    }

    if (provider.selectedIds.length > 1) {
      return _buildMultiSelectState(
        provider.selectedIds.length,
        theme,
        primaryColor,
        scale,
        provider,
      );
    }

    // Sync name controller if not focused
    final name = (selectedItem is McdEntity)
        ? selectedItem.name
        : (selectedItem is McdRelation ? selectedItem.name : "");

    if (_nameController.text != name && selectedItem is! McdLink) {
      _nameController.text = name;
    }

    return Container(
      width: widget.isMobile ? null : 300 * (scale > 1.2 ? 1.05 : 1.0),
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme),
        border: widget.isMobile
            ? null
            : Border(
                left: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
      ),
      child: Column(
        children: [
          _buildHeader(selectedItem, provider, primaryColor, theme, scale),
          if (selectedItem is McdRelation)
            _buildRelationLinks(
              selectedItem,
              provider,
              primaryColor,
              theme,
              scale,
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (selectedItem is! McdLink) ...[
                  _buildFieldLabel("Nom de l'élément", scale, theme),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    onChanged: (val) {
                      if (selectedItem is McdEntity) {
                        provider.updateEntityName(selectedItem.id, val);
                      } else if (selectedItem is McdRelation) {
                        provider.updateRelationName(selectedItem.id, val);
                      }
                    },
                    decoration: _inputDecoration(theme, primaryColor, scale),
                    style: TextStyle(
                      fontSize: 14 * scale,
                      color: ThemeColors.textMain(theme),
                    ),
                  ),
                ] else
                  _buildCardinalitySelector(
                    selectedItem,
                    provider,
                    primaryColor,
                    theme,
                    scale,
                  ),
                if (selectedItem is McdEntity ||
                    selectedItem is McdRelation) ...[
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFieldLabel("Attributs", scale, theme),
                      TextButton.icon(
                        onPressed: () => provider.addAttribute(
                          selectedItem is McdEntity
                              ? selectedItem.id
                              : (selectedItem as McdRelation).id,
                        ),
                        icon: Icon(
                          Icons.add_circle_outline,
                          size: 14 * scale,
                          color: primaryColor,
                        ),
                        label: Text(
                          "Ajouter",
                          style: TextStyle(
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...(selectedItem is McdEntity
                          ? selectedItem.attributes
                          : (selectedItem as McdRelation).attributes)
                      .asMap()
                      .entries
                      .map((entry) {
                        return _AttributeItem(
                          attr: entry.value,
                          index: entry.key,
                          itemId: selectedItem is McdEntity
                              ? selectedItem.id
                              : (selectedItem as McdRelation).id,
                          theme: theme,
                          primaryColor: primaryColor,
                          scale: scale,
                          isMobile: widget.isMobile,
                        );
                      })
                      .toList(),
                ],
                SizedBox(height: widget.isMobile ? 40 : 32),
                _buildPedagogicBox(selectedItem, primaryColor, theme, scale),
                if (widget.isMobile) const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppTheme theme, Color primaryColor, double scale) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    return Container(
      width: widget.isMobile ? null : 250,
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme),
        border: widget.isMobile
            ? null
            : Border(
                left: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app_outlined,
              size: 48 * scale,
              color: primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "Sélectionnez un élément\npour voir ses propriétés",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
                fontSize: 14 * scale,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectState(
    int count,
    AppTheme theme,
    Color primaryColor,
    double scale,
    MeriseProvider provider,
  ) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    return Container(
      width: widget.isMobile ? null : 380,
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme),
        border: widget.isMobile
            ? null
            : Border(
                left: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.layers_outlined,
              size: 48 * scale,
              color: primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "$count éléments sélectionnés",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ThemeColors.textMain(theme),
                fontSize: 16 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Vous pouvez les déplacer ou\nles supprimer ensemble.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
                fontSize: 13 * scale,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.deleteSelectedItems(),
              icon: Icon(Icons.delete, size: 18 * scale),
              label: Text("Supprimer la sélection ($count)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    dynamic item,
    MeriseProvider provider,
    Color primaryColor,
    AppTheme theme,
    double scale,
  ) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    String name = "";
    IconData icon = Icons.help_outline;

    if (item is McdEntity) {
      name = item.name;
      icon = Icons.rectangle_outlined;
    } else if (item is McdRelation) {
      name = item.name;
      icon = Icons.circle_outlined;
    } else if (item is McdLink) {
      final ent = provider.entities.firstWhere((e) => e.id == item.entityId);
      final rel = provider.relations.firstWhere((r) => r.id == item.relationId);
      name = "${ent.name} ↔ ${rel.name}";
      icon = Icons.link;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey[200]!,
          ),
        ),
      ),
      height: widget.isMobile ? 60 : null,
      child: Row(
        children: [
          Icon(
            icon,
            color: primaryColor,
            size: (widget.isMobile ? 24 : 20) * scale,
          ),
          const SizedBox(width: 8),
          Text(
            "Propriétés : ",
            style: TextStyle(
              fontSize: (widget.isMobile ? 14 : 13) * scale,
              fontWeight: FontWeight.bold,
              color: ThemeColors.textMain(theme),
            ),
          ),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: (widget.isMobile ? 14 : 13) * scale,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.save,
              size: (widget.isMobile ? 24 : 20) * scale,
              color: Colors.green,
            ),
            onPressed: () => provider.requestSave(),
            tooltip: "Enregistrer (Ctrl+S)",
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              size: (widget.isMobile ? 22 : 18) * scale,
              color: Colors.red[400],
            ),
            onPressed: () {
              if (item is McdLink) {
                provider.deleteLink(item.entityId, item.relationId);
                provider.selectItem(null);
              } else {
                provider.deleteSelectedItems();
              }
            },
            tooltip: "Supprimer",
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, double scale, AppTheme theme) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13 * scale,
        fontWeight: FontWeight.w600,
        color: ThemeColors.textMain(theme),
      ),
    );
  }

  InputDecoration _inputDecoration(
    AppTheme theme,
    Color primaryColor,
    double scale,
  ) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    return InputDecoration(
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.grey[50],
      isDense: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: widget.isMobile ? 18 : 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }

  Widget _buildPedagogicBox(
    dynamic item,
    Color primaryColor,
    AppTheme theme,
    double scale,
  ) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    String title = "Comprendre Merise";
    String content =
        "Sélectionnez une entité ou une relation pour voir des conseils personnalisés.";

    if (item is McdEntity) {
      title = "L'Entité : ${item.name}";
      content =
          "Une entité représente un objet ou un concept du monde réel. Chaque entité doit posséder un identifiant unique (Clé Primaire).";
    } else if (item is McdRelation) {
      title = "La Relation : ${item.name}";
      content =
          "Les relations décrivent les associations entre entités. Elles sont caractérisées par des cardinalités (0,1, 1,n, etc.).";
    } else if (item is McdLink) {
      title = "Le Lien (Cardinalités)";
      content =
          "Les cardinalités définissent combien de fois une entité participe à une relation.\n\n"
          "• 0,1 : Optionnel (Maximum 1)\n"
          "• 1,1 : Obligatoire (Exactement 1)\n"
          "• 0,n : Optionnel (Plusieurs)\n"
          "• 1,n : Obligatoire (Plusieurs)";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school_outlined,
                color: primaryColor,
                size: 18 * scale,
              ),
              const SizedBox(width: 8),
              Text(
                "Le Coin Pédagogique".toUpperCase(),
                style: TextStyle(
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12 * scale,
              fontWeight: FontWeight.bold,
              color: ThemeColors.textMain(theme),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 13 * scale,
              fontStyle: FontStyle.italic,
              color: ThemeColors.textMain(theme).withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardinalitySelector(
    McdLink link,
    MeriseProvider provider,
    Color primaryColor,
    AppTheme theme,
    double scale,
  ) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    final cards = ["0,1", "1,1", "0,n", "1,n"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel("Cardinalités", scale, theme),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cards.map((c) {
            final isSelected = link.cardinalities == c;
            return InkWell(
              onTap: () => provider.updateLinkCardinality(
                link.entityId,
                link.relationId,
                c,
              ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: widget.isMobile ? 12 : 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.1)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey[50]),
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.transparent,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  c,
                  style: TextStyle(
                    fontSize: (widget.isMobile ? 15 : 14) * scale,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? primaryColor
                        : ThemeColors.textMain(theme).withValues(alpha: 0.8),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRelationLinks(
    McdRelation relation,
    MeriseProvider provider,
    Color primaryColor,
    AppTheme theme,
    double scale,
  ) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    final links = provider.getLinksForRelation(relation.id);
    final available = provider.getAvailableEntitiesForRelation(relation.id);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey[200]!,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFieldLabel("Entités reliées", scale, theme),
              if (available.isNotEmpty)
                PopupMenuButton<McdEntity>(
                  icon: Icon(
                    Icons.add_link,
                    size: 18 * scale,
                    color: primaryColor,
                  ),
                  tooltip: "Lier une entité",
                  onSelected: (ent) => provider.createLink(ent.id, relation.id),
                  itemBuilder: (context) => available
                      .map(
                        (e) => PopupMenuItem(
                          value: e,
                          child: Text(
                            e.name,
                            style: TextStyle(fontSize: 12 * scale),
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
          if (links.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "Aucune entité liée",
                style: TextStyle(
                  fontSize: 12 * scale,
                  color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
                ),
              ),
            )
          else
            ...links.map((link) {
              final entity = provider.entities.firstWhere(
                (e) => e.id == link.entityId,
              );
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entity.name,
                        style: TextStyle(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.bold,
                          color: ThemeColors.textMain(theme),
                        ),
                      ),
                    ),
                    _buildMiniCardinality(link, provider, theme, scale),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18 * scale,
                        color: Colors.red,
                      ),
                      onPressed: () =>
                          provider.deleteLink(link.entityId, relation.id),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildMiniCardinality(
    McdLink link,
    MeriseProvider provider,
    AppTheme theme,
    double scale,
  ) {
    final cards = ["0,1", "1,1", "0,n", "1,n"];
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: link.cardinalities,
        isDense: true,
        style: TextStyle(
          fontSize: 10 * scale,
          color: ThemeColors.textMain(theme).withValues(alpha: 0.8),
        ),
        onChanged: (val) {
          if (val != null) {
            provider.updateLinkCardinality(link.entityId, link.relationId, val);
          }
        },
        items: cards
            .map(
              (c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: TextStyle(fontSize: 10 * scale)),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AttributeItem extends StatelessWidget {
  final McdAttribute attr;
  final int index;
  final String itemId;
  final AppTheme theme;
  final Color primaryColor;
  final double scale;
  final bool isMobile;

  const _AttributeItem({
    required this.attr,
    required this.index,
    required this.itemId,
    required this.theme,
    required this.primaryColor,
    required this.scale,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MeriseProvider>();
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 12),
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: isMobile ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: attr.isPrimaryKey
            ? (isDark ? primaryColor.withValues(alpha: 0.1) : Colors.grey[100])
            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50]),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: attr.isPrimaryKey
              ? primaryColor.withValues(alpha: 0.3)
              : (isMobile
                    ? (isDark ? Colors.white10 : Colors.grey[300]!)
                    : Colors.transparent),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              attr.isPrimaryKey ? Icons.key : Icons.key_off,
              size: (isMobile ? 22 : 20) * scale,
              color: attr.isPrimaryKey ? primaryColor : Colors.grey,
            ),
            onPressed: () => provider.toggleAttributePrimaryKey(itemId, index),
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            tooltip: "Clé Primaire",
          ),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: attr.name,
              onChanged: (val) =>
                  provider.updateAttributeName(itemId, index, val),
              style: TextStyle(
                fontSize: (isMobile ? 14 : 12) * scale,
                fontFamily: 'JetBrainsMono',
                color: ThemeColors.textMain(theme),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: "Nom",
                contentPadding: EdgeInsets.symmetric(
                  vertical: isMobile ? 8 : 0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: allowedTypes.contains(attr.type.toUpperCase())
                    ? attr.type.toUpperCase()
                    : 'CHAINE',
                isDense: true,
                isExpanded: true,
                iconSize: isMobile ? 24 : 20,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    provider.updateAttributeType(itemId, index, newValue);
                  }
                },
                style: TextStyle(
                  fontSize: (isMobile ? 12 : 10) * scale,
                  color: ThemeColors.textMain(theme).withValues(alpha: 0.7),
                ),
                items: allowedTypes.map<DropdownMenuItem<String>>((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(fontSize: (isMobile ? 12 : 10) * scale),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              size: (isMobile ? 22 : 20) * scale,
              color: Colors.red[300],
            ),
            onPressed: () => provider.deleteAttribute(itemId, index),
            padding: EdgeInsets.all(isMobile ? 10 : 12),
          ),
        ],
      ),
    );
  }
}
