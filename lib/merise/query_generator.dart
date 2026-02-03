import 'mld_transformer.dart';
import 'mpd_generator.dart';
import 'sql_utils.dart';

class MeriseQuery {
  final String title;
  final String description;
  final String sql;

  const MeriseQuery({
    required this.title,
    required this.description,
    required this.sql,
  });
}

class QueryGenerator {
  static List<MeriseQuery> generateCommonQueries(
    Mld mld, {
    SqlDialect dialect = SqlDialect.sqlite,
  }) {
    final queries = <MeriseQuery>[];

    for (final table in mld.tables) {
      // 1. Requête simple : Lister tout
      final qTableName = SqlUtils.quote(table.name, dialect);
      queries.add(
        MeriseQuery(
          title: 'Lister les ${table.name}',
          description:
              'Récupère tous les enregistrements de la table ${table.name}.',
          sql: 'SELECT * FROM $qTableName;',
        ),
      );

      // 2. Requêtes avec jointures basées sur les clés étrangères
      for (final fk in table.foreignKeys) {
        final referencedTable = fk.referencedTable;

        queries.add(
          MeriseQuery(
            title: '${table.name} avec ${referencedTable}',
            description:
                'Jointure entre ${table.name} et ${referencedTable} via ${fk.columnName}.',
            sql: _generateJoinQuery(
              table.name,
              referencedTable,
              fk.columnName,
              fk.referencedColumn,
              dialect,
            ),
          ),
        );
      }
    }

    return queries;
  }

  static String _generateJoinQuery(
    String tableA,
    String tableB,
    String columnA,
    String columnB,
    SqlDialect dialect,
  ) {
    final qTableA = SqlUtils.quote(tableA, dialect);
    final qTableB = SqlUtils.quote(tableB, dialect);
    final qColumnA = SqlUtils.quote(columnA, dialect);
    final qColumnB = SqlUtils.quote(columnB, dialect);

    return 'SELECT *\nFROM $qTableA\nJOIN $qTableB ON $qTableA.$qColumnA = $qTableB.$qColumnB;';
  }
}
