import 'package:drift/drift.dart';
import '../app_database.dart';

part 'chapter_dao.g.dart';

@DriftAccessor(tables: [Chapters])
class ChapterDao extends DatabaseAccessor<AppDatabase> with _$ChapterDaoMixin {
  ChapterDao(super.db);

  /// Obtiene todos los capítulos de un proyecto específico que no están lógicamente eliminados, ordenados por 'orden'.
  Stream<List<Chapter>> watchChaptersByProject(String projectLocalId) {
    return (select(chapters)
          ..where(
            (t) =>
                t.projectLocalId.equals(projectLocalId) &
                t.isDeleted.equals(false),
          )
          ..orderBy([
            (t) => OrderingTerm(expression: t.orden, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Inserta un nuevo capítulo.
  Future<void> insertChapter(Insertable<Chapter> chapter) {
    return into(chapters).insert(chapter, mode: InsertMode.insertOrReplace);
  }

  /// Actualiza un capítulo.
  Future<bool> updateChapter(Insertable<Chapter> chapter) {
    return update(chapters).replace(chapter);
  }

  /// Recupera un capítulo de la Base de Datos mediante su localId
  Future<Chapter?> getChapterById(String localId) {
    return (select(
      chapters,
    )..where((t) => t.localId.equals(localId))).getSingleOrNull();
  }

  /// Recupera un capitulo por su identificador remoto.
  Future<Chapter?> getChapterByRemoteId(int remoteId) {
    return (select(
      chapters,
    )..where((t) => t.remoteId.equals(remoteId))).getSingleOrNull();
  }

  /// Calcula el siguiente orden disponible para un proyecto.
  Future<int> getNextOrderForProject(String projectLocalId) async {
    final maxOrderExpr = chapters.orden.max();

    final query = selectOnly(chapters)
      ..addColumns([maxOrderExpr])
      ..where(
        chapters.projectLocalId.equals(projectLocalId) &
            chapters.isDeleted.equals(false),
      );

    final row = await query.getSingleOrNull();
    final maxOrder = row?.read(maxOrderExpr);

    return (maxOrder ?? 0) + 1;
  }

  /// Borrado lógico del capítulo marcando que requiere sincronización con Backend.
  Future<void> softDeleteChapter(String localId) {
    return (update(chapters)..where((c) => c.localId.equals(localId))).write(
      ChaptersCompanion(
        isDeleted: const Value(true),
        isSynced: const Value(false),
        lastModified: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Borrado lógico en lote para todos los capítulos de un proyecto.
  Future<void> softDeleteByProject(String projectLocalId) {
    return (update(
      chapters,
    )..where((c) => c.projectLocalId.equals(projectLocalId))).write(
      ChaptersCompanion(
        isDeleted: const Value(true),
        isSynced: const Value(false),
        lastModified: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}
