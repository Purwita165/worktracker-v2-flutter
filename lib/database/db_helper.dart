/*
============================================================
FILE: db_helper.dart
============================================================

Database helper untuk semua operasi SQLite.

Semua akses database harus melalui file ini.
*/

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo.dart';

class DBHelper {

  /*
  ========================================================
  SINGLETON PATTERN
  ========================================================
  */

  DBHelper._privateConstructor();

  static final DBHelper instance = DBHelper._privateConstructor();

  static const int _dbVersion = 3;

  static const String _dbName = "todo.db";

  static Database? _database;

  /*
  ========================================================
  DATABASE ACCESSOR
  ========================================================
  */

  Future<Database> get database async {

    if (_database != null) return _database!;

    _database = await _initDB();

    return _database!;
  }

  /*
  ========================================================
  DATABASE INITIALIZATION
  ========================================================
  */

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

  /*
  ========================================================
  DATABASE SCHEMA
  ========================================================
  */

  Future<void> _createDB(Database db, int version) async {

    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        description TEXT NOT NULL,
        work_id TEXT,
        ref TEXT,
        priority TEXT,
        due_date TEXT,
        progress INTEGER,
        task_date TEXT,
        is_done INTEGER
      )
    ''');

  }

  /*
  ========================================================
  DATABASE MIGRATION
  ========================================================
  */

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {

    if (oldVersion < 2) {

      await db.execute(
        'ALTER TABLE todos ADD COLUMN progress INTEGER',
      );

    }

    if (oldVersion < 3) {

      await db.execute(
        'ALTER TABLE todos ADD COLUMN work_id TEXT',
      );

    }

  }

  /*
  ========================================================
  INSERT TODO
  ========================================================
  */

  Future<int> insertTodo(Todo todo) async {

    final db = await database;

    return await db.insert(
      'todos',
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

  }

  /*
  ========================================================
  GET TODOS
  ========================================================
  */

  Future<List<Todo>> getTodos() async {

    final db = await database;

    final result = await db.query(
      'todos',
      orderBy: 'is_done ASC, task_date DESC',
    );

    return result.map((e) => Todo.fromMap(e)).toList();

  }

  /*
  ========================================================
  UPDATE TODO
  ========================================================
  */

  Future<int> updateTodo(Todo todo) async {

    final db = await database;

    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );

  }

  /*
  ========================================================
  UPDATE STATUS ONLY
  ========================================================
  */

  Future<int> updateTodoStatus(int id, int isDone) async {

    final db = await database;

    return await db.update(
      'todos',
      {'is_done': isDone},
      where: 'id = ?',
      whereArgs: [id],
    );

  }

  /*
  ========================================================
  DELETE TODO
  ========================================================
  */

  Future<int> deleteTodo(int id) async {

    final db = await database;

    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );

  }

  /*
  ========================================================
  CLOSE DATABASE
  ========================================================
  */

  Future close() async {

    final db = await instance.database;

    db.close();

  }

}