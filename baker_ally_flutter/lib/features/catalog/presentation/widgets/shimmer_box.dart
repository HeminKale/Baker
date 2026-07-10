import 'package:flutter/material.dart';

/// Lightweight manual shimmer placeholder -- no `shimmer` package (not part
/// of the approved stack, Planning docs/Initial plan/flutter_library_stack.md).
/// Used as `CachedNetworkImage`'s `placeholder` builder everywhere a product
/// image loads.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key, this.width, this.height, this.borderRadius = BorderRadius.zero});

  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: 0.4 + 0.3 * _controller.value),
            borderRadius: widget.borderRadius,
          ),
        );
      },
    );
  }
}
