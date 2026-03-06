/*
============================================================
FILE: todo.dart
============================================================

ROLE FILE INI
-------------
File ini mendefinisikan MODEL data Todo.

Model adalah struktur data utama yang dipakai oleh aplikasi.

Todo object mewakili satu task yang dibuat oleh user.

============================================================
ARCHITECTURE POSITION
------------------------------------------------------------

UI Layer
↓
Todo Model  ← file ini
↓
Database Layer (DBHelper)
↓
SQLite Database

Model menjadi jembatan antara:

UI ↔ Database

============================================================
SEPARATION OF CONCERN (SOC)
------------------------------------------------------------

File ini hanya bertanggung jawab untuk:

✔ mendefinisikan struktur data
✔ mengubah object menjadi Map (untuk database)
✔ mengubah Map menjadi object

File ini TIDAK boleh berisi:

✘ UI code
✘ database query
✘ network request

============================================================
DATA FLOW
------------------------------------------------------------

Ketika user membuat task:

User input
↓
Todo object dibuat
↓
Todo.toMap()
↓
DBHelper.insertTodo()
↓
SQLite database

Ketika aplikasi membaca data:

SQLite row
↓
Map<String,dynamic>
↓
Todo.fromMap()
↓
UI menampilkan data

============================================================
FUTURE EXTENSIBILITY
------------------------------------------------------------

Model Todo ini sengaja dibuat fleksibel.

Di masa depan bisa berkembang menjadi:

Inspection item
Survey report
Field activity record

Mapping contoh:

Todo.description → inspection notes
Todo.soNumber    → project / work order
Todo.ref         → equipment / location
Todo.priority    → risk level
Todo.progress    → work progress

============================================================
*/

class Todo {

  /*
  ========================================================
  PRIMARY KEY
  ========================================================

  id adalah unique identifier dari database.

  SQLite akan mengisinya secara otomatis
  karena menggunakan AUTOINCREMENT.
  */

  int? id;

  /*
  ========================================================
  USER ID (FUTURE MULTI USER SUPPORT)
  ========================================================

  Saat ini hanya menggunakan local user.

  Tapi struktur ini memungkinkan aplikasi berkembang
  menjadi multi-user system.
  */

  final String userId;

  /*
  ========================================================
  MAIN TASK DESCRIPTION
  ========================================================

  Ini adalah isi utama dari task.
  */

  String description;

  /*
  ========================================================
  OPTIONAL METADATA
  ========================================================

  Sebelumnya: SoNumber

  Sekarang:
  WorkID

  ref :
  Saat ini: general reference

  Future:
  equipment / location reference
  */

  final String? workId;
  final String? ref;

  /*
  ========================================================
  PRIORITY
  ========================================================

  Priority level task:

  H = High
  M = Medium
  L = Low

  Future mapping:

  priority → risk level (inspection system)
  */

  final String priority;

  /*
  ========================================================
  DUE DATE
  ========================================================

  Optional deadline task.

  Future mapping:

  dueDate → inspection date
  */

  final DateTime? dueDate;

  /*
  ========================================================
  PROGRESS
  ========================================================

  Progress task dalam persen (0–100).

  Future mapping:

  progress → work progress / inspection progress
  */

  int? progress;

  /*
  ========================================================
  TASK CREATION DATE
  ========================================================

  Tanggal task dibuat.
  */

  final DateTime taskDate;

  /*
  ========================================================
  COMPLETION STATUS
  ========================================================

  true  → task selesai
  false → task belum selesai
  */

  bool isDone;

  /*
  ========================================================
  CONSTRUCTOR
  ========================================================

  Constructor digunakan untuk membuat Todo object baru.
  */

  Todo({
    this.id,
    required this.userId,
    required this.description,
    this.workId,
    this.ref,
    required this.priority,
    this.dueDate,
    this.progress,
    required this.taskDate,
    this.isDone = false,
  });

  /*
  ========================================================
  OBJECT → DATABASE MAP
  ========================================================

  SQLite menyimpan data dalam bentuk Map.

  Karena itu object Todo harus diubah menjadi Map
  sebelum disimpan ke database.

  Flow:

  Todo Object
  ↓
  toMap()
  ↓
  SQLite Row
  */

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'description': description,
      'priority': priority,
      'work_id': workId,
      'ref': ref,
      'due_date': dueDate?.toIso8601String(),
      'progress': progress,
      'task_date': taskDate.toIso8601String(),
      'is_done': isDone ? 1 : 0,
    };
  }

  /*
  ========================================================
  DATABASE MAP → OBJECT
  ========================================================

  Ketika membaca data dari database,
  SQLite memberikan hasil dalam bentuk Map.

  Map tersebut diubah kembali menjadi Todo object.

  Flow:

  SQLite Row
  ↓
  Map<String,dynamic>
  ↓
  Todo.fromMap()
  ↓
  Todo object
  */

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      userId: map['user_id'],
      description: map['description'],
      priority: map['priority'],
      workId: map['work_id'],
      ref: map['ref'],
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'])
          : null,
      progress: map['progress'],
      taskDate: map['task_date'] != null
          ? DateTime.parse(map['task_date'])
          : DateTime.now(),
      isDone: map['is_done'] == 1,
    );
  }
}