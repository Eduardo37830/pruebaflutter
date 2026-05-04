import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../data/local/drift/app_database.dart';
import '../../../../data/local/drift/daos/chapter_dao.dart';
import '../../../../data/local/drift/daos/project_dao.dart';
import '../../../../data/local/drift/database_provider.dart';
import '../../auth/data/session_store.dart';

part 'project_repository.g.dart';

class ProjectRepository {
  final ProjectDao _projectDao;
  final ChapterDao _chapterDao;
  final Dio _dio;
  final SessionStore _sessionStore;

  ProjectRepository(
    this._projectDao,
    this._chapterDao,
    this._dio,
    this._sessionStore,
  );

  /// Devuelve los proyectos locales de forma reactiva
  Stream<List<Project>> watchAllProjects() {
    return _projectDao.watchAllProjects();
  }

  Future<Project?> getProjectByLocalId(String localId) {
    return _projectDao.getProjectByLocalId(localId);
  }

  Future<void> refreshFromBackend() async {
    final userId = await _sessionStore.getUserId();
    if (userId == null) {
      return;
    }

    try {
      final response = await _dio.get(
        '/proyectos',
        queryParameters: {'usuario_id': userId},
      );

      final data = response.data;
      if (data is! List) {
        return;
      }

      for (final item in data) {
        if (item is! Map) {
          continue;
        }

        final remoteId = _asInt(item['id']);
        if (remoteId == null) {
          continue;
        }

        final existing = await _projectDao.getProjectByRemoteId(remoteId);
        final localId = existing?.localId ?? 'remote-project-$remoteId';

        final project = Project(
          localId: localId,
          remoteId: remoteId,
          titulo: (item['titulo'] ?? '').toString(),
          genero: item['genero']?.toString(),
          usuarioId: _asInt(item['usuario_id']) ?? userId,
          isSynced: true,
          isDeleted: false,
          lastModified: DateTime.now().millisecondsSinceEpoch,
        );

        await _projectDao.insertProject(project);
      }
    } on DioException {
      // Mantiene datos locales si no hay conectividad.
    }
  }

  /// Crea un nuevo proyecto en local
  Future<void> createProject(Project project) async {
    await _projectDao.insertProject(project);

    final userId = project.usuarioId ?? await _sessionStore.getUserId();
    if (userId == null) {
      return;
    }

    try {
      final response = await _dio.post(
        '/proyectos',
        data: {
          'titulo': project.titulo,
          'genero': project.genero,
          'usuario_id': userId,
        },
      );

      final body = response.data;
      if (body is! Map) {
        return;
      }

      final synced = project.copyWith(
        remoteId: Value(_asInt(body['id'])),
        usuarioId: Value(userId),
        isSynced: true,
        lastModified: DateTime.now().millisecondsSinceEpoch,
      );

      await _projectDao.updateProject(synced);
    } on DioException {
      // Queda en pendiente de sincronizacion.
    }
  }

  /// Actualiza datos del proyecto e invalida el Sync
  Future<void> updateLocalProject(Project project) async {
    final localUpdated = project.copyWith(
      isSynced: false,
      lastModified: DateTime.now().millisecondsSinceEpoch,
    );
    await _projectDao.updateProject(localUpdated);

    final remoteId = localUpdated.remoteId;
    if (remoteId == null) {
      return;
    }

    try {
      await _dio.put(
        '/proyectos/$remoteId',
        data: {'titulo': localUpdated.titulo, 'genero': localUpdated.genero},
      );

      await _projectDao.updateProject(
        localUpdated.copyWith(
          isSynced: true,
          lastModified: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } on DioException {
      // Permanece en estado no sincronizado.
    }
  }

  /// Realiza borrado logico del proyecto y sus capitulos dependientes
  Future<void> deleteProject(String localId) async {
    final existing = await _projectDao.getProjectByLocalId(localId);

    await _projectDao.softDeleteProject(localId);
    await _chapterDao.softDeleteByProject(localId);

    final remoteId = existing?.remoteId;
    if (remoteId == null || existing == null) {
      return;
    }

    try {
      await _dio.delete('/proyectos/$remoteId');

      await _projectDao.updateProject(
        existing.copyWith(
          isDeleted: true,
          isSynced: true,
          lastModified: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } on DioException {
      // Permanece en estado no sincronizado.
    }
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}

@riverpod
ProjectRepository projectRepository(ProjectRepositoryRef ref) {
  return ProjectRepository(
    ref.watch(projectDaoProvider),
    ref.watch(chapterDaoProvider),
    ref.watch(dioClientProvider),
    ref.watch(sessionStoreProvider),
  );
}
