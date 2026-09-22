import 'package:flutter/material.dart';

/// Read-only star row -- `rating` may be fractional (a live average).
class StarDisplay extends StatelessWidget {
  const StarDisplay({super.key, required this.rating, this.size = 16, this.color});

  final double rating;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Colors.amber;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = rating >= i + 1;
        final half = !filled && rating > i && rating < i + 1;
        return Icon(
          half ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
          size: size,
          color: starColor,
        );
      }),
    );
  }
}

/// Interactive 1-5 tap-to-select star row, used by the Add Review form.
class StarPicker extends StatelessWidget {
  const StarPicker({super.key, required this.value, required this.onChanged, this.size = 28});

  final int value; // 0 = unset
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = i + 1;
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: size + 4, minHeight: size + 4),
          iconSize: size,
          onPressed: () => onChanged(starValue),
          icon: Icon(
            value >= starValue ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
        );
      }),
    );
  }
}
