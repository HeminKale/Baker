import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'email_otp_screen.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Baker Ally',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Sign in to continue'),
                const SizedBox(height: 32),
                if (authState.isLoading)
                  const CircularProgressIndicator()
                else
                  FilledButton.icon(
                    onPressed: () async {
                      try {
                        await ref.read(authProvider.notifier).signInWithGoogle();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Sign-in failed: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Continue with Google'),
                  ),
                if (!authState.isLoading) ...[
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('OR'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EmailOtpScreen()),
                      );
                    },
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Continue with Email'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
