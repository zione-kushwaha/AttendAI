import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/core/database/database_service.dart';
import 'package:hajiri/providers/settings_provider.dart';
import 'package:hajiri/providers/backup_provider.dart';

//
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final backupState = ref.watch(backupProvider);
    final isDarkMode = settings['isDarkMode'] as bool? ?? false;
    final isPinEnabled = settings['pinEnabled'] as bool? ?? false;

    return Scaffold(
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 16),
          _buildSection(context, 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme'),
            value: isDarkMode,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).toggleDarkMode();
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          const Divider(),
          _buildSection(context, 'Security'),
          SwitchListTile(
            title: const Text('PIN Protection'),
            subtitle: const Text('Require PIN to open the app'),
            value: isPinEnabled,
            onChanged: (value) {
              if (value) {
                _showPinDialog(context, ref);
              } else {
                ref
                    .read(settingsProvider.notifier)
                    .setPinProtection(enabled: false);
              }
            },
            secondary: const Icon(Icons.lock),
          ),
          if (isPinEnabled)
            ListTile(
              leading: const Icon(Icons.pin),
              title: const Text('Change PIN'),
              onTap: () => _showPinDialog(context, ref, isChange: true),
            ),
          const Divider(),
          _buildSection(context, 'Data Management'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup Data'),
            subtitle: const Text('Export all data to a file'),
            onTap: () => ref.read(backupProvider.notifier).exportDataToJson(),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore Data'),
            subtitle: const Text('Import data from a backup file'),
            onTap: () => _showRestoreConfirmation(context, ref),
          ),
          const Divider(),
          _buildSection(context, 'About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About AttendAI'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () => _showAboutDialog(context),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () => _showResetConfirmation(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Reset All Data'),
            ),
          ),
          const SizedBox(height: 32),
          if (backupState is AsyncLoading)
            const Center(child: CircularProgressIndicator()),
          if (backupState is AsyncError)
            Center(
              child: Text(
                'Error: ${(backupState).error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showPinDialog(
    BuildContext context,
    WidgetRef ref, {
    bool isChange = false,
  }) {
    final pinController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isChange ? 'Change PIN' : 'Set PIN'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Enter 4-digit PIN',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a PIN';
                  }
                  if (value.length < 4) {
                    return 'PIN must be 4 digits';
                  }
                  if (int.tryParse(value) == null) {
                    return 'PIN must only contain numbers';
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    ref
                        .read(settingsProvider.notifier)
                        .setPinProtection(
                          enabled: true,
                          pin: pinController.text,
                        );
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showRestoreConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Restore Data'),
            content: const Text(
              'This will replace all current data with the backup file. '
              'Any unsaved changes will be lost. Do you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(backupProvider.notifier).importDataFromJson();
                },
                child: const Text('Restore'),
              ),
            ],
          ),
    );
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset All Data'),
            content: const Text(
              'This will delete all classes, students, and attendance records. '
              'This action cannot be undone. Do you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetAllData(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reset'),
              ),
            ],
          ),
    );
  }

  Future<void> _resetAllData(BuildContext context) async {
    final db = DatabaseService();
    await db.clearAllData();

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All data has been reset')));
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'AttendAI',
      applicationVersion: '1.0.0',
      applicationIcon: Image.asset(
        'assets/icon/icon.png',
        width: 48,
        height: 48,
      ),
      applicationLegalese: '© 2025 AttendAI App',
      children: [
        const SizedBox(height: 24),
        const Text(
          'AttendAI is a fully offline attendance management app for teachers and educators. '
          'Manage classes, students, and attendance records without requiring an internet connection.',
        ),
      ],
    );
  }
}
