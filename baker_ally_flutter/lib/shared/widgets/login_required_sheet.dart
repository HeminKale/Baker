import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shown when a guest taps something that requires login (wishlist heart
/// per 02_catalog_tab.md §4/§6; Cart's guest-checkout flow in Milestone 3
/// reuses this same pattern per 00_common_architecture.md §8).
Future<void> showLoginRequiredSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Log in required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Please log in to continue.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/login');
                },
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
