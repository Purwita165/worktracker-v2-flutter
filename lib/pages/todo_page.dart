import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../database/db_helper.dart';
import 'package:intl/intl.dart';
import '../widgets/todo_card.dart';

enum FilterType { all, active, completed, priority, due }

class TodoPage extends StatefulWidget {
  const TodoPage({Key? key}) : super(key: key);

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final dbHelper = DBHelper.instance;

  List<Todo> todos = [];

  // ============================================================
  // FILTER STATE
  // ============================================================
  FilterType currentFilter = FilterType.active;
  String searchText = "";
  String? priorityFilter;
  String? dueFilter;

  // ============================================================
  // FORM CONTROLLERS
  // ============================================================
  final descController = TextEditingController();
  final workController = TextEditingController();
  final refController = TextEditingController();
  final searchController = TextEditingController();
  final quickController = TextEditingController();
  final FocusNode quickFocus = FocusNode();

  bool isTypingQuick = false;

  String? priority;
  DateTime? dueDate;
  int progress = 0;

  String selectedContext = "Office";
  String? selectedSubContext;
  String? contextFilter;

  DateTime? selectedStartDate;

  final String currentUserId = "local-user";

  // ============================================================
  // INIT
  // ============================================================
  @override
  void initState() {
    super.initState();

    loadTodos();

    quickController.addListener(() {
      setState(() {
        isTypingQuick = quickController.text.isNotEmpty;
      });
    });
  }

  final List<String> contextOptions = [
    "Office",
    "Consulting",
    "Learning",
    "Private",
  ];

  final List<String> learningSubContexts = [
    "English & Communication",
    "Business Fundamentals",
    "Operations & Process",
    "Finance Basics",
    "Dev Fundamentals",
    "System Thinking",
    "Documentation & SOP",
    "Problem Solving",
  ];

  // ============================================================
  // LOAD DATA
  // ============================================================
  Future<void> loadTodos() async {
    final data = await dbHelper.getTodos();

    setState(() {
      todos = data;
    });
  }

  // ============================================================
  // ADD TODO
  // ============================================================
  Future<void> addTodo() async {
    if (descController.text.trim().isEmpty) return;

    final todo = Todo(
      userId: currentUserId,
      context: selectedContext,
      subContext: selectedSubContext,
      description: descController.text.trim(),
      workId: workController.text.isEmpty ? null : workController.text,
      ref: refController.text.isEmpty ? null : refController.text,
      priority: priority ?? "M",
      dueDate: dueDate,
      progress: progress,

      startDate: selectedStartDate,
      startedAt: null,

      status: 'open',
    );

    await dbHelper.insertTodo(todo);

    clearForm();
    await loadTodos();
  }

  // ============================================================
  // QUICK ADD
  // ============================================================
  Future<void> quickAddTask(String text) async {
    if (text.trim().isEmpty) return;

    final todo = Todo(
      userId: currentUserId,
      description: text.trim(),

      context: selectedContext,
      subContext: selectedSubContext,

      priority: "M",
      progress: 0,
      status: 'open',
    );

    await dbHelper.insertTodo(todo);

    quickController.clear();
    quickFocus.requestFocus();

    await loadTodos();
  }

  // ============================================================
  // UPDATE
  // ============================================================
  Future<void> updateTodo(Todo todo) async {
    final updated = todo.copyWith(
      description: descController.text.trim(),
      workId: workController.text,
      ref: refController.text,
      priority: priority ?? "M",
      dueDate: dueDate,
      progress: progress,
    );

    await dbHelper.updateTodo(updated);
    await loadTodos();
  }

  // ============================================================
  // DELETE
  // ============================================================
  Future<void> deleteTodo(int id) async {
    await dbHelper.deleteTodo(id);
    await loadTodos();
  }

  // ============================================================
  // TOGGLE DONE (FIXED)
  // ============================================================
  Future<void> toggleTodo(Todo todo) async {
    final newIsDone = !todo.isDone;

    final updated = todo.copyWith(
      isDone: newIsDone,
      status: newIsDone ? 'done' : 'open',
      completedAt: newIsDone ? DateTime.now() : null,
      duration: newIsDone
          ? DateTime.now().difference(todo.createdAt).inHours
          : null,
    );

    setState(() {
      final index = todos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        todos[index] = updated;
      }
    });

    await dbHelper.updateTodo(updated);
  }

  // ============================================================
  // FILTER ENGINE
  // ============================================================
  List<Todo> getFilteredTodos() {
    final now = DateTime.now();
    final query = searchText.toLowerCase();

    return todos.where((t) {
      // ======= SEARCH FILTER ===========
      if (searchText.isNotEmpty) {
        if (!(t.description.toLowerCase().contains(query) ||
            (t.workId ?? "").toLowerCase().contains(query) ||
            (t.ref ?? "").toLowerCase().contains(query))) {
          return false;
        }
      }

      // ================= CONTEXT FILTER =================
      if (contextFilter != null) {
        if (t.context != contextFilter) {
          return false;
        }
      }

      if (currentFilter == FilterType.active && t.isDone) return false;
      if (currentFilter == FilterType.completed && !t.isDone) return false;

      if (priorityFilter != null) {
        if (t.priority != priorityFilter) return false;
      }

      if (dueFilter != null) {
        if (t.dueDate == null) return false;

        if (dueFilter == "overdue" && !t.dueDate!.isBefore(now)) {
          return false;
        }

        if (dueFilter == "week") {
          final weekLater = now.add(const Duration(days: 7));
          if (t.dueDate!.isAfter(weekLater)) return false;
        }
      }

      return true;
    }).toList();
  }

  // ============================================================
  // HELPERS
  // ============================================================
  void clearForm() {
    descController.clear();
    workController.clear();
    refController.clear();
    priority = "M";
    progress = 0;
    dueDate = null;
  }

  String formatDate(DateTime? date) {
    if (date == null) return "-";
    return DateFormat('dd-MM-yyyy').format(date);
  }

  // ============================================================
  // DIALOG
  // ============================================================
  void openTaskDialog(Todo? todo) {
    if (todo != null) {
      descController.text = todo.description;
      workController.text = todo.workId ?? "";
      refController.text = todo.ref ?? "";
      priority = todo.priority;
      dueDate = todo.dueDate;
      progress = todo.progress;
    } else {
      clearForm();
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(todo == null ? "Add Task" : "Edit Task"),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ CONTEXT DROPDOWN
                  DropdownButtonFormField<String>(
                    value: selectedContext,
                    decoration: const InputDecoration(labelText: "Context"),
                    items: contextOptions.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedContext = value!;
                        selectedSubContext = null;
                      });
                    },
                  ),

                  // ================= SUB CONTEXT (HANYA LEARNING) =================
                  if (selectedContext == "Learning")
                    Column(
                      children: [
                        const SizedBox(height: 10),

                        DropdownButtonFormField<String>(
                          value: selectedSubContext,
                          decoration: const InputDecoration(
                            labelText: "Sub Context",
                          ),
                          items: learningSubContexts.map((s) {
                            return DropdownMenuItem(value: s, child: Text(s));
                          }).toList(),
                          onChanged: (value) {
                            setStateDialog(() {
                              selectedSubContext = value;
                            });
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 10),

                  // DESCRIPTION
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),

                  const SizedBox(height: 10),

                  // WORK ID
                  TextField(
                    controller: workController,
                    decoration: const InputDecoration(labelText: "WorkID"),
                  ),

                  const SizedBox(height: 10),

                  // REF
                  TextField(
                    controller: refController,
                    decoration: const InputDecoration(labelText: "Reference"),
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (todo == null) {
                      await addTodo();
                    } else {
                      await updateTodo(todo);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final filteredTodos = getFilteredTodos();

    return Scaffold(
      appBar: AppBar(title: const Text("WorkTracker V2")),

      body: Column(
        children: [
          // QUICK ADD
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: quickController,
              focusNode: quickFocus,
              onSubmitted: quickAddTask,
              decoration: const InputDecoration(
                hintText: "Quick task...",
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // SEARCH
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchController,
              onChanged: (v) {
                setState(() {
                  searchText = v;
                });
              },
              decoration: const InputDecoration(
                hintText: "Search...",
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // == CONTEXT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                const Text("Context: "),
                const SizedBox(width: 10),

                DropdownButton<String?>(
                  value: contextFilter,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text("All"),
                    ),
                    ...contextOptions.map((c) {
                      return DropdownMenuItem<String?>(
                        value: c,
                        child: Text(c),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      contextFilter = value;
                    });
                  },
                ),

                const SizedBox(width: 20),

                Text(
                  contextFilter == null
                      ? "Showing: All"
                      : "Showing: $contextFilter",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          Expanded(
            child: filteredTodos.isEmpty
                ? const Center(child: Text("No tasks"))
                : ListView.builder(
                    itemCount: filteredTodos.length,
                    itemBuilder: (_, i) {
                      final todo = filteredTodos[i];

                      final isOverdue =
                          todo.dueDate != null &&
                          todo.dueDate!.isBefore(DateTime.now()) &&
                          !todo.isDone;

                      return TodoCard(
                        todo: todo,
                        isOverdue: isOverdue,
                        toggleTodo: toggleTodo,
                        openTaskDialog: openTaskDialog,
                        confirmDelete: (t) => deleteTodo(t.id!),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => openTaskDialog(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
