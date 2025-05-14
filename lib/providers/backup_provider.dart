import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hajiri/core/database/database_service.dart';

class BackupNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseService _db = DatabaseService();

  BackupNotifier() : super(const AsyncValue.data(null));

  // Export data to a JSON file
  Future<void> exportDataToJson() async {
    try {
      state = const AsyncValue.loading();

      // Get data from database
      final exportData = await _db.exportData();

      // Convert to JSON string
      final jsonData = jsonEncode(exportData);

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final filePath = '${directory.path}/hajiri_backup_$timestamp.json';

      // Write to file
      final file = File(filePath);
      await file.writeAsString(jsonData);

      // Share file
      await Share.shareXFiles([XFile(filePath)], text: 'Hajiri Backup File');

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Import data from a JSON file
  Future<void> importDataFromJson() async {
    try {
      state = const AsyncValue.loading();

      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final jsonString = await file.readAsString();
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

        // Import data
        await _db.importData(jsonData);
      }

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final backupProvider = StateNotifierProvider<BackupNotifier, AsyncValue<void>>((
  ref,
) {
  return BackupNotifier();
});
