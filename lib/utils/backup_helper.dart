import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../database/database_helper.dart';

class BackupHelper {
  static final DatabaseHelper _db = DatabaseHelper();

  static Future<void> exportBackup() async {
    try {
      final data = await _db.backupData();
      final jsonString = jsonEncode(data);
      const fileName = 'expense_tracker_backup.json';

      // 1. Try to write directly to Android Downloads folder (Works on many Androids with the permissions we added)
      if (!kIsWeb && Platform.isAndroid) {
        try {
          final directory = Directory('/storage/emulated/0/Download');
          if (await directory.exists()) {
            final file = File('${directory.path}/$fileName');
            await file.writeAsString(jsonString);
            // If we reached here, it saved successfully to Downloads!
            return;
          }
        } catch (e) {
          debugPrint('Direct save to Downloads failed, falling back to Share: $e');
        }
      }

      // 2. Fallback: Save to a temporary location and open the Share Sheet
      // This allows the user to select "Save to device" or "Save to Files" -> "Downloads"
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(tempFile.path, name: fileName)],
        subject: 'Expense Tracker Backup',
      );
      
    } catch (e) {
      debugPrint('Export error: $e');
      rethrow;
    }
  }

  static Future<bool> importBackup() async {
    try {
      // Use FileType.any to ensure all files in Downloads are visible
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        
        dynamic decoded = jsonDecode(content);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('expenses') || decoded.containsKey('categories')) {
            await _db.restoreData(decoded);
            return true;
          }
        }
        throw Exception('Invalid backup file format');
      }
      return false;
    } catch (e) {
      debugPrint('Import error: $e');
      rethrow;
    }
  }
}
