import 'package:flutter/material.dart';

/// Stand-in body for tab roots that get real content in later milestones
/// (Phase 2 Catalog, Phase 3 Cart, Phase 5 Order Again/Brownie Points).
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title -- coming soon')),
    );
  }
}
