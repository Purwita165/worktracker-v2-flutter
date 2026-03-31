import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import '../models/todo.dart';

class BackupHelper {
  // ========================================================
  // FILE NAME
  // ========================================================
  static const String _fileName = "todo_backup.json";

  // ========================================================
  // GET FILE
  // ========================================================
  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = "${dir.path}/$_fileName";

    print("📂 BACKUP PATH: $path");

    return File(path);
  }

  // ========================================================
  // SAVE BACKUP
  // ========================================================
  static Future<void> saveBackup(List<Todo> todos) async {
    try {
      final file = await _getFile();

      final data = todos.map((e) => e.toMap()).toList();

      final jsonString = jsonEncode(data);

      await file.writeAsString(jsonString);

      print("💾 BACKUP SAVED (${todos.length} items)");
    } catch (e) {
      print("❌ BACKUP FAILED: $e");
    }
  }

  // ========================================================
  // LOAD BACKUP
  // ========================================================
  static Future<List<Todo>> loadBackup() async {
    try {
      final file = await _getFile();

      if (!await file.exists()) {
        print("📭 BACKUP FILE TIDAK ADA");
        return [];
      }

      final content = await file.readAsString();

      if (content.isEmpty) {
        print("📭 BACKUP KOSONG");
        return [];
      }

      final List decoded = jsonDecode(content);

      final todos = decoded.map((e) => Todo.fromMap(e)).toList();

      print("📥 BACKUP LOADED (${todos.length} items)");

      return todos;
    } catch (e) {
      print("❌ LOAD BACKUP FAILED: $e");
      return [];
    }
  }

  // ========================================================
  // DELETE BACKUP (OPTIONAL)
  // ========================================================
  static Future<void> deleteBackup() async {
    try {
      final file = await _getFile();

      if (await file.exists()) {
        await file.delete();
        print("🗑️ BACKUP DELETED");
      }
    } catch (e) {
      print("❌ DELETE BACKUP FAILED: $e");
    }
  }
}