/*
============================================================
FILE: todo_page.dart
============================================================

ROLE FILE INI
-------------
Ini adalah UI Layer aplikasi.

Tanggung jawab file ini:

✔ menampilkan daftar todo
✔ menerima input user
✔ mengatur state UI
✔ memanggil operasi database

============================================================
ARCHITECTURE POSITION
------------------------------------------------------------

User Interaction
↓
TodoPage (UI Layer)
↓
Todo Model
↓
DBHelper (Database Layer)
↓
SQLite

============================================================
SEPARATION OF CONCERN
------------------------------------------------------------

UI Layer
(todo_page.dart)

✔ menampilkan data
✔ menerima input user

Model Layer
(todo.dart)

✔ mendefinisikan struktur data

Database Layer
(db_helper.dart)

✔ CRUD database

============================================================
STATE MANAGEMENT
------------------------------------------------------------

State adalah data yang berubah selama aplikasi berjalan.

State utama halaman ini:

List<Todo> todos

Ketika state berubah kita memanggil:

setState()

agar Flutter melakukan rebuild UI.

============================================================
DATA FLOW
------------------------------------------------------------

User klik Add
↓
Dialog muncul
↓
User isi form
↓
Todo object dibuat
↓
todos.add()
↓
setState()
↓
UI rebuild

============================================================
*/

import 'package:flutter/material.dart';
import '../models/todo.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({Key? key}) : super(key: key);

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {

  /*
  ============================================================
  STATE
  ============================================================
  */

  List<Todo> todos = [];

  String filterMode = "all";

  final TextEditingController descController = TextEditingController();
  final TextEditingController refController = TextEditingController();
  final TextEditingController workController = TextEditingController();

  String? priority;
  DateTime? dueDate;
  int? progress;

  final String currentUserId = "local-user";

  /*
  ============================================================
  PRIORITY CONFIG
  ============================================================
  */

  static const Map<String, String> priorityLabels = {
    "H": "High",
    "M": "Medium",
    "L": "Low",
  };

  /*
  ============================================================
  ADD TODO
  ============================================================
  */

  void addTodo() {

    if (descController.text.trim().isEmpty || priority == null) return;

    final todo = Todo(
      userId: currentUserId,
      description: descController.text.trim(),
      workId: workController.text,
      ref: refController.text,
      priority: priority!,
      dueDate: dueDate,
      progress: progress,
      taskDate: DateTime.now(),
      isDone: false,
    );

    setState(() {
      todos.add(todo);
    });

    descController.clear();
    refController.clear();
    workController.clear();
    priority = null;
    dueDate = null;
    progress = null;
  }

  /*
  ============================================================
  EDIT TODO
  ============================================================
  */

  void editTodo(int index) {

    final todo = todos[index];

    descController.text = todo.description;

    showDialog(
      context: context,
      builder: (_) {

        return AlertDialog(
          title: const Text("Edit Task"),
          content: TextField(
            controller: descController,
            decoration: const InputDecoration(
              labelText: "Description",
            ),
          ),
          actions: [

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {

                setState(() {
                  todo.description = descController.text;
                });

                Navigator.pop(context);
              },
              child: const Text("Save"),
            )

          ],
        );
      },
    );
  }

  /*
  ============================================================
  DELETE TODO
  ============================================================
  */

  void deleteTodo(int index) {

    setState(() {
      todos.removeAt(index);
    });

  }

  /*
  ============================================================
  TOGGLE COMPLETE
  ============================================================
  */

  void toggleTodo(Todo todo) {

    setState(() {
      todo.isDone = !todo.isDone;
    });

  }

  /*
  ============================================================
  FILTER FUNCTION
  ============================================================
  */

  List<Todo> getFilteredTodos() {

    if (filterMode == "active") {
      return todos.where((t) => !t.isDone).toList();
    }

    if (filterMode == "completed") {
      return todos.where((t) => t.isDone).toList();
    }

    return todos;
  }

  /*
  ============================================================
  UI
  ============================================================
  */

  @override
  Widget build(BuildContext context) {

    final filteredTodos = getFilteredTodos();

    return Scaffold(

      appBar: AppBar(
        title: const Text("HB-ExeCon v1"),
      ),

      body: Column(

        children: [

          /*
          FILTER BAR
          */

          Padding(
            padding: const EdgeInsets.all(8.0),

            child: Wrap(
              spacing: 8,

              children: [

                FilterChip(
                  label: const Text("All"),
                  selected: filterMode == "all",
                  onSelected: (_){
                    setState(() => filterMode = "all");
                  },
                ),

                FilterChip(
                  label: const Text("Active"),
                  selected: filterMode == "active",
                  onSelected: (_){
                    setState(() => filterMode = "active");
                  },
                ),

                FilterChip(
                  label: const Text("Completed"),
                  selected: filterMode == "completed",
                  onSelected: (_){
                    setState(() => filterMode = "completed");
                  },
                ),

              ],
            ),
          ),

          /*
          TODO LIST
          */

          Expanded(
            child: filteredTodos.isEmpty
                ? const Center(
                    child: Text(
                      "No tasks yet",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTodos.length,
                    itemBuilder: (context, index) {

                      final todo = filteredTodos[index];

                      return Dismissible(
                        key: Key(todo.hashCode.toString()),

                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),

                        onDismissed: (_) {
                          deleteTodo(todos.indexOf(todo));
                        },

                        child: ListTile(

                          leading: Checkbox(
                            value: todo.isDone,
                            onChanged: (_) => toggleTodo(todo),
                          ),

                          title: Text(
                            todo.description,
                            style: TextStyle(
                              decoration: todo.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),

                          subtitle: Text(
                            "Pr: ${priorityLabels[todo.priority]}  "
                            "Prog: ${todo.progress ?? 0}%",
                          ),

                          onTap: (){
                            editTodo(todos.indexOf(todo));
                          },

                        ),
                      );

                    },
                  ),
          ),

        ],

      ),

      /*
      ========================================================
      FLOATING BUTTON
      ========================================================
      */

      floatingActionButton: FloatingActionButton(

        onPressed: () {

          showDialog(

            context: context,

            builder: (_) {

              return AlertDialog(

                title: const Text("Add Task"),

                content: TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: "Description",
                  ),
                ),

                actions: [

                  TextButton(
                    onPressed: (){
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel"),
                  ),

                  ElevatedButton(
                    onPressed: (){

                      priority ??= "M";
                      progress ??= 0;

                      addTodo();

                      Navigator.pop(context);

                    },
                    child: const Text("Save"),
                  )

                ],

              );

            },

          );

        },

        child: const Icon(Icons.add),

      ),

    );

  }
}