/*
============================================================
FILE: main.dart
============================================================

FILE ROLE
---------
File ini adalah ENTRY POINT aplikasi Flutter.

Setiap aplikasi Flutter selalu dimulai dari fungsi:

main()

Flutter akan menjalankan aplikasi dari titik ini.

============================================================
ARCHITECTURE OVERVIEW
------------------------------------------------------------

Aplikasi ini mengikuti struktur sederhana:

UI Layer
↓
Model Layer
↓
Database Layer

File Structure:

main.dart
    ↓
pages/todo_page.dart        → UI
models/todo.dart            → Data Model
database/db_helper.dart     → Database Access

============================================================
SEPARATION OF CONCERN (SOC)
------------------------------------------------------------

File ini hanya bertanggung jawab untuk:

✔ Memulai aplikasi
✔ Menentukan root widget
✔ Menentukan halaman pertama

File ini TIDAK BOLEH berisi:

✘ Database logic
✘ Business logic
✘ Data manipulation

Hal-hal tersebut ditangani oleh layer lain.

============================================================
CONTROL FLOW (ALUR PROGRAM)
------------------------------------------------------------

Ketika aplikasi dijalankan:

main()
  ↓
runApp()
  ↓
MyApp()
  ↓
MaterialApp
  ↓
TodoPage()

============================================================
DATA FLOW OVERVIEW
------------------------------------------------------------

User Action
↓
TodoPage (UI)
↓
Todo Model
↓
DBHelper (Database)
↓
SQLite Storage
↓
Data kembali ke UI

============================================================
*/

import 'package:flutter/material.dart';
import 'pages/todo_page.dart';

void main() {
  runApp(const MyApp());
}

/*
============================================================
ROOT WIDGET
============================================================

MyApp adalah ROOT WIDGET aplikasi.

Widget ini membangun kerangka utama aplikasi.

Biasanya di sini kita mengatur:

• theme
• navigation
• routing
• global configuration
*/

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    /*
    ========================================================
    MATERIAL APP
    ========================================================

    MaterialApp menyediakan:

    • Material Design UI
    • navigation
    • theme
    • scaffold system
    */

    return MaterialApp(

      // menghilangkan banner debug
      debugShowCheckedModeBanner: false,

      /*
      ======================================================
      HOME PAGE
      ======================================================

      Halaman pertama aplikasi adalah TodoPage.

      Di halaman ini user akan:

      • melihat daftar task
      • menambah task
      • mengedit task
      • menghapus task
      */

      home: const TodoPage(),
    );
  }
}