import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/dio_client.dart';
import '../../../data/local/drift/app_database.dart';
import '../../../data/local/drift/daos/chapter_dao.dart';
import '../../../data/local/drift/daos/project_dao.dart';
import '../../../data/local/drift/daos/sync_queue_dao.dart';
import '../../../data/local/drift/database_provider.dart';

part 'sync_engine.g.dart';

const _maxRetryAttempts = 3;

class SyncEngine {
  final SyncQueueDao _queueDao;
  final ProjectDao _projectDao;
  final ChapterDao _chapterDao;
  final Dio _dio;

  SyncEngine(
    this._queueDao,
    this._projectDao,
    this._chapterDao,
    this._dio,
  );

  Future<void> processQueue() async {
    final items = await _queueDao.getAllPending();
    if (items.isEmpty) return;

    for (final item in items) {
      await _processItem(item);
    }
  }

  Future<void> enqueueForRetry({
    required String entityType,
    required String entityLocalId,
    required String operation,
    required Map<String, Object?> payload,
  }) async {
    await _queueDao.enqueue(
      entityType: entityType,
      entityLocalId: entityLocalId,
      operation: operation,
      payload: payload,
    );
  }

  Future<void> _processItem(SyncQueueData item) async {
    if (item.attemptCount >= _maxRetryAttempts) return;

    try {
      final dependenciesMet = await _checkDependencies(item);
      if (!dependenciesMet) return;

      await _executeOperation(item);

      await _queueDao.removeById(item.id);
    } catch (e) {
      final newAttempt = item.attemptCount + 1;
      await _queueDao.updateAttempt(
        item.id,
        newAttempt,
        e.toString(),
      );
    }
  }

  Future<bool> _checkDependencies(SyncQueueData item) async {
    if (item.entityType == 'chapter' &&
        (item.operation == 'create' || item.operation == 'update')) {
      final payload = _parsePayload(item.payloadSnapshot);
      final remoteProjectId = payload['remote_project_id'];
      if (remoteProjectId == null) {
        final chapter = await _chapterDao.getChapterById(item.entityLocalId);
        if (chapter != null && chapter.remoteProjectId == null) return false;
      }
    }
    if (item.operation == 'update' || item.operation == 'delete') {
      if (item.entityType == 'chapter') {
        final chapter =
            await _chapterDao.getChapterById(item.entityLocalId);
        if (chapter != null && chapter.remoteId == null) return false;
      }
      if (item.entityType == 'project') {
        final project =
            await _projectDao.getProjectByLocalId(item.entityLocalId);
        if (project != null && project.remoteId == null) return false;
      }
    }
    return true;
  }

  Future<void> _executeOperation(SyncQueueData item) async {
    final payload = _parsePayload(item.payloadSnapshot);

    switch (item.entityType) {
      case 'project':
        await _executeProjectOp(
            item.operation, item.entityLocalId, payload);
      case 'chapter':
        await _executeChapterOp(
            item.operation, item.entityLocalId, payload);
    }
  }

  Future<void> _executeProjectOp(
    String operation,
    String localId,
    Map<String, Object?> payload,
  ) async {
    switch (operation) {
      case 'create':
        final response = await _dio.post('/proyectos', data: payload);
        final body = response.data;
        if (body is Map) {
          final project =
              await _projectDao.getProjectByLocalId(localId);
          if (project != null) {
            await _projectDao.updateProject(
              project.copyWith(
                remoteId: Value(_asInt(body['id'])),
                isSynced: true,
                lastModified:
                    DateTime.now().millisecondsSinceEpoch,
              ),
            );
          }
        }
      case 'update':
        final remoteId = payload['remote_id'] as int;
        await _dio.put('/proyectos/$remoteId', data: payload);
        final project =
            await _projectDao.getProjectByLocalId(localId);
        if (project != null) {
          await _projectDao.updateProject(
            project.copyWith(
              isSynced: true,
              lastModified:
                  DateTime.now().millisecondsSinceEpoch,
            ),
          );
        }
      case 'delete':
        final remoteId = payload['remote_id'] as int;
        await _dio.delete('/proyectos/$remoteId');
        final project =
            await _projectDao.getProjectByLocalId(localId);
        if (project != null) {
          await _projectDao.updateProject(
            project.copyWith(
              isSynced: true,
              isDeleted: true,
              lastModified:
                  DateTime.now().millisecondsSinceEpoch,
            ),
          );
        }
    }
  }

  Future<void> _executeChapterOp(
    String operation,
    String localId,
    Map<String, Object?> payload,
  ) async {
    switch (operation) {
      case 'create':
        final response = await _dio.post('/escritos', data: payload);
        final body = response.data;
        if (body is Map) {
          final chapter =
              await _chapterDao.getChapterById(localId);
          if (chapter != null) {
            await _chapterDao.updateChapter(
              chapter.copyWith(
                remoteId: Value(_asInt(body['id'])),
                isSynced: true,
                lastModified:
                    DateTime.now().millisecondsSinceEpoch,
              ),
            );
          }
        }
      case 'update':
        final remoteId = payload['remote_id'] as int;
        await _dio.put('/escritos/$remoteId', data: payload);
        final chapter =
            await _chapterDao.getChapterById(localId);
        if (chapter != null) {
          await _chapterDao.updateChapter(
            chapter.copyWith(
              isSynced: true,
              lastModified:
                  DateTime.now().millisecondsSinceEpoch,
            ),
          );
        }
      case 'delete':
        final remoteId = payload['remote_id'] as int;
        await _dio.delete('/escritos/$remoteId');
        final chapter =
            await _chapterDao.getChapterById(localId);
        if (chapter != null) {
          await _chapterDao.updateChapter(
            chapter.copyWith(
              isSynced: true,
              isDeleted: true,
              lastModified:
                  DateTime.now().millisecondsSinceEpoch,
            ),
          );
        }
    }
  }

  Map<String, Object?> _parsePayload(String json) {
    try {
      return jsonDecode(json) as Map<String, Object?>;
    } catch (_) {
      return {};
    }
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

@Riverpod(keepAlive: true)
SyncEngine syncEngine(SyncEngineRef ref) {
  return SyncEngine(
    ref.watch(syncQueueDaoProvider),
    ref.watch(projectDaoProvider),
    ref.watch(chapterDaoProvider),
    ref.watch(dioClientProvider),
  );
}
