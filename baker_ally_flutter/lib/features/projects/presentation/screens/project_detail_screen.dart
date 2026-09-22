import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../cart/presentation/providers/cart_providers.dart';
import '../../data/models/project.dart';
import '../../data/models/project_detail.dart';
import '../../data/models/project_item.dart';
import '../providers/project_providers.dart';

/// `/projects/:id` (07_projects.md §6). Items with per-unit strikethrough
/// pricing + quantity stepper, an aggregate totals block, Mark
/// Complete/Reopen, project delete, and "Add All to Cart" (§6a).
class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  Future<void> _toggleStatus(BuildContext context, WidgetRef ref, ProjectDetail detail) async {
    final newStatus = detail.project.isCompleted ? 'active' : 'completed';
    try {
      await ref.read(projectRepositoryProvider).update(projectId, status: newStatus);
      ref.invalidate(projectDetailProvider(projectId));
      ref.invalidate(projectsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update project: $e')));
      }
    }
  }

  Future<void> _deleteProject(BuildContext context, WidgetRef ref, Project project) async {
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
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete project: $e')));
      }
    }
  }

  Future<void> _addAllToCart(BuildContext context, WidgetRef ref, ProjectDetail detail) async {
    final items = detail.items.map((i) => (variantId: i.variantId, quantity: i.quantity)).toList();
    if (items.isEmpty) return;
    try {
      await ref.read(cartProvider.notifier).addBatch(items);
      if (context.mounted) context.push('/cart');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add items to cart: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(projectDetailProvider(projectId));

    return Scaffold(
      appBar: AppBar(
        title: Text(detailAsync.valueOrNull?.project.name ?? ''),
        actions: detailAsync.maybeWhen(
          data: (detail) => [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteProject(context, ref, detail.project),
            ),
            IconButton(
              icon: Icon(detail.project.isCompleted ? Icons.replay : Icons.check_circle_outline),
              tooltip: detail.project.isCompleted ? 'Reopen' : 'Mark Complete',
              onPressed: () => _toggleStatus(context, ref, detail),
            ),
          ],
          orElse: () => const [],
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load project: $e')),
        data: (detail) => _ProjectDetailBody(projectId: projectId, detail: detail, onAddAllToCart: () => _addAllToCart(context, ref, detail)),
      ),
    );
  }
}

class _ProjectDetailBody extends ConsumerWidget {
  const _ProjectDetailBody({required this.projectId, required this.detail, required this.onAddAllToCart});

  final String projectId;
  final ProjectDetail detail;
  final VoidCallback onAddAllToCart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _EventClientSubtitle(projectId: projectId, project: detail.project),
        Expanded(
          child: detail.items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No items yet — add products from the catalog using the project icon',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: detail.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) => _ProjectItemRow(projectId: projectId, item: detail.items[index]),
                ),
        ),
        _TotalsFooter(detail: detail, onAddAllToCart: onAddAllToCart),
      ],
    );
  }
}

class _EventClientSubtitle extends ConsumerWidget {
  const _EventClientSubtitle({required this.projectId, required this.project});

  final String projectId;
  final Project project;

  bool get _hasDetails => project.eventDate != null || project.clientName != null || project.clientPhone != null;

  String _formatDate(DateTime d) =>
      '${d.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_hasDetails && project.isCompleted) return const SizedBox.shrink();

    final parts = <String>[
      if (project.eventDate != null) '📅 ${_formatDate(project.eventDate!)}',
      if (project.clientName != null && project.clientName!.isNotEmpty) project.clientName!,
      if (project.clientPhone != null && project.clientPhone!.isNotEmpty) project.clientPhone!,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              parts.isEmpty ? 'No event details yet' : parts.join(' · '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => _EditProjectDetailsSheet.show(context, ref, projectId, project),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}

class _ProjectItemRow extends ConsumerWidget {
  const _ProjectItemRow({required this.projectId, required this.item});

  final String projectId;
  final ProjectItem item;

  String _rupees(int paise) => '₹${(paise / 100).toStringAsFixed(0)}';

  Future<void> _setQuantity(WidgetRef ref, int quantity) async {
    await ref.read(projectRepositoryProvider).updateItemQuantity(projectId, item.id, quantity);
    ref.invalidate(projectDetailProvider(projectId));
    ref.invalidate(projectsProvider);
  }

  Future<void> _remove(WidgetRef ref) async {
    await ref.read(projectRepositoryProvider).removeItem(projectId, item.id);
    ref.invalidate(projectDetailProvider(projectId));
    ref.invalidate(projectsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 48,
          height: 48,
          child: item.imageUrl != null
              ? CachedNetworkImage(imageUrl: item.imageUrl!, fit: BoxFit.cover)
              : Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
        ),
      ),
      title: Text('${item.productName} – ${item.variantName}', maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Row(
        children: [
          if (item.isOnSale) ...[
            Text(
              _rupees(item.originalPrice),
              style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _rupees(item.currentPrice),
            style: TextStyle(fontWeight: FontWeight.bold, color: item.isOnSale ? Colors.green : null),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () => _setQuantity(ref, item.quantity - 1),
          ),
          Text('${item.quantity}'),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => _setQuantity(ref, item.quantity + 1),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _remove(ref),
          ),
        ],
      ),
    );
  }
}

class _TotalsFooter extends StatelessWidget {
  const _TotalsFooter({required this.detail, required this.onAddAllToCart});

  final ProjectDetail detail;
  final VoidCallback onAddAllToCart;

  String _rupees(int paise) => '₹${(paise / 100).toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (detail.hasDiscount)
              Text(
                _rupees(detail.originalTotal),
                style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey),
              ),
            Text(
              'Estimated total: ${_rupees(detail.estimatedTotal)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: detail.items.isEmpty ? null : onAddAllToCart,
                child: const Text('Add All to Cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Event date / client details edit sheet (§6b) -- same field set as project
/// creation's full form, reached from Project Detail's [Edit].
class _EditProjectDetailsSheet extends ConsumerStatefulWidget {
  const _EditProjectDetailsSheet({required this.projectId, required this.project});

  final String projectId;
  final Project project;

  static Future<void> show(BuildContext context, WidgetRef ref, String projectId, Project project) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditProjectDetailsSheet(projectId: projectId, project: project),
    );
  }

  @override
  ConsumerState<_EditProjectDetailsSheet> createState() => _EditProjectDetailsSheetState();
}

class _EditProjectDetailsSheetState extends ConsumerState<_EditProjectDetailsSheet> {
  late final _clientName = TextEditingController(text: widget.project.clientName);
  late final _clientPhone = TextEditingController(text: widget.project.clientPhone);
  late final _notes = TextEditingController(text: widget.project.notes);
  DateTime? _eventDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _eventDate = widget.project.eventDate;
  }

  @override
  void dispose() {
    _clientName.dispose();
    _clientPhone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(projectRepositoryProvider).update(
            widget.projectId,
            eventDate: _eventDate,
            clientName: _clientName.text.trim().isEmpty ? null : _clientName.text.trim(),
            clientPhone: _clientPhone.text.trim().isEmpty ? null : _clientPhone.text.trim(),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );
      ref.invalidate(projectDetailProvider(widget.projectId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Event / Client Details', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(_eventDate == null ? 'Event date (optional)' : '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}'),
            trailing: _eventDate != null
                ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _eventDate = null))
                : null,
            onTap: _pickDate,
          ),
          TextField(controller: _clientName, decoration: const InputDecoration(labelText: 'Client Name')),
          const SizedBox(height: 8),
          TextField(controller: _clientPhone, decoration: const InputDecoration(labelText: 'Client Phone')),
          const SizedBox(height: 8),
          TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
