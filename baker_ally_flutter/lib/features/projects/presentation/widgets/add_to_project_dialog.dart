import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/project.dart';
import '../providers/project_providers.dart';

/// "Add to Project" bottom sheet (07_projects.md §4) -- search bar first,
/// existing (active-only) projects list in the middle, "+ New Project"
/// pinned last. Tapping a row toggles that variant's membership in that
/// project; multi-select across several projects in one visit is the point.
class AddToProjectDialog extends ConsumerStatefulWidget {
  const AddToProjectDialog({
    super.key,
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.currentPrice,
    this.imageUrl,
  });

  final String variantId;
  final String productId;
  final String productName;
  final String variantName;
  final int currentPrice;
  final String? imageUrl;

  static Future<void> show(
    BuildContext context, {
    required String variantId,
    required String productId,
    required String productName,
    required String variantName,
    required int currentPrice,
    String? imageUrl,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddToProjectDialog(
        variantId: variantId,
        productId: productId,
        productName: productName,
        variantName: variantName,
        currentPrice: currentPrice,
        imageUrl: imageUrl,
      ),
    );
  }

  @override
  ConsumerState<AddToProjectDialog> createState() => _AddToProjectDialogState();
}

class _AddToProjectDialogState extends ConsumerState<AddToProjectDialog> {
  final _search = TextEditingController();
  final _newProjectName = TextEditingController();

  bool _loading = true;
  String? _error;
  List<Project> _projects = const [];
  Set<String> _memberOf = const {};
  final Set<String> _pending = {}; // projectIds mid-toggle, disables their row
  bool _addingNew = false;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _newProjectName.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(projectRepositoryProvider);
      final results = await Future.wait([
        repo.getAll(status: 'active'),
        repo.getMembership(widget.variantId),
      ]);
      if (!mounted) return;
      setState(() {
        _projects = results[0] as List<Project>;
        _memberOf = results[1] as Set<String>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your projects: $e';
        _loading = false;
      });
    }
  }

  Future<void> _toggle(Project project) async {
    final wasMember = _memberOf.contains(project.id);
    setState(() => _pending.add(project.id));
    try {
      await ref.read(projectRepositoryProvider).setMembership(project.id, widget.variantId, !wasMember);
      ref.read(projectItemVariantIdsProvider.notifier).refresh();
      if (!mounted) return;
      setState(() {
        _memberOf = wasMember ? ({..._memberOf}..remove(project.id)) : {..._memberOf, project.id};
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update project: $e')));
    } finally {
      if (mounted) setState(() => _pending.remove(project.id));
    }
  }

  Future<void> _createAndAdd() async {
    final name = _newProjectName.text.trim();
    if (name.isEmpty) return;
    setState(() => _creating = true);
    try {
      final repo = ref.read(projectRepositoryProvider);
      final project = await repo.create(name: name);
      await repo.setMembership(project.id, widget.variantId, true);
      ref.read(projectItemVariantIdsProvider.notifier).refresh();
      if (!mounted) return;
      setState(() {
        _projects = [project, ..._projects];
        _memberOf = {..._memberOf, project.id};
        _newProjectName.clear();
        _addingNew = false;
        _creating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create project: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = query.isEmpty
        ? _projects
        : _projects.where((p) => p.name.toLowerCase().contains(query)).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'Add "${widget.productName} – ${widget.variantName}" to a project',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Search your projects...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              if (visible.isEmpty && !_addingNew)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(child: Text('No projects yet')),
                                ),
                              for (final project in visible)
                                CheckboxListTile(
                                  value: _memberOf.contains(project.id),
                                  onChanged: _pending.contains(project.id) ? null : (_) => _toggle(project),
                                  title: Text(project.name),
                                  subtitle: Text('${project.itemCount} items'),
                                  secondary: _pending.contains(project.id)
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : null,
                                ),
                              const Divider(),
                              if (_addingNew)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _newProjectName,
                                          autofocus: true,
                                          decoration: const InputDecoration(
                                            hintText: 'Project name',
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                          ),
                                          onSubmitted: (_) => _createAndAdd(),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _creating
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : IconButton(
                                              onPressed: _createAndAdd,
                                              icon: const Icon(Icons.check),
                                            ),
                                    ],
                                  ),
                                )
                              else
                                ListTile(
                                  leading: const Icon(Icons.add),
                                  title: const Text('New Project...'),
                                  onTap: () => setState(() => _addingNew = true),
                                ),
                              const SizedBox(height: 24),
                            ],
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
