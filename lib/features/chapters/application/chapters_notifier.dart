import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/local/drift/app_database.dart';
import '../data/chapter_repository.dart';

part 'chapters_notifier.g.dart';

@riverpod
Stream<List<Chapter>> chaptersByProject(
  ChaptersByProjectRef ref,
  String projectLocalId,
) {
  final repository = ref.watch(chapterRepositoryProvider);
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
      localId: const Uuid().v4(),
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

  Future<void> reorderChapter(
    String projectLocalId,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex == newIndex) return;
    final adjustedNew = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final repository = ref.read(chapterRepositoryProvider);
    final chapters = await repository
        .watchChaptersByProject(projectLocalId)
        .first;
    final reordered = List<Chapter>.from(chapters);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(adjustedNew, moved);
    for (var i = 0; i < reordered.length; i++) {
      await repository.updateChapterOrder(
        reordered[i].localId,
        i + 1,
      );
    }
  }
}
