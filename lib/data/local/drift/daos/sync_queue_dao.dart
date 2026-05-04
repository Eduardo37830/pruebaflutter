import 'dart:convert';

import 'package:drift/drift.dart';
import '../app_database.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Stream<List<SyncQueueData>> watchAllPending() {
    return (select(syncQueue)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<List<SyncQueueData>> getAllPending() {
    return (select(syncQueue)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<void> enqueue({
    required String entityType,
    required String entityLocalId,
    required String operation,
    required Map<String, Object?> payload,
  }) async {
    await into(syncQueue).insert(SyncQueueCompanion(
      entityType: Value(entityType),
      entityLocalId: Value(entityLocalId),
      operation: Value(operation),
      payloadSnapshot: Value(jsonEncode(payload)),
      attemptCount: const Value(0),
      createdAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> removeById(int id) async {
    await (delete(syncQueue)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateAttempt(
      int id, int attemptCount, String? lastError) async {
    await (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        attemptCount: Value(attemptCount),
        lastError: Value(lastError),
      ),
    );
  }
}
