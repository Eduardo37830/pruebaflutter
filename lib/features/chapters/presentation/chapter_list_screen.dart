import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/local/drift/app_database.dart';
import '../application/chapters_notifier.dart';

class ChapterListScreen extends ConsumerWidget {
  const ChapterListScreen({
    super.key,
    required this.projectLocalId,
    required this.projectTitle,
  });

  final String projectLocalId;
  final String projectTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(chaptersByProjectProvider(projectLocalId));

    return Scaffold(
      appBar: AppBar(title: Text('Capitulos - $projectTitle')),
      body: chaptersAsync.when(
        data: (chapters) {
          if (chapters.isEmpty) {
            return const Center(
              child: Text('No hay capitulos. Crea el primero.'),
            );
          }

          return ListView.separated(
            itemCount: chapters.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chapter = chapters[index];

              return ListTile(
                title: Text(chapter.tituloCapitulo),
                subtitle: Text(
                  _markdownPreview(chapter.contenido),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: CircleAvatar(child: Text(chapter.orden.toString())),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, ref, chapter),
                ),
                onTap: () {
                  context.push('/editor/$projectLocalId/${chapter.localId}');
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewChapterDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo capitulo'),
      ),
    );
  }

  Future<void> _showNewChapterDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) {
                return;
              }
              ref
                  .read(chaptersNotifierProvider.notifier)
                  .createChapter(projectLocalId, title);
              Navigator.pop(context);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Chapter chapter,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar capítulo'),
        content: Text('¿Eliminar "${chapter.tituloCapitulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(chaptersNotifierProvider.notifier).deleteChapter(chapter.localId);
    }
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

    if (normalized.isEmpty) {
      return 'Sin contenido';
    }

    return normalized;
  }
}
