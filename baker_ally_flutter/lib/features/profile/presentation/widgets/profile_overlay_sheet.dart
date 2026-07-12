import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../providers/profile_providers.dart';

/// 90%-height bottom sheet opened by the top bar's avatar button
/// (06_profile_and_account.md "How It Opens"). Profile card + the 8-item
/// menu + a separately-styled destructive Log Out row.
class ProfileOverlaySheet extends ConsumerWidget {
  const ProfileOverlaySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ProfileOverlaySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                profileAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('Could not load profile: $e'),
                  ),
                  data: (profile) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage:
                                profile.avatarUrl != null ? CachedNetworkImageProvider(profile.avatarUrl!) : null,
                            child: profile.avatarUrl == null
                                ? Text(profile.initials, style: const TextStyle(fontSize: 18))
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(profile.fullName ?? 'Your Name',
                                    style: Theme.of(context).textTheme.titleMedium),
                                if (profile.businessName != null && profile.businessName!.isNotEmpty)
                                  Text(profile.businessName!),
                                if (profile.phone != null) Text(profile.phone!),
                                if (profile.gstin != null && profile.gstin!.isNotEmpty)
                                  Text('GSTIN ${profile.gstin}'),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.push('/profile/edit');
                            },
                            child: const Text('Edit →'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      _MenuTile(icon: Icons.local_shipping_outlined, label: 'Your Orders', route: '/orders'),
                      const Divider(height: 1),
                      _MenuTile(
                        icon: Icons.local_shipping,
                        label: 'Order Status',
                        route: '/orders',
                        extra: {'status': 'active'},
                      ),
                      const Divider(height: 1),
                      _MenuTile(icon: Icons.favorite_border, label: 'Your Wishlist', route: '/wishlist'),
                      const Divider(height: 1),
                      _MenuTile(icon: Icons.receipt_long_outlined, label: 'Receipts & Invoices', route: '/receipts'),
                      const Divider(height: 1),
                      _MenuTile(icon: Icons.location_on_outlined, label: 'Delivery Addresses', route: '/addresses'),
                      const Divider(height: 1),
                      _MenuTile(icon: Icons.cake_outlined, label: 'Recipes', route: '/recipes'),
                      const Divider(height: 1),
                      _MenuTile(icon: Icons.call_outlined, label: 'Contact Us', route: '/contact'),
                      const Divider(height: 1),
                      _MenuTile(icon: Icons.help_outline, label: 'Help & Support', route: '/help'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                    title: Text('Log Out', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    onTap: () => _confirmLogOut(context, ref),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Log Out')),
        ],
      ),
    );
    if (confirmed != true) return;

    // Clear Drift local cache (cart, orders, catalog, ...) + JWT + Supabase
    // session, then land on /login with no back-stack (06_profile_and_account.md
    // "Log Out" key rule).
    await ref.read(appDatabaseProvider).clearAll();
    await ref.read(authProvider.notifier).signOut();
    if (context.mounted) {
      Navigator.of(context).pop();
      context.go('/login');
    }
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.route, this.extra});

  final IconData icon;
  final String label;
  final String route;
  final Map<String, dynamic>? extra;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).pop();
        context.push(route, extra: extra);
      },
    );
  }
}
