import 'mcd_models.dart';

class MldColumn {
  final String name;
  final String type;
  final bool isPrimaryKey;
  final bool isForeignKey;
  /// Whether the column can be NULL in the generated schema.
  /// Defaults to true because Merise MLD is concept-level; constraints are derived from cardinalities.
  final bool isNullable;
  /// Whether the column should be UNIQUE (useful for enforcing 1:1).
  final bool isUnique;

  const MldColumn({
    required this.name,
    required this.type,
    this.isPrimaryKey = false,
    this.isForeignKey = false,
    this.isNullable = true,
    this.isUnique = false,
  });

  MldColumn copyWith({
    String? name,
    String? type,
    bool? isPrimaryKey,
    bool? isForeignKey,
    bool? isNullable,
    bool? isUnique,
  }) {
    return MldColumn(
      name: name ?? this.name,
      type: type ?? this.type,
      isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
      isForeignKey: isForeignKey ?? this.isForeignKey,
      isNullable: isNullable ?? this.isNullable,
      isUnique: isUnique ?? this.isUnique,
    );
  }
}

class MldForeignKey {
  final String columnName;
  final String referencedTable;
  final String referencedColumn;

  const MldForeignKey({
    required this.columnName,
    required this.referencedTable,
    required this.referencedColumn,
  });
}

class MldTable {
  final String name;
  final List<MldColumn> columns;
  final List<MldForeignKey> foreignKeys;

  const MldTable({
    required this.name,
    required this.columns,
    this.foreignKeys = const [],
  });
}

class Mld {
  final List<MldTable> tables;
  const Mld({required this.tables});
}

class MldTransformer {
  static _Card _parseCardinality(String raw) {
    // Expected formats: "0,1", "1,1", "0,n", "1,n" (case-insensitive on N)
    final s = raw.trim();
    final m = RegExp(r'^([01])\s*,\s*([1nN])$').firstMatch(s);
    if (m == null) return const _Card(min: 0, maxIsMany: true);
    final min = int.parse(m.group(1)!);
    final max = m.group(2)!;
    return _Card(min: min, maxIsMany: max.toLowerCase() == 'n');
  }

  static String _uniqueColumnName(Set<String> existing, String base) {
    var name = base;
    var i = 2;
    while (existing.contains(name)) {
      name = '${base}_$i';
      i++;
    }
    existing.add(name);
    return name;
  }

  static Mld transform(Mcd mcd) {
    final tables = <MldTable>[];

    // 1. Créer les tables pour chaque entité
    final entityTables = <String, MldTable>{};
    for (final entity in mcd.entities) {
      final columns = entity.attributes
          .map(
            (attr) => MldColumn(
              name: attr.name,
              type: attr.type,
              isPrimaryKey: attr.isPrimaryKey,
            ),
          )
          .toList();

      final table = MldTable(
        name: entity.name,
        columns: columns,
        foreignKeys: [],
      );
      entityTables[entity.id] = table;
    }

    // 2. Gérer les associations
    for (final relation in mcd.relations) {
      final links = mcd.links
          .where((l) => l.relationId == relation.id)
          .toList();

      if (links.isEmpty) continue;

      // Cas 1: Relation N-aire (3+ entités), Association avec attributs, ou N:N
      // Dans ces cas, on crée TOUJOURS une table d'association
      bool isNary = links.length > 2;
      bool hasAttributes = relation.attributes.isNotEmpty;

      // Déterminer s'il y a plus d'une patte avec une cardinalité max 'N'
      int maxNCount = links
          .where((l) => l.cardinalities.toLowerCase().endsWith('n'))
          .length;
      bool isManyToMany = maxNCount > 1;

      if (isNary || hasAttributes || isManyToMany) {
        final columns = <MldColumn>[];
        final fks = <MldForeignKey>[];
        final existingNames = <String>{};

        for (final link in links) {
          final targetEntity = mcd.entities.firstWhere(
            (e) => e.id == link.entityId,
          );
          final pkAttr = targetEntity.attributes.firstWhere(
            (a) => a.isPrimaryKey,
            orElse: () => targetEntity.attributes.first,
          );

          final colName = '${targetEntity.name.toLowerCase()}_${pkAttr.name}';
          final safeColName = _uniqueColumnName(existingNames, colName);
          columns.add(
            MldColumn(
              name: safeColName,
              type: pkAttr.type,
              isPrimaryKey: true,
              isForeignKey: true,
              isNullable: false,
            ),
          );

          fks.add(
            MldForeignKey(
              columnName: safeColName,
              referencedTable: targetEntity.name,
              referencedColumn: pkAttr.name,
            ),
          );
        }

        // Ajouter les attributs de la relation elle-même (Porteuse de données)
        for (final attr in relation.attributes) {
          final safeName = _uniqueColumnName(existingNames, attr.name);
          columns.add(MldColumn(name: safeName, type: attr.type));
        }

        tables.add(
          MldTable(name: relation.name, columns: columns, foreignKeys: fks),
        );
      }
      // Cas 2: Relation binaire 1:N (ou 1:1)
      else if (links.length == 2) {
        // Correct Merise→Relational mapping:
        // - For 1:N: the FK is placed on the N-side table referencing the 1-side table.
        // - For 1:1: place the FK on the mandatory side if any, else pick deterministically.
        final c1 = _parseCardinality(links[0].cardinalities);
        final c2 = _parseCardinality(links[1].cardinalities);

        final linkA = links[0];
        final linkB = links[1];

        late McdLink fkReceiverLink; // table that gets the FK column
        late McdLink referencedLink; // referenced table (provides PK)
        late bool fkIsUnique;
        late bool fkIsNullable;

        if (c1.maxIsMany != c2.maxIsMany) {
          // 1:N case
          fkReceiverLink = c1.maxIsMany ? linkA : linkB; // N-side
          referencedLink = c1.maxIsMany ? linkB : linkA; // 1-side
          fkIsUnique = false;
          fkIsNullable = _parseCardinality(fkReceiverLink.cardinalities).min == 0;
        } else {
          // 1:1 case (both max=1) or N:N (should have been caught earlier)
          // Enforce 1:1 with UNIQUE on the FK.
          fkIsUnique = true;

          // Prefer placing FK on the mandatory side (min=1) to preserve obligation.
          final aMin = c1.min;
          final bMin = c2.min;
          if (aMin != bMin) {
            fkReceiverLink = aMin == 1 ? linkA : linkB;
            referencedLink = aMin == 1 ? linkB : linkA;
          } else {
            // Deterministic fallback: receiver is the entity with lexicographically larger name
            // (stable and avoids random diffs).
            final ea = mcd.entities.firstWhere((e) => e.id == linkA.entityId);
            final eb = mcd.entities.firstWhere((e) => e.id == linkB.entityId);
            final receiverIsA = ea.name.toLowerCase().compareTo(eb.name.toLowerCase()) >= 0;
            fkReceiverLink = receiverIsA ? linkA : linkB;
            referencedLink = receiverIsA ? linkB : linkA;
          }
          fkIsNullable = _parseCardinality(fkReceiverLink.cardinalities).min == 0;
        }

        final fkReceiverEntity = mcd.entities.firstWhere(
          (e) => e.id == fkReceiverLink.entityId,
        );
        final referencedEntity = mcd.entities.firstWhere(
          (e) => e.id == referencedLink.entityId,
        );

        final referencedPK = referencedEntity.attributes.firstWhere(
          (a) => a.isPrimaryKey,
          orElse: () => referencedEntity.attributes.first,
        );

        final baseFkColumnName =
            '${referencedEntity.name.toLowerCase()}_${referencedPK.name}';

        // Mettre à jour la table receveuse de la FK
        final currentTable = entityTables[fkReceiverEntity.id]!;
        final existingNames = currentTable.columns.map((c) => c.name).toSet();
        final fkColumnName = _uniqueColumnName(existingNames, baseFkColumnName);

        final updatedColumns = List<MldColumn>.from(currentTable.columns)
          ..add(
            MldColumn(
              name: fkColumnName,
              type: referencedPK.type,
              isForeignKey: true,
              isNullable: fkIsNullable,
              isUnique: fkIsUnique,
            ),
          );

        final updatedFKs = List<MldForeignKey>.from(currentTable.foreignKeys)
          ..add(
            MldForeignKey(
              columnName: fkColumnName,
              referencedTable: referencedEntity.name,
              referencedColumn: referencedPK.name,
            ),
          );

        entityTables[fkReceiverEntity.id] = MldTable(
          name: currentTable.name,
          columns: updatedColumns,
          foreignKeys: updatedFKs,
        );
      }
    }

    tables.addAll(entityTables.values);
    return Mld(tables: tables);
  }
}

class _Card {
  final int min; // 0 or 1
  final bool maxIsMany; // true if 'n'
  const _Card({required this.min, required this.maxIsMany});
}
