import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/local/drift/app_database.dart';
import '../../chapters/data/chapter_repository.dart';

part 'editor_notifier.g.dart';

@riverpod
class EditorNotifier extends _$EditorNotifier {
  @override
  FutureOr<Chapter?> build(String chapterLocalId) {
    return ref.read(chapterRepositoryProvider).getChapterById(chapterLocalId);
  }

  Future<void> saveChapter({
    required String title,
    required String markdownContent,
  }) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    final updated = current.copyWith(
      tituloCapitulo: title,
      contenido: markdownContent,
      isSynced: false,
      lastModified: DateTime.now().millisecondsSinceEpoch,
    );

    await ref.read(chapterRepositoryProvider).updateLocalChapter(updated);
    state = AsyncValue.data(updated);
  }
}
