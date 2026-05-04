import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'app_database.dart';
import 'daos/project_dao.dart';
import 'daos/chapter_dao.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
ProjectDao projectDao(ProjectDaoRef ref) {
  return ref.watch(appDatabaseProvider).projectDao;
}

@Riverpod(keepAlive: true)
ChapterDao chapterDao(ChapterDaoRef ref) {
  return ref.watch(appDatabaseProvider).chapterDao;
}
