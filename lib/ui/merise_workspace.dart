import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/merise_provider.dart';
import '../providers/file_provider.dart';
import '../providers/theme_provider.dart';
import '../theme.dart';
import '../merise/mcd_models.dart';

class MeriseWorkspace extends StatefulWidget {
  const MeriseWorkspace({super.key});

  @override
  State<MeriseWorkspace> createState() => _MeriseWorkspaceState();
}

class _MeriseWorkspaceState extends State<MeriseWorkspace> {
  // Zoom is now handled by MeriseProvider

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final meriseProvider = context.watch<MeriseProvider>();
    final theme = themeProvider.currentTheme;
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;

    final primaryColor = const Color(0xFFFF9900);
    final bgColor = isDark ? const Color(0xFF231B0F) : const Color(0xFFF8F7F5);
    final borderColor = isDark
        ? const Color(0xFF3D3324)
        : const Color(0xFFE7E2DA);
    final surfaceColor = isDark ? const Color(0xFF1C160C) : Colors.white;

    final isWorkspaceMobile = MediaQuery.of(context).size.width < 900;

    // decide which view to show
    if (meriseProvider.activeView == 'mcd') {
      return Container(
        color: bgColor,
        child: KeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          autofocus: true,
          onKeyEvent: (event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.delete) {
              meriseProvider.deleteSelectedItems();
            }
          },
          child: Stack(
            children: [
              Column(
                children: [
                  // Local Header removed (handled by BarreHaut)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, workspaceConstraints) {
                        final isWorkspaceMobile =
                            workspaceConstraints.maxWidth < 900;

                        return Row(
                          children: [
                            // Mini sidebar
                            if (!isWorkspaceMobile)
                              _buildMiniSidebar(
                                isDark,
                                borderColor,
                                surfaceColor,
                                primaryColor,
                                meriseProvider,
                              ),
                            // Main Workspace
                            Expanded(
                              flex: 70,
                              child: ClipRect(
                                child: _MeriseCanvas(
                                  zoom: meriseProvider.zoom,
                                  isDark: isDark,
                                  primaryColor: primaryColor,
                                ),
                              ),
                            ),
                            // Properties Panel
                            if (!isWorkspaceMobile)
                              _buildPropertiesPanel(
                                isDark,
                                borderColor,
                                surfaceColor,
                                primaryColor,
                                meriseProvider,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  // Footer status bar
                  _buildFooter(
                    isDark,
                    borderColor,
                    surfaceColor,
                    meriseProvider,
                  ),
                ],
              ),
              // Floating Action Buttons
              Positioned(
                right: isWorkspaceMobile ? 20 : 380,
                bottom: 60,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isWorkspaceMobile &&
                        meriseProvider.selectedItem != null) ...[
                      FloatingActionButton(
                        heroTag: 'showProperties',
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => _buildPropertiesPanel(
                              isDark,
                              borderColor,
                              surfaceColor,
                              primaryColor,
                              meriseProvider,
                            ),
                          );
                        },
                        backgroundColor: Colors.blueAccent,
                        tooltip: 'Propriétés',
                        child: const Icon(Icons.tune, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (isWorkspaceMobile) ...[
                      FloatingActionButton(
                        heroTag: 'showTools',
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => _buildMiniSidebar(
                              isDark,
                              borderColor,
                              surfaceColor,
                              primaryColor,
                              meriseProvider,
                            ),
                          );
                        },
                        backgroundColor: Colors.grey,
                        tooltip: 'Outils',
                        child: const Icon(Icons.build, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FloatingActionButton(
                      heroTag: 'createEntity',
                      onPressed: () {
                        meriseProvider.createEntity(const Offset(400, 300));
                      },
                      backgroundColor: primaryColor,
                      tooltip: 'Créer une entité',
                      child: const Icon(Icons.add_box, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton(
                      heroTag: 'createRelation',
                      onPressed: () {
                        meriseProvider.createRelation(const Offset(500, 300));
                      },
                      backgroundColor: primaryColor.withValues(alpha: 0.8),
                      tooltip: 'Créer une relation',
                      child: const Icon(Icons.hub, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return _buildViewPlaceholder(meriseProvider.activeView, isDark);
    }
  }

  Widget _buildViewPlaceholder(String viewId, bool isDark) {
    String title = "Vue inconnue";
    IconData icon = Icons.help;

    switch (viewId) {
      case 'accueil':
        title = "Accueil Merise";
        icon = Icons.home;
        break;
      case 'etude':
        title = "Étude de l’existant";
        icon = Icons.article;
        break;
      case 'regles':
        title = "Règles de gestion";
        icon = Icons.gavel;
        break;
      case 'dictionnaire':
        title = "Dictionnaire de données";
        icon = Icons.menu_book;
        break;
      case 'mld':
        title = "Modèle Logique de Données (MLD)";
        icon = Icons.table_chart;
        break;
      case 'mpd':
        title = "Modèle Physique de Données (MPD)";
        icon = Icons.storage;
        break;
      case 'normalisation':
        title = "Normalisation";
        icon = Icons.check_circle;
        break;
      case 'requetes':
        title = "Requêtes & Jointures";
        icon = Icons.query_stats;
        break;
      case 'simulation':
        title = "Simulation";
        icon = Icons.play_arrow;
        break;
      case 'generation':
        title = "Génération";
        icon = Icons.code;
        break;
      case 'validation':
        title = "Validation";
        icon = Icons.fact_check;
        break;
      case 'parametres':
        title = "Paramètres du projet";
        icon = Icons.settings;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Module en cours de construction",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSidebar(
    bool isDark,
    Color borderColor,
    Color surfaceColor,
    Color primaryColor,
    MeriseProvider provider,
  ) {
    final fileProvider = context.watch<FileProvider>();
    final isWorkspaceMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      width: isWorkspaceMobile ? null : 200,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              "OUTILS MERISE",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _SidebarIcon(Icons.schema, "MCD", true, primaryColor, isDark),
          _SidebarIcon(
            Icons.data_object,
            "Dictionnaire",
            false,
            primaryColor,
            isDark,
          ),
          _SidebarIcon(
            Icons.history,
            "Historique",
            false,
            primaryColor,
            isDark,
          ),
          const Divider(height: 32, indent: 12, endIndent: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              "FICHIERS OUVERTS",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: fileProvider.openFiles.length,
              itemBuilder: (context, index) {
                final file = fileProvider.openFiles[index];
                final isActive = index == fileProvider.activeTabIndex;
                return InkWell(
                  onTap: () => fileProvider.setActiveTab(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color: isActive
                        ? primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    child: Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 14,
                          color: isActive
                              ? primaryColor
                              : (isDark ? Colors.white54 : Colors.black54),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            file.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isActive
                                  ? (isDark ? Colors.white : Colors.black)
                                  : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isActive)
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          _SidebarIcon(
            Icons.settings,
            "Paramètres",
            false,
            primaryColor,
            isDark,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPropertiesPanel(
    bool isDark,
    Color borderColor,
    Color surfaceColor,
    Color primaryColor,
    MeriseProvider meriseProvider,
  ) {
    final panelBg = isDark ? surfaceColor : Colors.white;
    final selectedItem = meriseProvider.selectedItem;
    final isWorkspaceMobile = MediaQuery.of(context).size.width < 900;

    // Check if an entity is selected
    McdEntity? selectedEntity;
    McdRelation? selectedRelation;

    if (selectedItem is McdEntity) {
      selectedEntity = selectedItem;
    } else if (selectedItem is McdRelation) {
      selectedRelation = selectedItem;
    }

    // If nothing is selected
    if (selectedEntity == null && selectedRelation == null) {
      return Container(
        width: isWorkspaceMobile ? null : 320,
        decoration: BoxDecoration(
          color: panelBg,
          border: Border(left: BorderSide(color: borderColor)),
        ),
        child: Center(
          child: Text(
            "Sélectionnez une entité ou relation pour éditer",
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // If a relation is selected
    if (selectedRelation != null) {
      return RelationPropertiesPanel(
        key: ValueKey(selectedRelation.id),
        relation: selectedRelation,
        isDark: isDark,
        borderColor: borderColor,
        surfaceColor: surfaceColor,
        primaryColor: primaryColor,
        provider: meriseProvider,
        isMobile: isWorkspaceMobile,
      );
    }

    // If an entity is selected
    return EntityPropertiesPanel(
      key: ValueKey(selectedEntity!.id),
      entity: selectedEntity,
      isDark: isDark,
      borderColor: borderColor,
      surfaceColor: surfaceColor,
      primaryColor: primaryColor,
      provider: meriseProvider,
      isMobile: isWorkspaceMobile,
    );
  }
} // End of _MeriseWorkspaceState

class EntityPropertiesPanel extends StatefulWidget {
  final McdEntity entity;
  final bool isDark;
  final Color borderColor;
  final Color surfaceColor;
  final Color primaryColor;
  final MeriseProvider provider;

  final bool isMobile;

  const EntityPropertiesPanel({
    super.key,
    required this.entity,
    required this.isDark,
    required this.borderColor,
    required this.surfaceColor,
    required this.primaryColor,
    required this.provider,
    this.isMobile = false,
  });

  @override
  State<EntityPropertiesPanel> createState() => _EntityPropertiesPanelState();
}

class _EntityPropertiesPanelState extends State<EntityPropertiesPanel> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entity.name);
  }

  @override
  void didUpdateWidget(covariant EntityPropertiesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entity.id != oldWidget.entity.id) {
      _nameController.text = widget.entity.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panelBg = widget.isDark ? widget.surfaceColor : Colors.white;

    return Container(
      width: widget.isMobile ? null : 320,
      decoration: BoxDecoration(
        color: panelBg,
        border: widget.isMobile
            ? null
            : Border(left: BorderSide(color: widget.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? const Color(0xFF231B0F).withValues(alpha: 0.5)
                  : const Color(0xFFF8F7F5).withValues(alpha: 0.5),
              border: Border(bottom: BorderSide(color: widget.borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.settings_input_component,
                      color: widget.primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? Colors.white : Colors.black,
                        ),
                        children: [
                          const TextSpan(text: "PROPRIÉTÉS: "),
                          TextSpan(
                            text: widget.entity.name,
                            style: TextStyle(color: widget.primaryColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Colors.red.withValues(alpha: 0.7),
                    size: 18,
                  ),
                  onPressed: () {
                    widget.provider.deleteEntity(widget.entity.id);
                  },
                  tooltip: 'Supprimer l\'entité',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  "Nom de l'entité",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  onChanged: (val) {
                    widget.provider.updateEntityName(widget.entity.id, val);
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: widget.isDark
                        ? const Color(0xFF2D2417)
                        : Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: widget.borderColor),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Attributs",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        widget.provider.addAttribute(widget.entity.id);
                      },
                      icon: Icon(
                        Icons.add_circle,
                        color: widget.primaryColor,
                        size: 14,
                      ),
                      label: Text(
                        "Ajouter",
                        style: TextStyle(
                          color: widget.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...widget.entity.attributes.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: AttributeRow(
                      key: ValueKey(
                        '${widget.entity.id}_${entry.key}_${entry.value.name}',
                      ), // Unique Key
                      entityId: widget.entity.id,
                      attrIndex: entry.key,
                      attribute: entry.value,
                      isDark: widget.isDark,
                      borderColor: widget.borderColor,
                      primaryColor: widget.primaryColor,
                      provider: widget.provider,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _PedagogicalCorner(widget.isDark, widget.primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RelationPropertiesPanel extends StatefulWidget {
  final McdRelation relation;
  final bool isDark;
  final Color borderColor;
  final Color surfaceColor;
  final Color primaryColor;
  final MeriseProvider provider;

  final bool isMobile;

  const RelationPropertiesPanel({
    super.key,
    required this.relation,
    required this.isDark,
    required this.borderColor,
    required this.surfaceColor,
    required this.primaryColor,
    required this.provider,
    this.isMobile = false,
  });

  @override
  State<RelationPropertiesPanel> createState() =>
      _RelationPropertiesPanelState();
}

class _RelationPropertiesPanelState extends State<RelationPropertiesPanel> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.relation.name);
  }

  @override
  void didUpdateWidget(covariant RelationPropertiesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.relation.id != oldWidget.relation.id) {
      _nameController.text = widget.relation.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panelBg = widget.isDark ? widget.surfaceColor : Colors.white;

    // Trouver les liens associés à cette relation
    final relatedLinks = widget.provider.links
        .where((link) => link.relationId == widget.relation.id)
        .toList();

    return Container(
      width: widget.isMobile ? null : 320,
      decoration: BoxDecoration(
        color: panelBg,
        border: widget.isMobile
            ? null
            : Border(left: BorderSide(color: widget.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? const Color(0xFF231B0F).withValues(alpha: 0.5)
                  : const Color(0xFFF8F7F5).withValues(alpha: 0.5),
              border: Border(bottom: BorderSide(color: widget.borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.hub, color: widget.primaryColor, size: 18),
                    const SizedBox(width: 8),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? Colors.white : Colors.black,
                        ),
                        children: [
                          const TextSpan(text: "RELATION: "),
                          TextSpan(
                            text: widget.relation.name,
                            style: TextStyle(color: widget.primaryColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Colors.red.withValues(alpha: 0.7),
                    size: 18,
                  ),
                  onPressed: () {
                    widget.provider.deleteRelation(widget.relation.id);
                  },
                  tooltip: 'Supprimer la relation',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  "Nom de la relation",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  onChanged: (val) {
                    widget.provider.updateRelationName(widget.relation.id, val);
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: widget.isDark
                        ? const Color(0xFF2D2417)
                        : Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: widget.borderColor),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Liens avec entités",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.add_circle,
                        color: widget.primaryColor,
                        size: 18,
                      ),
                      tooltip: 'Ajouter un lien',
                      onSelected: (entityId) {
                        widget.provider.createLink(
                          entityId,
                          widget.relation.id,
                        );
                      },
                      itemBuilder: (context) {
                        return widget.provider.entities.map((entity) {
                          // Vérifier si le lien existe déjà
                          final linkExists = relatedLinks.any(
                            (link) => link.entityId == entity.id,
                          );
                          return PopupMenuItem<String>(
                            value: entity.id,
                            enabled: !linkExists,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add_box,
                                  size: 16,
                                  color: linkExists
                                      ? Colors.grey
                                      : widget.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  entity.name,
                                  style: TextStyle(
                                    color: linkExists ? Colors.grey : null,
                                  ),
                                ),
                                if (linkExists)
                                  const Text(
                                    ' (déjà lié)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...relatedLinks.map((link) {
                  final entity = widget.provider.entities.firstWhere(
                    (e) => e.id == link.entityId,
                    orElse: () => McdEntity(
                      id: '',
                      name: 'Inconnu',
                      position: Offset.zero,
                      attributes: [],
                    ),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _LinkRow(
                      entityName: entity.name,
                      cardinality: link.cardinalities,
                      isDark: widget.isDark,
                      borderColor: widget.borderColor,
                      primaryColor: widget.primaryColor,
                      onCardinalityChanged: (newCard) {
                        widget.provider.updateLinkCardinality(
                          link.entityId,
                          link.relationId,
                          newCard,
                        );
                      },
                      onDelete: () {
                        widget.provider.deleteLink(
                          link.entityId,
                          link.relationId,
                        );
                      },
                    ),
                  );
                }),
                if (relatedLinks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      "Aucun lien. Cliquez sur + pour ajouter.",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildFooter(
  bool isDark,
  Color borderColor,
  Color surfaceColor,
  MeriseProvider provider,
) {
  return Container(
    height: 32,
    decoration: BoxDecoration(
      color: surfaceColor,
      border: Border(top: BorderSide(color: borderColor)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _FooterItem("Entités: ${provider.entities.length}"),
            const SizedBox(width: 16),
            _FooterItem("Associations: ${provider.relations.length}"),
            const SizedBox(width: 16),
            _FooterItem("Zoom: ${(100 * provider.zoom).toInt()}%"),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.cloud_done, color: Colors.green, size: 14),
            const SizedBox(width: 4),
            Text(
              "Sauvegardé",
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _FooterItem(String text) {
  return Text(
    text,
    style: const TextStyle(
      fontSize: 10,
      color: Colors.grey,
      fontWeight: FontWeight.w500,
    ),
  );
}

Future<void> _showRenameDialog(
  BuildContext context,
  String title,
  String initialValue,
  Function(String) onSave,
) async {
  final controller = TextEditingController(text: initialValue);
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextFormField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: "Nouveau nom",
        ),
        onFieldSubmitted: (val) {
          if (val.trim().isNotEmpty) {
            onSave(val.trim());
            Navigator.pop(context);
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              onSave(controller.text.trim());
              Navigator.pop(context);
            }
          },
          child: const Text("Sauvegarder"),
        ),
      ],
    ),
  );
}

class _MeriseCanvas extends StatelessWidget {
  final double zoom;
  final bool isDark;
  final Color primaryColor;
  const _MeriseCanvas({
    required this.zoom,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final meriseProvider = context.watch<MeriseProvider>();

    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: 0.3,
      maxScale: 3.0,
      constrained: false,
      child: SizedBox(
        width: 3000,
        height: 3000,
        child: CustomPaint(
          painter: _MeriseGridPainter(isDark: isDark),
          child: Stack(
            children: [
              // Connections Layer (Lowest z-index)
              Positioned.fill(
                child: CustomPaint(
                  painter: _MeriseLinksPainter(
                    isDark: isDark,
                    primaryColor: primaryColor,
                    provider: meriseProvider,
                  ),
                ),
              ),

              // Relations Layer
              ...meriseProvider.relations.map((rel) {
                return Positioned(
                  left: rel.position.dx,
                  top: rel.position.dy,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      meriseProvider.updateRelationPosition(
                        rel.id,
                        rel.position + details.delta,
                      );
                    },
                    onTap: () => meriseProvider.selectItem(rel),
                    onDoubleTap: () {
                      _showRenameDialog(
                        context,
                        "Renommer la relation",
                        rel.name,
                        (newName) {
                          meriseProvider.updateRelationName(rel.id, newName);
                        },
                      );
                    },
                    child: _RelationWidget(
                      relation: rel,
                      isDark: isDark,
                      primaryColor: primaryColor,
                      isSelected: meriseProvider.selectedItem == rel,
                    ),
                  ),
                );
              }),

              // Entities Layer
              ...meriseProvider.entities.map((entity) {
                return Positioned(
                  left: entity.position.dx,
                  top: entity.position.dy,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      meriseProvider.updateEntityPosition(
                        entity.id,
                        entity.position + details.delta,
                      );
                    },
                    onTap: () => meriseProvider.selectItem(entity),
                    child: _EntityBox(
                      entity: entity,
                      isDark: isDark,
                      primaryColor: primaryColor,
                      isSelected: meriseProvider.selectedItem == entity,
                      onHeaderDoubleTap: () {
                        _showRenameDialog(
                          context,
                          "Renommer l'entité",
                          entity.name,
                          (newName) {
                            meriseProvider.updateEntityName(entity.id, newName);
                          },
                        );
                      },
                      onAttributeDoubleTap: (index) {
                        _showRenameDialog(
                          context,
                          "Renommer l'attribut",
                          entity.attributes[index].name,
                          (newName) {
                            meriseProvider.updateAttributeName(
                              entity.id,
                              index,
                              newName,
                            );
                          },
                        );
                      },
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeriseGridPainter extends CustomPainter {
  final bool isDark;
  _MeriseGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final dotColor = isDark ? const Color(0xFF4B3F2F) : const Color(0xFFD1D5DB);
    final paint = Paint()
      ..color = dotColor
      ..strokeWidth = 1.0;

    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MeriseLinksPainter extends CustomPainter {
  final bool isDark;
  final Color primaryColor;
  final MeriseProvider provider;

  _MeriseLinksPainter({
    required this.isDark,
    required this.primaryColor,
    required this.provider,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeColor = isDark
        ? const Color(0xFFF8F7F5)
        : const Color(0xFF181510);
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // dashedPaint removed as it was unused and caused lint warnings

    for (var link in provider.links) {
      final entity = provider.entities.firstWhere(
        (e) => e.id == link.entityId,
        orElse: () =>
            McdEntity(id: '', name: '', position: Offset.zero, attributes: []),
      );
      final relation = provider.relations.firstWhere(
        (r) => r.id == link.relationId,
        orElse: () => McdRelation(id: '', name: '', position: Offset.zero),
      );

      if (entity.id.isNotEmpty && relation.id.isNotEmpty) {
        // Calculate centers more accurately
        final entityCenter = entity.position + const Offset(75, 40);
        final relationCenter = relation.position + const Offset(40, 40);

        // Draw the line
        canvas.drawLine(entityCenter, relationCenter, paint);

        // Calculate position for cardinality (closer to entity)
        final dx = relationCenter.dx - entityCenter.dx;
        final dy = relationCenter.dy - entityCenter.dy;

        // Position cardinality at 25% from entity (closer to entity)
        final cardPos = Offset(
          entityCenter.dx + dx * 0.25,
          entityCenter.dy + dy * 0.25,
        );

        // Draw cardinality with background
        _drawCardinalityLabel(
          canvas,
          link.cardinalities,
          cardPos,
          primaryColor,
        );
      }
    }
  }

  void _drawCardinalityLabel(
    Canvas canvas,
    String label,
    Offset pos,
    Color color,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'JetBrainsMono',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Draw background box
    final bgRect = Rect.fromCenter(
      center: pos,
      width: textPainter.width + 12,
      height: textPainter.height + 8,
    );

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      bgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      borderPaint,
    );

    // Draw text
    final textPos = Offset(
      pos.dx - textPainter.width / 2,
      pos.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textPos);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RelationWidget extends StatelessWidget {
  final McdRelation relation;
  final bool isDark;
  final Color primaryColor;
  final bool isSelected;

  const _RelationWidget({
    required this.relation,
    required this.isDark,
    required this.primaryColor,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final strokeColor = isDark
        ? const Color(0xFFF8F7F5)
        : const Color(0xFF181510);
    return Container(
      padding: const EdgeInsets.all(8), // HIT AREA
      child: CustomPaint(
        painter: _RelationPainter(
          label: relation.name,
          isDark: isDark,
          strokeColor: isSelected ? primaryColor : strokeColor,
        ),
        size: const Size(40, 40),
      ),
    );
  }
}

class _RelationPainter extends CustomPainter {
  final String label;
  final bool isDark;
  final Color strokeColor;

  _RelationPainter({
    required this.label,
    required this.isDark,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF2D2417) : Colors.white;
    final borderPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, 18, bgPaint);
    canvas.drawCircle(center, 18, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: strokeColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _EntityBox extends StatelessWidget {
  final McdEntity entity;
  final bool isDark;
  final Color primaryColor;
  final bool isSelected;
  final VoidCallback onHeaderDoubleTap;
  final Function(int) onAttributeDoubleTap;

  const _EntityBox({
    required this.entity,
    required this.isDark,
    required this.primaryColor,
    required this.isSelected,
    required this.onHeaderDoubleTap,
    required this.onAttributeDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? primaryColor
        : (isDark ? const Color(0xFFF8F7F5) : const Color(0xFF181510));
    final headerBg = isSelected
        ? primaryColor.withValues(alpha: 0.2)
        : (isDark ? const Color(0xFF3D3324) : const Color(0xFFF5F5F5));

    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2417) : Colors.white,
        border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onDoubleTap: onHeaderDoubleTap,
                    child: Text(
                      entity.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Icon(
                  Icons.drag_indicator,
                  size: 10,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entity.attributes.asMap().entries.map((entry) {
                final index = entry.key;
                final attr = entry.value;
                return GestureDetector(
                  onDoubleTap: () => onAttributeDoubleTap(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        if (attr.isPrimaryKey)
                          Icon(Icons.key, size: 8, color: primaryColor),
                        if (attr.isPrimaryKey) const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            attr.name,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white70 : Colors.black87,
                              decoration: attr.isPrimaryKey
                                  ? TextDecoration.underline
                                  : null,
                              decorationStyle: TextDecorationStyle.dashed,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _IconBtn(this.icon, this.isDark, this.onTap);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 20,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
      splashRadius: 20,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _ActionButton(this.icon, this.label, this.isDark, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark
            ? const Color(0xFF2D2417)
            : const Color(0xFFF5F3F0),
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        minimumSize: const Size(0, 40),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PrimaryButton(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        minimumSize: const Size(0, 40),
      ),
    );
  }
}

class _SidebarIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color primaryColor;
  final bool isDark;

  const _SidebarIcon(
    this.icon,
    this.label,
    this.active,
    this.primaryColor,
    this.isDark,
  );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: active
              ? Border(left: BorderSide(color: primaryColor, width: 3))
              : null,
          color: active ? primaryColor.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: active
                  ? primaryColor
                  : (isDark ? Colors.white54 : Colors.black54),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: active
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AttributeRow extends StatefulWidget {
  final String entityId;
  final int attrIndex;
  final McdAttribute attribute;
  final bool isDark;
  final Color borderColor;
  final Color primaryColor;
  final MeriseProvider provider;

  const AttributeRow({
    super.key,
    required this.entityId,
    required this.attrIndex,
    required this.attribute,
    required this.isDark,
    required this.borderColor,
    required this.primaryColor,
    required this.provider,
  });

  @override
  State<AttributeRow> createState() => _AttributeRowState();
}

class _AttributeRowState extends State<AttributeRow> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.attribute.name);
  }

  @override
  void didUpdateWidget(covariant AttributeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.attribute.name != _nameController.text) {
      final selection = _nameController.selection;
      _nameController.text = widget.attribute.name;
      if (selection.baseOffset <= widget.attribute.name.length &&
          selection.extentOffset <= widget.attribute.name.length) {
        _nameController.selection = selection;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: widget.attribute.isPrimaryKey
            ? (widget.isDark
                  ? const Color(0xFF2D2417)
                  : const Color(0xFFF5F3F0))
            : (widget.isDark ? const Color(0xFF1C160C) : Colors.white),
        border: Border.all(color: widget.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Primary Key Toggle
          InkWell(
            onTap: () {
              widget.provider.toggleAttributePrimaryKey(
                widget.entityId,
                widget.attrIndex,
              );
            },
            child: Icon(
              widget.attribute.isPrimaryKey ? Icons.key : Icons.key_off,
              size: 14,
              color: widget.attribute.isPrimaryKey
                  ? widget.primaryColor
                  : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 8),
          // Attribute Name (Editable)
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: _nameController,
              onChanged: (val) {
                widget.provider.updateAttributeName(
                  widget.entityId,
                  widget.attrIndex,
                  val,
                );
              },
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'JetBrainsMono',
                color: widget.isDark ? Colors.white : Colors.black,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Type Selector
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: widget.attribute.type,
              isDense: true,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: 11,
                color: widget.isDark ? Colors.white70 : Colors.black87,
              ),
              dropdownColor: widget.isDark
                  ? const Color(0xFF2D2417)
                  : Colors.white,
              items: ['String', 'Entier', 'Reel', 'Date', 'Booleen']
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  widget.provider.updateAttributeType(
                    widget.entityId,
                    widget.attrIndex,
                    val,
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          // Delete Button
          InkWell(
            onTap: () {
              widget.provider.deleteAttribute(
                widget.entityId,
                widget.attrIndex,
              );
            },
            child: Icon(
              Icons.delete_outline,
              size: 14,
              color: Colors.red.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

class _PedagogicalCorner extends StatelessWidget {
  final bool isDark;
  final Color primaryColor;
  const _PedagogicalCorner(this.isDark, this.primaryColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.school, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                "COIN PÉDAGOGIQUE",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Comprendre les Cardinalités",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'La cardinalité "1,n" entre CLIENT et COMMANDE indique qu\'un client doit avoir au moins une commande pour être dans notre système, et peut en avoir plusieurs.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Text(
            "Astuce : Une cardinalité minimale \"1\" implique une existence obligatoire.",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String entityName;
  final String cardinality;
  final bool isDark;
  final Color borderColor;
  final Color primaryColor;
  final Function(String) onCardinalityChanged;
  final VoidCallback onDelete;

  const _LinkRow({
    required this.entityName,
    required this.cardinality,
    required this.isDark,
    required this.borderColor,
    required this.primaryColor,
    required this.onCardinalityChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C160C) : Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.link, size: 16, color: primaryColor),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              entityName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: cardinality,
              isDense: true,
              decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: borderColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
              dropdownColor: isDark ? const Color(0xFF2D2417) : Colors.white,
              items: ['0,1', '1,1', '0,n', '1,n']
                  .map(
                    (card) => DropdownMenuItem(value: card, child: Text(card)),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  onCardinalityChanged(val);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onDelete,
            child: Icon(
              Icons.delete_outline,
              size: 16,
              color: Colors.red.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
