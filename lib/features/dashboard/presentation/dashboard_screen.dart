import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/local/drift/app_database.dart';
import '../application/dashboard_notifier.dart';
import '../../auth/application/auth_notifier.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final projectsAsyncValue = ref.watch(dashboardProjectsProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: scheme.primary,
        onRefresh: () =>
            ref.read(dashboardNotifierProvider.notifier).refreshFromBackend(),
        child: projectsAsyncValue.when(
          data: (projects) {
            final filteredProjects = projects.where((project) {
              if (_searchQuery.trim().isEmpty) {
                return true;
              }
              final q = _searchQuery.toLowerCase();
              final inTitle = project.titulo.toLowerCase().contains(q);
              final inGenre = (project.genero ?? '').toLowerCase().contains(q);
              return inTitle || inGenre;
            }).toList();

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: _buildHeader(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Buscar manuscritos, notas, tags...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                ),
                if (filteredProjects.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildEmptyState(context),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            childAspectRatio: 1.25,
                            mainAxisSpacing: 14,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final project = filteredProjects[index];
                        return _ProjectCard(
                          title: project.titulo,
                          genre: project.genero ?? 'Sin genero',
                          isSynced: project.isSynced,
                          editedLabel: _lastEditedLabel(project.lastModified),
                          onOpen: () {
                            context.push(
                              '/chapters/${project.localId}/${Uri.encodeComponent(project.titulo)}',
                            );
                          },
                          onDelete: () => _confirmDelete(context, project),
                        );
                      }, childCount: filteredProjects.length),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, st) => Center(child: Text('Error: $error')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoNuevoProyecto(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good morning,', style: theme.textTheme.titleMedium),
              Text(
                'Writer.',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Sincronizar',
          onPressed: () {
            ref.read(dashboardNotifierProvider.notifier).refreshFromBackend();
          },
          icon: const Icon(Icons.sync_rounded),
        ),
        IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: () async {
            await ref.read(authNotifierProvider.notifier).logout();
          },
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.menu_book_outlined, size: 44),
              const SizedBox(height: 14),
              Text(
                'No tienes proyectos aún',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Crea tu primer manuscrito para empezar.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => _mostrarDialogoNuevoProyecto(context, ref),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nuevo proyecto'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _lastEditedLabel(int lastModifiedMs) {
    final now = DateTime.now();
    final last = DateTime.fromMillisecondsSinceEpoch(lastModifiedMs);
    final diff = now.difference(last);

    if (diff.inMinutes < 1) {
      return 'Edited just now';
    }
    if (diff.inMinutes < 60) {
      return 'Edited ${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return 'Edited ${diff.inHours} h ago';
    }
    return 'Edited ${diff.inDays} d ago';
  }

  Future<void> _confirmDelete(BuildContext context, Project project) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar proyecto'),
        content: Text('¿Seguro quieres borrar "${project.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(dashboardNotifierProvider.notifier)
          .softDeleteProject(project.localId);
    }
  }

  Future<void> _mostrarDialogoNuevoProyecto(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final titleController = TextEditingController();
    final genreController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nuevo Proyecto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              TextField(
                controller: genreController,
                decoration: const InputDecoration(
                  labelText: 'Género (Opcional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final titulo = titleController.text;
                if (titulo.isNotEmpty) {
                  try {
                    await ref
                        .read(dashboardNotifierProvider.notifier)
                        .createProject(titulo, genreController.text);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  } catch (error) {
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No se pudo crear: $error')),
                    );
                  }
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.title,
    required this.genre,
    required this.editedLabel,
    required this.isSynced,
    required this.onOpen,
    required this.onDelete,
  });

  final String title;
  final String genre;
  final String editedLabel;
  final bool isSynced;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onOpen,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(genre, style: theme.textTheme.labelSmall),
                  ),
                  const Spacer(),
                  if (!isSynced)
                    const Tooltip(
                      message: 'Pendiente de sincronizar',
                      child: Icon(Icons.cloud_off_rounded, color: Colors.red),
                    ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.edit_note_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text(editedLabel, style: theme.textTheme.labelMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
