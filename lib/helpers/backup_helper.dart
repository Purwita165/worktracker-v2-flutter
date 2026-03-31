import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import '../models/todo.dart';

class BackupHelper {
  static const String _fileName = "todo_backup.json";

  // ==============================
  // GET FILE
  // ==============================
  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = "${dir.path}/$_fileName";
    return File(path);
  }

  // ==============================
  // SAVE BACKUP
  // ==============================
  static Future<void> saveBackup(List<Todo> todos) async {
    final file = await _getFile();

    final data = todos.map((e) => e.toMap()).toList();

    await file.writeAsString(jsonEncode(data));

    print("💾 BACKUP SAVED (${todos.length})");
  }

  // ==============================
  // LOAD BACKUP
  // ==============================
  static Future<List<Todo>> loadBackup() async {
    final file = await _getFile();

    if (!await file.exists()) return [];

    final content = await file.readAsString();

    if (content.isEmpty) return [];

    final List decoded = jsonDecode(content);

    return decoded.map((e) => Todo.fromMap(e)).toList();
  }
}