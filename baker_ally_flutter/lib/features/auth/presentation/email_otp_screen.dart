import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

/// Second sign-in path alongside Google: user enters email, gets a 6-digit
/// code, verifies it. Supabase handles delivery -- no Google Cloud setup.
class EmailOtpScreen extends ConsumerStatefulWidget {
  const EmailOtpScreen({super.key});

  @override
  ConsumerState<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends ConsumerState<EmailOtpScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).sendEmailOtp(email);
      if (mounted) setState(() => _codeSent = true);
    } catch (e) {
      _showError('Could not send code: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    final email = _emailController.text.trim();
    final token = _otpController.text.trim();
    if (token.isEmpty) {
      _showError('Enter the code from your email');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).verifyEmailOtp(email: email, token: token);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showError('Invalid or expired code: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in with Email')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _emailController,
                enabled: !_codeSent,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (_codeSent) ...[
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '6-digit code',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                FilledButton(
                  onPressed: _codeSent ? _verifyCode : _sendCode,
                  child: Text(_codeSent ? 'Verify Code' : 'Send Code'),
                ),
              if (_codeSent) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() {
                    _codeSent = false;
                    _otpController.clear();
                  }),
                  child: const Text('Use a different email'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
