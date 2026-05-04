import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/local/drift/app_database.dart';
import '../data/chapter_repository.dart';

part 'chapters_notifier.g.dart';

@riverpod
Stream<List<Chapter>> chaptersByProject(
  ChaptersByProjectRef ref,
  String projectLocalId,
) {
  final repository = ref.watch(chapterRepositoryProvider);
  Future<void>.microtask(() {
    repository.refreshChaptersForProject(projectLocalId);
  });
  return repository.watchChaptersByProject(projectLocalId);
}

@riverpod
class ChaptersNotifier extends _$ChaptersNotifier {
  @override
  void build() {}

  Future<void> createChapter(
    String projectLocalId,
    String tituloCapitulo,
  ) async {
    final repository = ref.read(chapterRepositoryProvider);
    final nextOrder = await repository.getNextOrderForProject(projectLocalId);

    final chapter = Chapter(
      localId: DateTime.now().microsecondsSinceEpoch.toString(),
      remoteId: null,
      tituloCapitulo: tituloCapitulo,
      contenido: '# $tituloCapitulo\n\n',
      orden: nextOrder,
      projectLocalId: projectLocalId,
      remoteProjectId: null,
      isSynced: false,
      isDeleted: false,
      lastModified: DateTime.now().millisecondsSinceEpoch,
    );

    await repository.createLocalChapter(chapter);
  }

  Future<void> deleteChapter(String localId) async {
    await ref.read(chapterRepositoryProvider).deleteChapter(localId);
  }
}
