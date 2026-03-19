import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo.dart';

class DBHelper {
  // ========================================================
  // SINGLETON PATTERN
  // ========================================================
  // Menjamin hanya ada 1 instance database di aplikasi
  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  // ========================================================
  // DATABASE CONFIG
  // ========================================================
  // Version HARUS naik kalau schema berubah
  static const int _dbVersion = 7;
  
  static const String _dbName = "todo.db";

  static Database? _database;

  // ========================================================
  // DATABASE ACCESSOR (LAZY INIT)
  // ========================================================
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // ========================================================
  // INIT DATABASE
  // ========================================================
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // ========================================================
  // CREATE TABLE (FULL STRUCTURE - V2)
  // ========================================================
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        context TEXT,

        sub_context TEXT,

        user_id TEXT,
        description TEXT NOT NULL,

        work_id TEXT,
        ref TEXT,

        priority TEXT,

        due_date TEXT,

        progress INTEGER DEFAULT 0,

        task_date TEXT,

        created_at TEXT,

        start_date TEXT,

        started_at TEXT,

        updated_at TEXT,

        completed_at TEXT,
        duration INTEGER,

        is_done INTEGER DEFAULT 0,

        status TEXT,
        category TEXT,
        notes TEXT
      )
    ''');

    // ========================================================
    // INDEX (PERFORMANCE)
    // ========================================================
    // Mempercepat query saat data sudah banyak
    await db.execute('CREATE INDEX idx_todos_status ON todos(status)');
    await db.execute('CREATE INDEX idx_todos_work_id ON todos(work_id)');
    await db.execute('CREATE INDEX idx_todos_due_date ON todos(due_date)');
  }

  // ========================================================
  // DATABASE MIGRATION (VERY IMPORTANT)
  // ========================================================
  // Jangan ubah CREATE TABLE lama!
  // Tambah kolom via migration agar data lama tidak hilang
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE todos ADD COLUMN created_at TEXT');
      await db.execute('ALTER TABLE todos ADD COLUMN updated_at TEXT');
      await db.execute('ALTER TABLE todos ADD COLUMN status TEXT');
      await db.execute('ALTER TABLE todos ADD COLUMN category TEXT');
      await db.execute('ALTER TABLE todos ADD COLUMN notes TEXT');
      await db.execute('ALTER TABLE todos ADD COLUMN duration INTEGER');
    }

    if (oldVersion < 6) {
      await db.execute('ALTER TABLE todos ADD COLUMN context TEXT');
      await db.execute('ALTER TABLE todos ADD COLUMN sub_context TEXT');
    }

    if (oldVersion < 7) {
      await db.execute('ALTER TABLE todos ADD COLUMN start_date TEXT');
      await db.execute('ALTER TABLE todos ADD COLUMN started_at TEXT');
    }
  }

  // ========================================================
  // INSERT TODO
  // ========================================================
  // Gunakan toMap() dari model → memastikan konsistensi
  Future<int> insertTodo(Todo todo) async {
    final db = await database;

    return await db.insert(
      'todos',
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ========================================================
  // GET TODOS (SMART SORTING)
  // ========================================================
  // Prioritas:
  // 1. Task belum selesai
  // 2. Task deadline terdekat
  // 3. Task terbaru
  Future<List<Todo>> getTodos() async {
    final db = await database;

    final result = await db.query(
      'todos',
      orderBy: 'is_done ASC, due_date ASC, task_date DESC',
    );

    return result.map((e) => Todo.fromMap(e)).toList();
  }

  // ========================================================
  // UPDATE STATUS CEPAT (FAST ACTION)
  // ========================================================
  // Digunakan untuk toggle selesai
  Future<int> updateTodoStatus(int id, int isDone) async {
    final db = await database;

    return await db.update(
      'todos',
      {
        'is_done': isDone,
        'completed_at': isDone == 1 ? DateTime.now().toIso8601String() : null,
        'updated_at': DateTime.now().toIso8601String(),
        'status': isDone == 1 ? 'done' : 'open',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========================================================
  // FULL UPDATE
  // ========================================================
  // Dipakai saat edit detail task
  Future<int> updateTodo(Todo todo) async {
    final db = await database;

    final updatedTodo = todo;

    return await db.update(
      'todos',
      updatedTodo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  // ========================================================
  // DELETE
  // ========================================================
  Future<int> deleteTodo(int id) async {
    final db = await database;

    return await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  // ========================================================
  // CLOSE DATABASE
  // ========================================================
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
