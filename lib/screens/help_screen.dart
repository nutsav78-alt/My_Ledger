import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import '../main.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(TranslationService.translate('help', lang)),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHelpItem(
                context,
                Icons.business_center,
                'Business Profile',
                'Create and manage multiple business profiles. Each profile has its own isolated data (Transactions, Parties, Notes). Use "Switch Profile" to jump between them.',
              ),
              _buildHelpItem(
                context,
                Icons.calendar_today,
                'Financial Year (FY)',
                'Filter your data by Financial Year. You can add new years or delete them. All transactions and parties are linked to a specific FY.',
              ),
              _buildHelpItem(
                context,
                Icons.receipt_long,
                'Transactions (Day Book)',
                'Record daily Income and Expense. Transactions are automatically tracked on the Home dashboard chart.',
              ),
              _buildHelpItem(
                context,
                Icons.people,
                'Parties & Ledgers',
                'Manage your clients or suppliers. Each party has a dedicated ledger showing debit/credit history and real-time current balance.',
              ),
              _buildHelpItem(
                context,
                Icons.calendar_month,
                'Date Format (AD/BS)',
                'The app supports both AD and BS (Nepali) calendars. Change your preference in Settings to update dates across the entire app instantly.',
              ),
              _buildHelpItem(
                context,
                Icons.security,
                'App Lock',
                'Secure your financial data with PIN, Password, or Biometrics (Fingerprint). Enable it from the Drawer menu.',
              ),
              _buildHelpItem(
                context,
                Icons.backup,
                'Backup & Restore',
                'Export your data to Excel, PDF, or JSON. Use JSON backup to restore your data on a new device.',
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'My Ledger v2.0\nProfessional Financial Tracking',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHelpItem(BuildContext context, IconData icon, String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 14, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
