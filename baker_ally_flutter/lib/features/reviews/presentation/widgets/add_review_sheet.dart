import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/review_providers.dart';
import 'star_display.dart';

const _suggestedTags = [
  'Great Quality',
  'Value for Money',
  'Well Packaged',
  'Matched Description',
  'Fast Delivery',
  'Damaged Packaging',
];

/// Add Review bottom sheet (00_common_architecture.md §5a) -- overall rating
/// required, 4 category ratings + comment + tags optional.
class AddReviewSheet extends ConsumerStatefulWidget {
  const AddReviewSheet({super.key, required this.productId});

  final String productId;

  static Future<void> show(BuildContext context, String productId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddReviewSheet(productId: productId),
    );
  }

  @override
  ConsumerState<AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends ConsumerState<AddReviewSheet> {
  int _overall = 0;
  int _quality = 0;
  int _value = 0;
  int _packaging = 0;
  int _accuracy = 0;
  final _comment = TextEditingController();
  final Set<String> _tags = {};
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_overall == 0) {
      setState(() => _error = 'Please give an overall rating');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(reviewRepositoryProvider).submitReview(
            widget.productId,
            overallRating: _overall,
            qualityRating: _quality == 0 ? null : _quality,
            valueRating: _value == 0 ? null : _value,
            packagingRating: _packaging == 0 ? null : _packaging,
            accuracyRating: _accuracy == 0 ? null : _accuracy,
            comment: _comment.text.trim(),
            tags: _tags.toList(),
          );
      ref.invalidate(productReviewsProvider(widget.productId));
      ref.invalidate(reviewEligibilityProvider(widget.productId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not submit review: $e';
      });
    }
  }

  Widget _categoryRow(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          StarPicker(value: value, onChanged: onChanged, size: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Text('Add Review', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    const Text('Overall Rating'),
                    StarPicker(value: _overall, onChanged: (v) => setState(() => _overall = v)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              _categoryRow('Product Quality', _quality, (v) => setState(() => _quality = v)),
              _categoryRow('Value for Money', _value, (v) => setState(() => _value = v)),
              _categoryRow('Packaging Condition', _packaging, (v) => setState(() => _packaging = v)),
              _categoryRow('Accuracy vs Description', _accuracy, (v) => setState(() => _accuracy = v)),
              const Divider(),
              const SizedBox(height: 8),
              TextField(
                controller: _comment,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedTags.map((tag) {
                  final selected = _tags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: selected,
                    onSelected: (v) => setState(() => v ? _tags.add(tag) : _tags.remove(tag)),
                  );
                }).toList(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Submit Review'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
