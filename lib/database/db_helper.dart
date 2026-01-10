import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo.dart';

class DBHelper {
  // =============================================================
  // SINGLETON SETUP
  // =============================================================

  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  static Database? _database;

  // =============================================================
  // DATABASE ACCESSOR
  // =============================================================

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('todo.db');
    return _database!;
  }

  // =============================================================
  // DATABASE INITIALIZATION
  // =============================================================

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // =============================================================
  // DATABASE SCHEMA
  // =============================================================

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        ref TEXT,
        priority INTEGER,
        isDone INTEGER,
        due_date TEXT
      )
    ''');
  }

  // =============================================================
  // DATABASE MIGRATION
  // =============================================================

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE todos ADD COLUMN due_date TEXT',
      );
    }
  }

  // =============================================================
  // CRUD OPERATIONS
  // =============================================================

  /// INSERT
  Future<int> insertTodo(Todo todo) async {
    final db = await database;
    return await db.insert(
      'todos',
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// SELECT ALL
  Future<List<Todo>> getTodos() async {
    final db = await database;

    final result = await db.query(
      'todos',
      orderBy: 'isDone ASC, priority DESC',
    );

    return result.map((e) => Todo.fromMap(e)).toList();
  }

  /// UPDATE (FULL OBJECT)
  Future<int> updateTodo(Todo todo) async {
    final db = await database;

    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  /// UPDATE STATUS ONLY (MARK COMPLETE)
  Future<int> updateTodoStatus(int id, int isDone) async {
    final db = await database;

    return await db.update(
      'todos',
      {'isDone': isDone},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// DELETE
  Future<int> deleteTodo(int id) async {
    final db = await database;

    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
