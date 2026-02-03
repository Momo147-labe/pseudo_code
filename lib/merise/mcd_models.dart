import 'package:flutter/material.dart';

class McdAttribute {
  final String name;
  final String type;
  final bool isPrimaryKey;
  final String description;
  final String length;
  final String constraints;
  final String rules;
  final Map<String, String>? _customFields;
  Map<String, String> get customFields => _customFields ?? const {};

  const McdAttribute({
    required this.name,
    this.type = 'CHAINE',
    this.isPrimaryKey = false,
    this.description = '',
    this.length = '',
    this.constraints = '',
    this.rules = '',
    Map<String, String>? customFields,
  }) : _customFields = customFields;

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'isPrimaryKey': isPrimaryKey,
    'description': description,
    'length': length,
    'constraints': constraints,
    'rules': rules,
    'customFields': customFields,
  };

  factory McdAttribute.fromJson(Map<String, dynamic> json) => McdAttribute(
    name: json['name'] as String? ?? 'Attribut',
    type: json['type'] as String? ?? 'CHAINE',
    isPrimaryKey: json['isPrimaryKey'] as bool? ?? false,
    description: json['description'] as String? ?? '',
    length: json['length'] as String? ?? '',
    constraints: json['constraints'] as String? ?? '',
    rules: json['rules'] as String? ?? '',
    customFields: json['customFields'] != null
        ? Map<String, String>.from(json['customFields'] as Map)
        : null,
  );

  McdAttribute copyWith({
    String? name,
    String? type,
    bool? isPrimaryKey,
    String? description,
    String? length,
    String? constraints,
    String? rules,
    Map<String, String>? customFields,
  }) => McdAttribute(
    name: name ?? this.name,
    type: type ?? this.type,
    isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
    description: description ?? this.description,
    length: length ?? this.length,
    constraints: constraints ?? this.constraints,
    rules: rules ?? this.rules,
    customFields: customFields ?? this._customFields,
  );
}

class McdEntity {
  final String id;
  final String name;
  final Offset position;
  final List<McdAttribute> attributes;

  const McdEntity({
    required this.id,
    required this.name,
    required this.position,
    required this.attributes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'position': {'dx': position.dx, 'dy': position.dy},
    'attributes': attributes.map((a) => a.toJson()).toList(),
  };

  factory McdEntity.fromJson(Map<String, dynamic> json) {
    final String id =
        json['id'] as String? ?? 'e${DateTime.now().microsecondsSinceEpoch}';
    final String name = json['name'] as String? ?? 'Entité';

    Offset pos = Offset.zero;
    if (json['position'] != null && json['position'] is Map) {
      final p = json['position'] as Map;
      pos = Offset(
        (p['dx'] as num? ?? 0).toDouble(),
        (p['dy'] as num? ?? 0).toDouble(),
      );
    }

    final List<McdAttribute> attrs = [];
    if (json['attributes'] != null && json['attributes'] is List) {
      for (final a in (json['attributes'] as List)) {
        if (a is Map<String, dynamic>) {
          attrs.add(McdAttribute.fromJson(a));
        }
      }
    }

    return McdEntity(id: id, name: name, position: pos, attributes: attrs);
  }

  McdEntity copyWith({
    String? id,
    String? name,
    Offset? position,
    List<McdAttribute>? attributes,
  }) => McdEntity(
    id: id ?? this.id,
    name: name ?? this.name,
    position: position ?? this.position,
    attributes: attributes ?? this.attributes,
  );
}

class McdRelation {
  final String id;
  final String name;
  final Offset position;
  final List<McdAttribute> attributes;

  const McdRelation({
    required this.id,
    required this.name,
    required this.position,
    this.attributes = const <McdAttribute>[],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'position': {'dx': position.dx, 'dy': position.dy},
    'attributes': attributes.map((a) => a.toJson()).toList(),
  };

  factory McdRelation.fromJson(Map<String, dynamic> json) {
    // Robust parsing with defaults
    final String id =
        json['id'] as String? ?? 'r${DateTime.now().millisecondsSinceEpoch}';
    final String name = json['name'] as String? ?? 'Relation';

    Offset pos = Offset.zero;
    if (json['position'] != null && json['position'] is Map) {
      final p = json['position'] as Map;
      pos = Offset(
        (p['dx'] as num? ?? 0).toDouble(),
        (p['dy'] as num? ?? 0).toDouble(),
      );
    }

    final List<McdAttribute> attrs = [];
    if (json['attributes'] != null && json['attributes'] is List) {
      for (final a in (json['attributes'] as List)) {
        if (a is Map<String, dynamic>) {
          attrs.add(McdAttribute.fromJson(a));
        }
      }
    }

    return McdRelation(id: id, name: name, position: pos, attributes: attrs);
  }

  McdRelation copyWith({
    String? id,
    String? name,
    Offset? position,
    List<McdAttribute>? attributes,
  }) => McdRelation(
    id: id ?? this.id,
    name: name ?? this.name,
    position: position ?? this.position,
    attributes: attributes ?? this.attributes,
  );
}

class McdLink {
  final String entityId;
  final String relationId;
  final String cardinalities;

  const McdLink({
    required this.entityId,
    required this.relationId,
    this.cardinalities = "1,n",
  });

  Map<String, dynamic> toJson() => {
    'entityId': entityId,
    'relationId': relationId,
    'cardinalities': cardinalities,
  };

  factory McdLink.fromJson(Map<String, dynamic> json) => McdLink(
    entityId: json['entityId'] as String? ?? '',
    relationId: json['relationId'] as String? ?? '',
    cardinalities: json['cardinalities'] as String? ?? '1,n',
  );

  McdLink copyWith({
    String? entityId,
    String? relationId,
    String? cardinalities,
  }) => McdLink(
    entityId: entityId ?? this.entityId,
    relationId: relationId ?? this.relationId,
    cardinalities: cardinalities ?? this.cardinalities,
  );
}

class McdFunctionalDependency {
  final String id;
  final List<String> sourceAttributes;
  final List<String> targetAttributes;

  const McdFunctionalDependency({
    required this.id,
    required this.sourceAttributes,
    required this.targetAttributes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceAttributes': sourceAttributes,
    'targetAttributes': targetAttributes,
  };

  factory McdFunctionalDependency.fromJson(
    Map<String, dynamic> json,
  ) => McdFunctionalDependency(
    id: json['id'] as String? ?? 'df${DateTime.now().millisecondsSinceEpoch}',
    sourceAttributes: List<String>.from(json['sourceAttributes'] ?? []),
    targetAttributes: List<String>.from(json['targetAttributes'] ?? []),
  );

  McdFunctionalDependency copyWith({
    String? id,
    List<String>? sourceAttributes,
    List<String>? targetAttributes,
  }) => McdFunctionalDependency(
    id: id ?? this.id,
    sourceAttributes: sourceAttributes ?? this.sourceAttributes,
    targetAttributes: targetAttributes ?? this.targetAttributes,
  );
}

class Mcd {
  final List<McdEntity> entities;
  final List<McdRelation> relations;
  final List<McdLink> links;
  final List<McdFunctionalDependency> functionalDependencies;

  const Mcd({
    required this.entities,
    required this.relations,
    required this.links,
    this.functionalDependencies = const [],
  });

  Map<String, dynamic> toJson() => {
    'entities': entities.map((e) => e.toJson()).toList(),
    'relations': relations.map((r) => r.toJson()).toList(),
    'links': links.map((l) => l.toJson()).toList(),
    'functionalDependencies': functionalDependencies
        .map((df) => df.toJson())
        .toList(),
  };

  factory Mcd.fromJson(Map<String, dynamic> json) => Mcd(
    entities: (json['entities'] as List? ?? [])
        .map((e) => McdEntity.fromJson(e as Map<String, dynamic>))
        .toList(),
    relations: (json['relations'] as List? ?? [])
        .map((r) => McdRelation.fromJson(r as Map<String, dynamic>))
        .toList(),
    links: (json['links'] as List? ?? [])
        .map((l) => McdLink.fromJson(l as Map<String, dynamic>))
        .toList(),
    functionalDependencies: (json['functionalDependencies'] as List? ?? [])
        .map(
          (df) => McdFunctionalDependency.fromJson(df as Map<String, dynamic>),
        )
        .toList(),
  );
}
