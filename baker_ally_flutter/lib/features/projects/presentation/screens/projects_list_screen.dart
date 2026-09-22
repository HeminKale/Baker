import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/project.dart';
import '../providers/project_providers.dart';

/// `/projects` (07_projects.md §5) -- Active/Completed tabs, search, [+ New].
class ProjectsListScreen extends ConsumerStatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  ConsumerState<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends ConsumerState<ProjectsListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _createNew() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _NewProjectNameDialog(),
    );
    if (name == null || name.trim().isEmpty) return;

    try {
      final project = await ref.read(projectRepositoryProvider).create(name: name.trim());
      ref.invalidate(projectsProvider);
      if (mounted) context.push('/projects/${project.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create project: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);
    final query = _search.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Projects'),
        actions: [
          TextButton.icon(onPressed: _createNew, icon: const Icon(Icons.add), label: const Text('New')),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Active'), Tab(text: 'Completed')],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search projects...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: projectsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Could not load projects: $e')),
              data: (projects) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _ProjectList(
                      projects: projects.where((p) => !p.isCompleted && _matches(p, query)).toList(),
                      emptyMessage: 'No projects yet — tap + New to start one, or add a product from the catalog',
                    ),
                    _ProjectList(
                      projects: projects.where((p) => p.isCompleted && _matches(p, query)).toList(),
                      emptyMessage: 'No completed projects yet',
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _matches(Project p, String query) => query.isEmpty || p.name.toLowerCase().contains(query);
}

class _ProjectList extends ConsumerWidget {
  const _ProjectList({required this.projects, required this.emptyMessage});

  final List<Project> projects;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (projects.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(emptyMessage, textAlign: TextAlign.center)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: projects.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) => _ProjectRow(project: projects[index]),
    );
  }
}

class _ProjectRow extends ConsumerWidget {
  const _ProjectRow({required this.project});

  final Project project;

  String _rupees(int paise) => '₹${(paise / 100).toStringAsFixed(0)}';
  String _date(DateTime d) => '${d.day} ${_month(d.month)}';
  String _month(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${project.name}"?'),
        content: Text('This removes all ${project.itemCount} items in it. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(projectRepositoryProvider).delete(project.id);
      ref.invalidate(projectsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete project: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      onTap: () => context.push('/projects/${project.id}'),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 48,
          height: 48,
          child: project.coverImageUrl != null
              ? CachedNetworkImage(imageUrl: project.coverImageUrl!, fit: BoxFit.cover)
              : Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.folder_special_outlined),
                ),
        ),
      ),
      title: Text(project.name),
      subtitle: Text(
        '${project.itemCount} items · ${_rupees(project.estimatedTotal)} est.'
        '${project.eventDate != null ? ' · 📅 ${_date(project.eventDate!)}' : ''}',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _delete(context, ref),
      ),
    );
  }
}

class _NewProjectNameDialog extends StatefulWidget {
  @override
  State<_NewProjectNameDialog> createState() => _NewProjectNameDialogState();
}

class _NewProjectNameDialogState extends State<_NewProjectNameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Project'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'e.g. Hero\'s Birthday'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(context).pop(_controller.text), child: const Text('Create')),
      ],
    );
  }
}
