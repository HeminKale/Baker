import 'package:flutter/material.dart';

class _Recipe {
  const _Recipe(this.title, this.summary, this.category);

  final String title;
  final String summary;
  final String category;
}

/// Static content for now (06_profile_and_account.md: "initially static
/// markdown/JSON... later upgradeable to a CMS"). No backend endpoint this
/// milestone -- Phase 1's backend deliverables didn't include one, and
/// hardcoding a handful of recipes here needs no new API surface.
const _kRecipes = [
  _Recipe(
    'Classic Vanilla Butter Cake',
    'A moist all-purpose sponge base -- works for birthday cakes, cupcakes, and layered desserts alike.',
    'Cakes',
  ),
  _Recipe(
    'Eggless Chocolate Truffle',
    'Rich cocoa sponge with a dark chocolate ganache filling, using our premium cocoa powder and compound chocolate.',
    'Cakes',
  ),
  _Recipe(
    'Butter Cookies (Piped)',
    'A firm, pipeable dough for classic swirled butter cookies -- pairs well with our unsalted butter and icing sugar.',
    'Cookies',
  ),
  _Recipe(
    'Basic Bread Loaf',
    'A no-fuss white bread loaf recipe using our bread flour and instant yeast, ideal for beginners.',
    'Breads',
  ),
];

/// `/recipes` (06_profile_and_account.md).
class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _kRecipes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final recipe = _kRecipes[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.cake_outlined),
              title: Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(recipe.summary),
              isThreeLine: true,
              trailing: Chip(label: Text(recipe.category), visualDensity: VisualDensity.compact),
            ),
          );
        },
      ),
    );
  }
}
