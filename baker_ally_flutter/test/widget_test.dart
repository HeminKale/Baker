// Minimal smoke test for Milestone 1. LoginScreen/AppShell pull in
// supabase_flutter through the provider tree, which needs Supabase.initialize()
// (network/plugin channels) to construct -- proper auth-flow widget tests
// belong in a dedicated testing pass with a mocked SupabaseClient, not this
// scaffold. This test just proves the `flutter test` toolchain is wired up.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baker_ally_flutter/shared/widgets/placeholder_screen.dart';

void main() {
  testWidgets('PlaceholderScreen renders its title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlaceholderScreen(title: 'Home')),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Home -- coming soon'), findsOneWidget);
  });
}
