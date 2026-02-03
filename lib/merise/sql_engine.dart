import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'mld_transformer.dart';
import 'mpd_generator.dart';
import 'sql_utils.dart';

/// Résultat d'une requête SQL
class QueryResult {
  final List<Map<String, dynamic>> rows;
  final List<String> columns;
  final int rowCount;
  final Duration executionTime;
  final String? error;

  const QueryResult({
    required this.rows,
    required this.columns,
    required this.rowCount,
    required this.executionTime,
    this.error,
  });

  bool get hasError => error != null;
  bool get isEmpty => rowCount == 0;
}

/// Moteur SQL en mémoire pour la simulation
class SqlEngine {
  Database? _db;
  Mld? _currentMld;
  static const _dialect = SqlDialect.sqlite;

  String _q(String name) => SqlUtils.quote(name, _dialect);

  /// Initialiser la base de données avec le schéma MLD
  Future<void> initialize(Mld mld) async {
    // Fermer la connexion existante si elle existe
    await close();

    // Initialiser sqflite selon la plateforme
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Créer une base de données en mémoire
    _db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        // Activer les contraintes de clés étrangères
        await db.execute('PRAGMA foreign_keys = ON;');
      },
    );

    _currentMld = mld;

    // Créer les tables
    await _createTables(mld);
  }

  /// Créer toutes les tables du MLD
  Future<void> _createTables(Mld mld) async {
    if (_db == null) return;

    // Générer le SQL de création avec le générateur MPD
    final sqlScript = MpdGenerator.generate(mld, _dialect);

    // Extraire et exécuter chaque instruction CREATE TABLE
    final createStatements = _extractCreateStatements(sqlScript);

    for (final statement in createStatements) {
      try {
        await _db!.execute(statement);
      } catch (e) {
        print('Erreur lors de la création de table: $e');
        print('Statement: $statement');
      }
    }
  }

  /// Extraire les instructions CREATE TABLE du script SQL
  List<String> _extractCreateStatements(String sqlScript) {
    final statements = <String>[];
    final lines = sqlScript.split('\n');
    final buffer = StringBuffer();
    bool inCreateStatement = false;

    for (final line in lines) {
      final trimmed = line.trim();

      // Ignorer les commentaires et PRAGMA
      if (trimmed.startsWith('--') || trimmed.startsWith('PRAGMA')) {
        continue;
      }

      if (trimmed.toUpperCase().startsWith('CREATE TABLE')) {
        inCreateStatement = true;
        buffer.clear();
      }

      if (inCreateStatement) {
        buffer.writeln(line);

        if (trimmed.endsWith(');')) {
          statements.add(buffer.toString().trim());
          inCreateStatement = false;
        }
      }
    }

    return statements;
  }

  /// Insérer des données dans une table
  Future<void> insertData(String tableName, Map<String, dynamic> data) async {
    if (_db == null) {
      throw StateError('La base de données n\'est pas initialisée');
    }

    try {
      // Use rawInsert with proper quoting so reserved words / spaces work.
      final cols = data.keys.toList();
      final colList = cols.map((c) => _q(c)).join(', ');
      final placeholders = List.filled(cols.length, '?').join(', ');
      final values = cols.map((c) => data[c]).toList();
      final sql =
          'INSERT INTO ${_q(tableName)} ($colList) VALUES ($placeholders)';
      await _db!.rawInsert(sql, values);
    } catch (e) {
      throw Exception('Erreur lors de l\'insertion: $e');
    }
  }

  /// Exécuter une requête SELECT
  Future<QueryResult> executeQuery(String sql) async {
    if (_db == null) {
      return QueryResult(
        rows: [],
        columns: [],
        rowCount: 0,
        executionTime: Duration.zero,
        error: 'La base de données n\'est pas initialisée',
      );
    }

    final stopwatch = Stopwatch()..start();

    try {
      final results = await _db!.rawQuery(sql);
      stopwatch.stop();

      final columns = results.isNotEmpty
          ? results.first.keys.map((k) => k.toString()).toList()
          : <String>[];

      return QueryResult(
        rows: results,
        columns: columns,
        rowCount: results.length,
        executionTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return QueryResult(
        rows: [],
        columns: [],
        rowCount: 0,
        executionTime: stopwatch.elapsed,
        error: e.toString(),
      );
    }
  }

  /// Obtenir toutes les données d'une table
  Future<List<Map<String, dynamic>>> getTableData(String tableName) async {
    if (_db == null) return [];

    try {
      return await _db!.rawQuery('SELECT * FROM ${_q(tableName)}');
    } catch (e) {
      print('Erreur lors de la récupération des données: $e');
      return [];
    }
  }

  /// Obtenir les valeurs possibles pour une clé étrangère
  Future<List<Map<String, dynamic>>> getForeignKeyValues(
    String referencedTable,
    String referencedColumn,
  ) async {
    if (_db == null) return [];

    try {
      final sql =
          'SELECT DISTINCT ${_q(referencedColumn)} FROM ${_q(referencedTable)}';
      return await _db!.rawQuery(sql);
    } catch (e) {
      print('Erreur lors de la récupération des valeurs FK: $e');
      return [];
    }
  }

  /// Vider une table
  Future<void> clearTable(String tableName) async {
    if (_db == null) return;

    try {
      await _db!.execute('DELETE FROM ${_q(tableName)}');
    } catch (e) {
      print('Erreur lors du vidage de la table: $e');
    }
  }

  /// Vider toutes les tables
  Future<void> clearAllTables() async {
    if (_db == null || _currentMld == null) return;

    for (final table in _currentMld!.tables) {
      await clearTable(table.name);
    }
  }

  /// Obtenir le nombre d'enregistrements dans une table
  Future<int> getTableRowCount(String tableName) async {
    if (_db == null) return 0;

    try {
      final result = await _db!.rawQuery(
        'SELECT COUNT(*) as count FROM ${_q(tableName)}',
      );
      return result.first['count'] as int;
    } catch (e) {
      return 0;
    }
  }

  /// Fermer la connexion à la base de données
  Future<void> close() async {
    await _db?.close();
    _db = null;
    _currentMld = null;
  }

  /// Vérifier si la base est initialisée
  bool get isInitialized => _db != null;

  /// Obtenir le MLD actuel
  Mld? get currentMld => _currentMld;
}
