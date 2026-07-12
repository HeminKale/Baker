import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Placeholder support contact details -- no real support line/inbox has
/// been provisioned yet. A plain `wa.me` link, not an Interakt/WhatsApp
/// Business API integration (00_common_architecture.md §12 no-Interakt
/// decision; 06_profile_and_account.md Contact Us).
const _kSupportPhoneE164 = '919876543210';
const _kSupportEmail = 'support@chefsandbakers.app';
const _kSupportHours = 'Mon–Sat, 9:00 AM – 7:00 PM IST';

/// `/contact` (06_profile_and_account.md Contact Us).
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _openWhatsApp(BuildContext context) async {
    final uri = Uri.parse('https://wa.me/$_kSupportPhoneE164');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open WhatsApp: $e')));
      }
    }
  }

  Future<void> _sendEmail(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: _kSupportEmail);
    try {
      await launchUrl(uri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open mail app: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: const Text('Chat on WhatsApp'),
              subtitle: const Text('+91 98765 43210'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openWhatsApp(context),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              subtitle: const Text(_kSupportEmail),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _sendEmail(context),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.schedule_outlined),
              title: Text('Support Hours'),
              subtitle: Text(_kSupportHours),
            ),
          ),
        ],
      ),
    );
  }
}
