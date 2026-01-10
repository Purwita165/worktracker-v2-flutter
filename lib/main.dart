import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'pages/todo_page.dart';

void main() {
  // =============================================================
  // REQUIRED FOR WINDOWS / DESKTOP SQLITE
  // =============================================================
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(const HBExeConApp());
}

/// =============================================================
/// ROOT APPLICATION
/// =============================================================
class HBExeConApp extends StatelessWidget {
  const HBExeConApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HB-ExeCon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const TodoPage(),
    );
  }
}