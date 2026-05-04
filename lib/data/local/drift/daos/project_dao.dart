import 'package:drift/drift.dart';
import '../app_database.dart';

part 'project_dao.g.dart';

@DriftAccessor(tables: [Projects])
class ProjectDao extends DatabaseAccessor<AppDatabase> with _$ProjectDaoMixin {
  ProjectDao(super.db);

  /// Obtiene todos los proyectos que no están marcados como eliminados lógicamente
  Stream<List<Project>> watchAllProjects() {
    return (select(projects)..where((t) => t.isDeleted.equals(false))).watch();
  }

  /// Inserta un nuevo proyecto.
  Future<void> insertProject(Insertable<Project> project) {
    return into(projects).insert(project, mode: InsertMode.insertOrReplace);
  }

  /// Recupera un proyecto por su identificador local.
  Future<Project?> getProjectByLocalId(String localId) {
    return (select(
      projects,
    )..where((t) => t.localId.equals(localId))).getSingleOrNull();
  }

  /// Recupera un proyecto por su identificador remoto.
  Future<Project?> getProjectByRemoteId(int remoteId) {
    return (select(
      projects,
    )..where((t) => t.remoteId.equals(remoteId))).getSingleOrNull();
  }

  /// Actualiza un proyecto existente.
  Future<bool> updateProject(Insertable<Project> project) {
    return update(projects).replace(project);
  }

  /// Eliminado lógico: solo marcamos isDeleted = true y establecemos que requiere sync.
  Future<void> softDeleteProject(String localId) {
    return (update(projects)..where((p) => p.localId.equals(localId))).write(
      ProjectsCompanion(
        isDeleted: const Value(true),
        isSynced: const Value(false),
        lastModified: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}
