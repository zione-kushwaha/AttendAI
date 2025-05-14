import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hajiri/providers/settings_provider.dart';
import 'package:hajiri/providers/backup_provider.dart';

// Content-only version of SettingsScreen without AppBar
class SettingsScreenContent extends ConsumerWidget {
  const SettingsScreenContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final backupState = ref.watch(backupProvider);
    final isDarkMode = settings['isDarkMode'] as bool? ?? false;
    final isPinEnabled = settings['pinEnabled'] as bool? ?? false;

    return ListView(
      children: [
        const SizedBox(height: 16),
        _buildSection(context, 'Appearance'),
        SwitchListTile(
          title: const Text('Dark Mode'),
          subtitle: const Text('Enable dark theme'),
          value: isDarkMode,
          onChanged: (value) {
            ref
                .read(settingsProvider.notifier)
                .updateSetting('isDarkMode', value);
          },
        ),
        const Divider(),

        _buildSection(context, 'Security'),
        SwitchListTile(
          title: const Text('PIN Protection'),
          subtitle: const Text('Require PIN to open app'),
          value: isPinEnabled,
          onChanged: (value) {
            ref
                .read(settingsProvider.notifier)
                .updateSetting('pinEnabled', value);
            if (value) {
              _showPinDialog(context, ref);
            }
          },
        ),
        if (isPinEnabled)
          ListTile(
            title: const Text('Change PIN'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showPinDialog(context, ref, isChangingPin: true),
          ),
        const Divider(),

        _buildSection(context, 'Data Management'),
        ListTile(
          title: const Text('Export Data'),
          subtitle: const Text('Backup your data to a file'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            ref.read(backupProvider.notifier).exportDataToJson();
          },
        ),
        ListTile(
          title: const Text('Import Data'),
          subtitle: const Text('Restore data from a backup file'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            _showImportWarningDialog(context, ref);
          },
        ),
        if (backupState.isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
        backupState.when(
          data: (_) => const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error:
              (error, stackTrace) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  error.toString(),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
        ),
        const Divider(),

        _buildSection(context, 'About'),
        ListTile(
          title: const Text('About Hajiri'),
          subtitle: const Text('Version 1.0.0'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            _showAboutDialog(context);
          },
        ),
        ListTile(
          title: const Text('Privacy Policy'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Open privacy policy
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showPinDialog(
    BuildContext context,
    WidgetRef ref, {
    bool isChangingPin = false,
  }) {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isChangingPin ? 'Change PIN' : 'Set PIN'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pinController,
                  decoration: const InputDecoration(
                    labelText: 'Enter PIN (4 digits)',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                ),
                TextField(
                  controller: confirmPinController,
                  decoration: const InputDecoration(labelText: 'Confirm PIN'),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (pinController.text.length != 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN must be 4 digits')),
                    );
                    return;
                  }
                  if (pinController.text != confirmPinController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PINs do not match')),
                    );
                    return;
                  }

                  ref
                      .read(settingsProvider.notifier)
                      .updateSetting('pin', pinController.text);
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isChangingPin
                            ? 'PIN changed successfully'
                            : 'PIN set successfully',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showImportWarningDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Warning'),
            content: const Text(
              'Importing data will overwrite all existing data. This action cannot be undone. Are you sure you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(backupProvider.notifier).importDataFromJson();
                },
                child: const Text('Continue'),
              ),
            ],
          ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Hajiri',
      applicationVersion: '1.0.0',
      applicationIcon: Image.asset(
        'assets/icon/app_icon.png',
        width: 48,
        height: 48,
      ),
      applicationLegalese: '© 2024 Your Company',
      children: [
        const SizedBox(height: 16),
        const Text(
          'Hajiri is an attendance management app designed for teachers and educators to easily track student attendance.',
        ),
      ],
    );
  }
}
