/*
============================================================
MAIN ENTRY POINT
============================================================

File ini adalah titik awal aplikasi Flutter.

Semua aplikasi Flutter selalu mulai dari function:

main()

Urutan eksekusinya:

Program Start
      ↓
main()
      ↓
Initialize dependencies (SQLite, service, dll)
      ↓
runApp()
      ↓
Flutter membangun Widget Tree
      ↓
UI pertama muncul
*/

import 'package:flutter/material.dart';

/*
sqflite_common_ffi digunakan untuk SQLite di Desktop.

Kenapa perlu ini?

sqflite default hanya untuk:
- Android
- iOS

Sedangkan untuk:
- Windows
- Linux
- Mac

kita harus menggunakan FFI (Foreign Function Interface)

FFI = jembatan antara Dart dan native C library
*/
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/*
Digunakan untuk mengecek platform aplikasi.

Supaya kita tahu apakah aplikasi berjalan di:
- Android
- iOS
- Windows
- Linux
- Mac
*/
import 'dart:io';

import 'pages/todo_page.dart';

void main() {
  /*
  ============================================================
  INITIALIZE FLUTTER BINDING
  ============================================================

  Dibutuhkan sebelum menggunakan plugin seperti:

  - SQLite
  - SharedPreferences
  - Path provider

  Tanpa ini kadang plugin tidak bekerja di Android.
  */
  WidgetsFlutterBinding.ensureInitialized();

  /*
  ============================================================
  INITIALIZE SQLITE FOR DESKTOP ONLY
  ============================================================

  sqfliteFfiInit()

  Fungsi ini melakukan:

  1. Load SQLite native library
  2. Menghubungkan SQLite ke Dart runtime
  3. Menyiapkan database engine

  IMPORTANT:

  Kode ini HANYA boleh dijalankan di Desktop.

  Android dan iOS sudah punya SQLite sendiri.
  */

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();

    /*
    ============================================================
    SET DATABASE FACTORY FOR DESKTOP
    ============================================================

    databaseFactory adalah global variable yang dipakai
    oleh library sqflite.

    Secara default:

        databaseFactory → Android SQLite

    Di desktop kita ganti menjadi:

        databaseFactoryFfi → SQLite Desktop
    */

    databaseFactory = databaseFactoryFfi;
  }

  /*
  ============================================================
  RUN APPLICATION
  ============================================================

  runApp()

  Fungsi ini memulai Flutter framework.

  runApp menerima ROOT WIDGET.
  Root widget kita adalah:

      MyApp()
  */

  runApp(const MyApp());
}

/*
============================================================
ROOT APPLICATION WIDGET
============================================================

Widget ini adalah root dari seluruh UI.

Semua halaman aplikasi berada di bawah widget ini.

Widget tree akan menjadi:

MyApp
   ↓
MaterialApp
   ↓
TodoPage
   ↓
Todo List UI
*/

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    /*
    MaterialApp adalah wrapper utama aplikasi.

    Fungsi utamanya:

    - Theme
    - Navigation
    - Routing
    - Localization
    - Scaffold support
    */

    return MaterialApp(
      /*
      Menghilangkan tulisan DEBUG di pojok kanan atas
      */
      debugShowCheckedModeBanner: false,

      /*
      Judul aplikasi
      */
      title: 'WorkTracker',

      /*
      Halaman pertama yang dibuka saat aplikasi start
      */
      home: const TodoPage(),
    );
  }
}
