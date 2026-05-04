import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'daos/project_dao.dart';
import 'daos/chapter_dao.dart';

part 'app_database.g.dart';

/// Mapeo de la tabla de Proyectos
class Projects extends Table {
  TextColumn get localId => text()();
  IntColumn get remoteId => integer().nullable()();
  TextColumn get titulo => text()();
  TextColumn get genero => text().nullable()();
  IntColumn get usuarioId => integer().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get lastModified => integer()();

  @override
  Set<Column> get primaryKey => {localId};
}

/// Mapeo de la tabla de Capitulos
class Chapters extends Table {
  TextColumn get localId => text()();
  IntColumn get remoteId => integer().nullable()();
  TextColumn get tituloCapitulo => text()();
  TextColumn get contenido => text()();
  IntColumn get orden => integer()();
  TextColumn get projectLocalId => text()();
  IntColumn get remoteProjectId => integer().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get lastModified => integer()();

  @override
  Set<Column> get primaryKey => {localId};
}

/// Mapeo de la tabla de Cola de Sincronizacion
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // 'project' o 'chapter'
  TextColumn get entityLocalId => text()();
  TextColumn get operation => text()(); // 'create', 'update', 'delete'
  TextColumn get payloadSnapshot => text()(); // JSON
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  IntColumn get createdAt => integer()();
}

@DriftDatabase(
  tables: [Projects, Chapters, SyncQueue],
  daos: [ProjectDao, ChapterDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'escritor_app.sqlite'));

    // Configuración para Android
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    // Configuración de la carpeta temporal para sqlite3
    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
