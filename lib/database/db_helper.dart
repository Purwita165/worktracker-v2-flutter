/*
============================================================
FILE: db_helper.dart
============================================================

ROLE FILE INI
-------------
File ini bertanggung jawab untuk semua operasi DATABASE.

Semua akses ke SQLite harus melalui file ini.

============================================================
ARCHITECTURE POSITION
------------------------------------------------------------

UI Layer
↓
Todo Model
↓
DBHelper (file ini)
↓
SQLite Database

============================================================
SEPARATION OF CONCERN (SOC)
------------------------------------------------------------

UI Layer (todo_page.dart)
✔ menampilkan data
✔ menerima input user

DBHelper (file ini)
✔ mengakses database
✔ melakukan CRUD

Model (todo.dart)
✔ mendefinisikan struktur data

============================================================
OFFLINE-FIRST DESIGN
------------------------------------------------------------

Aplikasi ini menggunakan SQLite database lokal.

Artinya aplikasi dapat bekerja tanpa internet.

Data disimpan di device:

/data/data/app/databases/todo.db

Konsep ini penting untuk:

• productivity apps
• field inspection apps
• mobile offline systems

============================================================
DATA FLOW
------------------------------------------------------------

CREATE TASK

User input
↓
Todo object dibuat
↓
insertTodo()
↓
SQLite menyimpan data

READ TASK

SQLite query
↓
Map<String,dynamic>
↓
Todo.fromMap()
↓
List<Todo>
↓
UI tampil

UPDATE TASK

User edit
↓
updateTodo()
↓
SQLite update

DELETE TASK

User delete
↓
deleteTodo()
↓
SQLite remove

============================================================
*/

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo.dart';

class DBHelper {

  /*
  ========================================================
  SINGLETON PATTERN
  ========================================================

  Database hanya boleh dibuat satu instance.

  Jika database dibuka berkali-kali,
  aplikasi bisa crash atau performa menurun.

  Karena itu kita menggunakan Singleton pattern.
  */

  DBHelper._privateConstructor();

  static final DBHelper instance = DBHelper._privateConstructor();

  static const int _dbVersion = 3;

  static Database? _database;

  /*
  ========================================================
  DATABASE ACCESSOR
  ========================================================

  Getter ini memastikan database hanya dibuka satu kali.

  Jika database belum ada → inisialisasi
  Jika sudah ada → gunakan yang sudah ada
  */

  Future<Database> get database async {

    if (_database != null) return _database!;

    _database = await _initDB('todo.db');

    return _database!;
  }

  /*
  ========================================================
  DATABASE INITIALIZATION
  ========================================================

  Fungsi ini membuat atau membuka database.

  Flow:

  get path
  ↓
  open database
  ↓
  create table jika belum ada
  */

  Future<Database> _initDB(String fileName) async {

    final dbPath = await getDatabasesPath();

    final path = join(dbPath, fileName);

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

  Di sini kita mendefinisikan struktur tabel database.

  Tabel: todos

  Kolom:

  id
  description
  ref
  priority
  isDone
  due_date
  progress
  */

  Future<void> _createDB(Database db, int version) async {

    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        ref TEXT,
        priority TEXT,
        is_done INTEGER,
        due_date TEXT,
        progress INTEGER
      )
    ''');
  }

  /*
  ========================================================
  DATABASE MIGRATION
  ========================================================

  Jika struktur database berubah,
  kita bisa melakukan migration di sini.

  Contoh:

  versi lama tidak punya progress
  versi baru menambahkan progress
  */

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {

    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE todos ADD COLUMN progress INTEGER',
      );
    }
  }

  /*
  ========================================================
  CRUD OPERATIONS
  ========================================================

  CRUD = Create Read Update Delete

  Ini adalah operasi dasar database.

  ========================================================
  */

  /*
  ========================================================
  INSERT (CREATE)
  ========================================================

  Menyimpan Todo baru ke database.
  */

  Future<int> insertTodo(Todo todo) async {

    final db = await database;

    return await db.insert(
      'todos',
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /*
  ========================================================
  SELECT (READ)
  ========================================================

  Mengambil semua todo dari database.
  */

  Future<List<Todo>> getTodos() async {

    final db = await database;

    final result = await db.query(
      'todos',
      orderBy: 'is_done ASC, priority DESC',
    );

    return result.map((e) => Todo.fromMap(e)).toList();
  }

  /*
  ========================================================
  UPDATE (FULL OBJECT)
  ========================================================

  Digunakan ketika user mengedit task.
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

  Digunakan ketika user menekan checkbox.

  Hanya status selesai yang diubah.
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
  DELETE
  ========================================================

  Menghapus task dari database.
  */

  Future<int> deleteTodo(int id) async {

    final db = await database;

    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}