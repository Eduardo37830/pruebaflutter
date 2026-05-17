import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/widgets/confirm_delete_dialog.dart';
import '../../../../core/presentation/widgets/offline_banner.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';
import '../../../../data/local/drift/app_database.dart';
import '../application/chapters_notifier.dart';
import '../data/chapter_repository.dart';

class ChapterListScreen extends ConsumerStatefulWidget {
  const ChapterListScreen({
    super.key,
    required this.projectLocalId,
    required this.projectTitle,
  });

  final String projectLocalId;
  final String projectTitle;

  @override
  ConsumerState<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends ConsumerState<ChapterListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _didInit = false;
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chaptersAsync = ref.watch(
      chaptersByProjectProvider(widget.projectLocalId),
    );

    if (!_didInit) {
      _didInit = true;
      Future.microtask(() {
        ref.read(chapterRepositoryProvider).refreshChaptersForProject(
          widget.projectLocalId,
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text('Capitulos - ${widget.projectTitle}')),
      body: Column(
        children: [
          const OfflineBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar capítulos...',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
              onChanged: (value) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(
                  const Duration(milliseconds: 300),
                  () => setState(() => _searchQuery = value.toLowerCase()),
                );
              },
            ),
          ),
          Expanded(
            child: chaptersAsync.when(
              data: (chapters) {
                final filtered = chapters.where((ch) {
                  if (_searchQuery.isEmpty) return true;
                  return ch.tituloCapitulo.toLowerCase().contains(_searchQuery) ||
                      ch.contenido.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'Sin resultados'
                          : 'No hay capítulos. Crea el primero.',
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(chapterRepositoryProvider)
                      .refreshChaptersForProject(widget.projectLocalId),
                  child: ReorderableListView.builder(
                    itemCount: filtered.length,
                    buildDefaultDragHandles: false,
                    onReorder: (oldIndex, newIndex) {
                      ref
                          .read(chaptersNotifierProvider.notifier)
                          .reorderChapter(
                            widget.projectLocalId,
                            oldIndex,
                            newIndex,
                          );
                    },
                    itemBuilder: (context, index) {
                      final chapter = filtered[index];
                      return _ChapterTile(
                        key: ValueKey(chapter.localId),
                        chapter: chapter,
                        onTap: () => context.push(
                          '/editor/${widget.projectLocalId}/${chapter.localId}',
                        ),
                        onDelete: () => _confirmDelete(context, chapter),
                      );
                    },
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerList(),
              ),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewChapterDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo capitulo'),
      ),
    );
  }

  Future<void> _showNewChapterDialog(BuildContext context) async {
    final titleController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear capitulo'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Titulo del capitulo',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            final title = titleController.text.trim();
            if (title.isEmpty) return;
            ref
                .read(chaptersNotifierProvider.notifier)
                .createChapter(widget.projectLocalId, title);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              ref
                  .read(chaptersNotifierProvider.notifier)
                  .createChapter(widget.projectLocalId, title);
              Navigator.pop(context);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Chapter chapter) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Eliminar capítulo',
      message: '¿Eliminar "${chapter.tituloCapitulo}"?',
    );

    if (confirmed) {
      ref
          .read(chaptersNotifierProvider.notifier)
          .deleteChapter(chapter.localId);
    }
  }
}

class _ChapterTile extends StatelessWidget {
  final Chapter chapter;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ChapterTile({
    super.key,
    required this.chapter,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(chapter.tituloCapitulo),
      subtitle: Text(
        _markdownPreview(chapter.contenido),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      leading: ReorderableDragStartListener(
        index: 0,
        child: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            chapter.orden.toString(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }

  String _markdownPreview(String markdown) {
    final normalized = markdown
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' [code] ')
        .replaceAll(RegExp(r'`[^`]*`'), ' ')
        .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), ' [img] ')
        .replaceAll(RegExp(r'\[[^\]]+\]\([^)]*\)'), ' ')
        .replaceAll(RegExp(r'^\s{0,3}#{1,6}\s*', multiLine: true), '')
        .replaceAll(RegExp(r'[>*_~#-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.isEmpty) return 'Sin contenido';
    return normalized;
  }
}
