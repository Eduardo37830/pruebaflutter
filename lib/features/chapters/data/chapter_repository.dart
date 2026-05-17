import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/type_utils.dart';
import '../../../../data/local/drift/app_database.dart';
import '../../../../data/local/drift/daos/chapter_dao.dart';
import '../../../../data/local/drift/daos/project_dao.dart';
import '../../../../data/local/drift/database_provider.dart';
import '../../../../sync/engine/sync_engine.dart';

part 'chapter_repository.g.dart';

class ChapterRepository {
  final ChapterDao _chapterDao;
  final ProjectDao _projectDao;
  final Dio _dio;
  final SyncEngine _syncEngine;

  ChapterRepository(
    this._chapterDao,
    this._projectDao,
    this._dio,
    this._syncEngine,
  );

  /// Observa la lista de capítulos por cada proyecto
  Stream<List<Chapter>> watchChaptersByProject(String projectLocalId) {
    return _chapterDao.watchChaptersByProject(projectLocalId);
  }

  /// Recupera solo un capitulo mediante su LocalId
  Future<Chapter?> getChapterById(String localId) async {
    return await _chapterDao.getChapterById(localId);
  }

  /// Inserta un capítulo nuevo indicando en que proyecto perternecerá
  Future<void> createLocalChapter(Chapter chapter) async {
    await _chapterDao.insertChapter(chapter);

    final resolvedRemoteProjectId =
        chapter.remoteProjectId ??
        (await _projectDao.getProjectByLocalId(
          chapter.projectLocalId,
        ))?.remoteId;

    if (resolvedRemoteProjectId == null) {
      return;
    }

    try {
      final response = await _dio.post(
        '/escritos',
        data: {
          'titulo_capitulo': chapter.tituloCapitulo,
          'contenido': chapter.contenido,
          'orden': chapter.orden,
          'proyecto_id': resolvedRemoteProjectId,
        },
      );

      final body = response.data;
      if (body is! Map) {
        return;
      }

      await _chapterDao.updateChapter(
        chapter.copyWith(
          remoteId: Value(asInt(body['id'])),
          remoteProjectId: Value(resolvedRemoteProjectId),
          isSynced: true,
          lastModified: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } on DioException {
      await _syncEngine.enqueueForRetry(
        entityType: 'chapter',
        entityLocalId: chapter.localId,
        operation: 'create',
        payload: {
          'titulo_capitulo': chapter.tituloCapitulo,
          'contenido': chapter.contenido,
          'orden': chapter.orden,
          'proyecto_id': resolvedRemoteProjectId,
          'remote_project_id': resolvedRemoteProjectId,
        },
      );
    }
  }

  Future<int> getNextOrderForProject(String projectLocalId) {
    return _chapterDao.getNextOrderForProject(projectLocalId);
  }

  Future<void> updateChapterOrder(String localId, int newOrden) {
    return _chapterDao.updateChapterOrder(localId, newOrden);
  }

  /// Actualiza los atributos del capítulo y reinicia la validacion de sync con backend
  Future<void> updateLocalChapter(Chapter chapter) async {
    final localUpdated = chapter.copyWith(
      isSynced: false,
      lastModified: DateTime.now().millisecondsSinceEpoch,
    );
    await _chapterDao.updateChapter(localUpdated);

    final remoteId = localUpdated.remoteId;
    if (remoteId == null) {
      return;
    }

    try {
      await _dio.put(
        '/escritos/$remoteId',
        data: {
          'titulo_capitulo': localUpdated.tituloCapitulo,
          'contenido': localUpdated.contenido,
          'orden': localUpdated.orden,
        },
      );

      await _chapterDao.updateChapter(
        localUpdated.copyWith(
          isSynced: true,
          lastModified: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } on DioException {
      final remoteId = localUpdated.remoteId;
      await _syncEngine.enqueueForRetry(
        entityType: 'chapter',
        entityLocalId: localUpdated.localId,
        operation: 'update',
        payload: {
          'titulo_capitulo': localUpdated.tituloCapitulo,
          'contenido': localUpdated.contenido,
          'orden': localUpdated.orden,
          if (remoteId != null) 'remote_id': remoteId,
        },
      );
    }
  }

  /// Realiza borrado logico del capitulo
  Future<void> deleteChapter(String localId) async {
    final existing = await _chapterDao.getChapterById(localId);

    await _chapterDao.softDeleteChapter(localId);

    final remoteId = existing?.remoteId;
    if (remoteId == null || existing == null) {
      return;
    }

    try {
      await _dio.delete('/escritos/$remoteId');

      await _chapterDao.updateChapter(
        existing.copyWith(
          isDeleted: true,
          isSynced: true,
          lastModified: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } on DioException {
      final remoteId = existing.remoteId;
      await _syncEngine.enqueueForRetry(
        entityType: 'chapter',
        entityLocalId: existing.localId,
        operation: 'delete',
        payload: {
          if (remoteId != null) 'remote_id': remoteId,
        },
      );
    }
  }

  Future<void> refreshChaptersForProject(String projectLocalId) async {
    final project = await _projectDao.getProjectByLocalId(projectLocalId);
    final remoteProjectId = project?.remoteId;
    if (remoteProjectId == null) {
      return;
    }

    try {
      final response = await _dio.get('/escritos/proyecto/$remoteProjectId');
      final data = response.data;

      if (data is! List) {
        return;
      }

      for (final item in data) {
        if (item is! Map) {
          continue;
        }

        final remoteId = asInt(item['id']);
        if (remoteId == null) {
          continue;
        }

        final existing = await _chapterDao.getChapterByRemoteId(remoteId);
        final localId = existing?.localId ?? 'remote-chapter-$remoteId';

        final chapter = Chapter(
          localId: localId,
          remoteId: remoteId,
          tituloCapitulo: (item['titulo_capitulo'] ?? 'Sin titulo').toString(),
          contenido: (item['contenido'] ?? '').toString(),
          orden: asInt(item['orden']) ?? 1,
          projectLocalId: existing?.projectLocalId ?? projectLocalId,
          remoteProjectId: remoteProjectId,
          isSynced: true,
          isDeleted: false,
          lastModified: DateTime.now().millisecondsSinceEpoch,
        );

        await _chapterDao.insertChapter(chapter);
      }
    } on DioException {
      // Mantiene los datos locales actuales.
    }
  }

}

@riverpod
ChapterRepository chapterRepository(ChapterRepositoryRef ref) {
  return ChapterRepository(
    ref.watch(chapterDaoProvider),
    ref.watch(projectDaoProvider),
    ref.watch(dioClientProvider),
    ref.watch(syncEngineProvider),
  );
}
