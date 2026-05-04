import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../projects/data/project_repository.dart';
import '../../auth/data/session_store.dart';
import '../../../../data/local/drift/app_database.dart';

part 'dashboard_notifier.g.dart';

/// Alimenta el listado completo de proyectos filtrando borrados de la DB local.
@riverpod
Stream<List<Project>> dashboardProjects(DashboardProjectsRef ref) {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.watchAllProjects();
}

/// Controla acciones como creacion, y borrado de proyectos del tablero
@riverpod
class DashboardNotifier extends _$DashboardNotifier {
  bool _didLoadRemote = false;

  @override
  void build() {
    if (!_didLoadRemote) {
      _didLoadRemote = true;
      Future<void>.microtask(refreshFromBackend);
    }
  }

  Future<void> refreshFromBackend() async {
    await ref.read(projectRepositoryProvider).refreshFromBackend();
  }

  Future<void> createProject(String titulo, String genero) async {
    final usuarioId = await ref.read(sessionStoreProvider).getUserId();
    if (usuarioId == null) {
      throw StateError('No hay sesion activa para crear proyectos');
    }

    final newProject = Project(
      localId: DateTime.now().millisecondsSinceEpoch
          .toString(), // ID simple temporal
      titulo: titulo,
      genero: genero,
      usuarioId: usuarioId,
      isSynced: false,
      isDeleted: false,
      lastModified: DateTime.now().millisecondsSinceEpoch,
    );

    await ref.read(projectRepositoryProvider).createProject(newProject);
  }

  Future<void> softDeleteProject(String localId) async {
    await ref.read(projectRepositoryProvider).deleteProject(localId);
  }
}
