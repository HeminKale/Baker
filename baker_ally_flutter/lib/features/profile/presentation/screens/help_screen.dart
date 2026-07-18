import 'package:flutter/material.dart';

import 'contact_screen.dart' show ContactScreen;

class _Faq {
  const _Faq(this.question, this.answer);

  final String question;
  final String answer;
}

const _kFaqs = [
  _Faq(
    'How do I place an order?',
    'Browse the Catalog tab, add items to your cart, then go to the Cart tab to review and check out.',
  ),
  _Faq(
    'How do I track my order?',
    'Open the Profile menu and tap "Order Status" to see all orders currently in progress.',
  ),
  _Faq(
    'Can I change my delivery address after ordering?',
    'Not yet from the app -- please contact support and we\'ll help update it before the order ships.',
  ),
  _Faq(
    'How do I download an invoice?',
    'Open the Profile menu, tap "Receipts & Invoices", and use Download next to the order.',
  ),
  _Faq(
    'What payment methods are accepted?',
    'UPI, cards, and net banking, processed securely via Razorpay.',
  ),
];

/// `/help` (06_profile_and_account.md Help & Support) -- FAQ accordion +
/// raise-a-ticket link (reuses Contact Us's email/WhatsApp actions).
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final faq in _kFaqs)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                title: Text(faq.question, style: const TextStyle(fontWeight: FontWeight.w600)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Align(alignment: Alignment.centerLeft, child: Text(faq.answer)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ContactScreen()),
            ),
            icon: const Icon(Icons.support_agent_outlined),
            label: const Text('Still need help? Raise a ticket'),
          ),
        ],
      ),
    );
  }
}
