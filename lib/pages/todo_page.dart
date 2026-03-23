import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../database/db_helper.dart';
import 'package:intl/intl.dart';
import '../widgets/todo_card.dart';
import 'dart:async';

enum FilterType { all, active, completed, priority, due }

class TodoPage extends StatefulWidget {
  const TodoPage({Key? key}) : super(key: key);

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final dbHelper = DBHelper.instance;

  List<Todo> todos = [];

  // ================= PRIORITY LABEL =================
  final Map<String, String> priorityLabels = {
    "H": "High",
    "M": "Medium",
    "L": "Low",
  };

  // ================= PRIORITY COLOR =================
  Color getPriorityColor(String priority) {
    switch (priority) {
      case "H":
        return Colors.red;
      case "M":
        return Colors.orange;
      case "L":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void clearForm() {
    // ================= TEXT CONTROLLER =================
    descController.clear();
    workController.clear();
    refController.clear();

    sequenceController.clear();
    taskNameController.clear();

    // ================= DATE =================
    selectedStartDate = null;
    selectedDueDate = null;

    // ================= VALUE =================
    progress = 0;
    priority = "M"; // default Medium

    // ================= OPTIONAL =================
    // kalau kamu pakai sub context filter di form
    // selectedSubContext = null;

    // ================= REFRESH UI =================
    setState(() {});
  }

  // ================= DATE NORMALIZE =================
  DateTime normalize(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  Timer? _timer;

  // ================= START DATE COLOR =================
  Color getStartDateColor(Todo todo) {
    if (todo.isDone) return Colors.grey;

    // 🔵 sedang berjalan
    if (todo.startedAt != null && !todo.isDone) {
      return Colors.blue;
    }

    if (todo.startDate == null) return Colors.black;

    final now = normalize(DateTime.now());
    final start = normalize(todo.startDate!);

    final diff = start.difference(now).inDays;

    if (start.isBefore(now)) {
      return Colors.orange;
    }

    if (diff >= 0 && diff <= 2) {
      return Colors.green;
    }

    return Colors.black;
  }

  Color getStartDeltaColor(Todo todo) {
    if (todo.startDate == null || todo.startedAt == null) {
      return Colors.grey;
    }

    final diff = todo.startedAt!.difference(todo.startDate!);

    if (diff.inDays == 0) return Colors.blue; // on time
    if (diff.isNegative) return Colors.green; // early
    return Colors.orange; // late
  }

  Duration getRunningDuration(Todo todo) {
    if (todo.startedAt == null) return Duration.zero;

    return DateTime.now().difference(todo.startedAt!);
  }

  String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return "${h}h ${m}m";
  }

  // ============================================================
  // FILTER STATE
  // ============================================================
  FilterType currentFilter = FilterType.all;
  String searchText = "";
  String? priorityFilter;
  String? dueFilter;
  String? contextFilter;
  String? subContextFilter;

  // ============================================================
  // FORM CONTROLLERS
  // ============================================================
  final descController = TextEditingController();
  final workController = TextEditingController();
  final refController = TextEditingController();
  final searchController = TextEditingController();
  final quickController = TextEditingController();
  final FocusNode quickFocus = FocusNode();
  TextEditingController sequenceController = TextEditingController();
  TextEditingController taskNameController = TextEditingController();

  bool isTypingQuick = false;

  String? priority;
  DateTime? dueDate;
  int progress = 0;

  DateTime? selectedStartDate;
  DateTime? selectedDueDate;

  final String currentUserId = "local-user";

  // ============================================================
  // INIT
  // ============================================================
  @override
  void initState() {
    super.initState();

    // ✅ SET DEFAULT FILTER DULU
    contextFilter = "Office";
    subContextFilter = "Project";

    // ✅ BARU LOAD DATA
    loadTodos();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });

    quickController.addListener(() {
      setState(() {
        isTypingQuick = quickController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
      todos = data.where((t) {
        // FILTER CONTEXT
        if (contextFilter != null && t.context != contextFilter) {
          return false;
        }

        // FILTER SUBCONTEXT (KHUSUS OFFICE)
        if (contextFilter == "Office" &&
            subContextFilter != null &&
            t.subContext != subContextFilter) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  // ============================================================
  // ADD TODO
  // ============================================================
  Future<void> addTodo() async {
    if (descController.text.trim().isEmpty) return;

    final todo = Todo(
      userId: currentUserId,
      context: contextFilter ?? "Office",
      subContext: subContextFilter,
      description: descController.text.trim(),
      workId: workController.text.isEmpty ? null : workController.text,
      ref: (contextFilter == "Office" && subContextFilter == "Project")
          ? (sequenceController.text.isEmpty && taskNameController.text.isEmpty)
                ? null
                : "${sequenceController.text.padLeft(3, '0')}|${taskNameController.text.trim()}"
          : refController.text.isEmpty
          ? null
          : refController.text,
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

  // ================= START TASK =================
  Future<void> startTask(Todo todo) async {
    DateTime? newStartedAt;

    if (todo.startedAt == null) {
      // ▶️ START
      newStartedAt = DateTime.now();
    } else {
      // ⏸ PAUSE
      newStartedAt = null;
    }

    final updated = todo.copyWith(startedAt: newStartedAt);

    setState(() {
      final index = todos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        todos[index] = updated;
      }
    });

    await dbHelper.updateTodo(updated);
  }

  // ============================================================
  // QUICK ADD
  // ============================================================
  Future<void> quickAddTask(String text) async {
    if (text.trim().isEmpty) return;

    final todo = Todo(
      userId: currentUserId,
      description: text.trim(),

      context: contextFilter ?? "Office",
      subContext: subContextFilter,

      priority: "M",
      progress: 0,
    );

    await dbHelper.insertTodo(todo);

    quickController.clear();
    setState(() {
      isTypingQuick = false;
    });

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
      startDate: selectedStartDate, // penting
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
      completedAt: newIsDone ? DateTime.now() : null,
    );

    // 🔥 sinkronisasi status
    updated.status = newIsDone ? 'done' : 'open';

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
    }).toList()..sort((a, b) {
      if (a.isDone == b.isDone) return 0;
      return a.isDone ? 1 : -1; // completed ke bawah
    });
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String formatDate(DateTime? date) {
    if (date == null) return "Not set";
    return DateFormat('dd-MM-yyyy').format(date);
  }

  String getStartDeltaLabel(Todo todo) {
    if (todo.startDate == null || todo.startedAt == null) return "";

    final diff = todo.startedAt!.difference(todo.startDate!);

    if (diff.inDays == 0) return "(on time)";
    if (diff.isNegative) return "(${diff.inDays.abs()}d early)";
    return "(+${diff.inDays}d)";
  }

  Duration getRemainingTime(Todo todo) {
    if (todo.dueDate == null) return Duration.zero;

    return todo.dueDate!.difference(DateTime.now());
  }

  String formatRemaining(Duration d) {
    final isOverdue = d.isNegative;

    final abs = d.abs();
    final days = abs.inDays;
    final hours = abs.inHours % 24;

    String result = "";

    if (days > 0) {
      result = "${days}d ${hours}h";
    } else {
      final minutes = abs.inMinutes % 60;
      result = "${hours}h ${minutes}m";
    }

    return isOverdue ? "-$result" : result;
  }

  String getCompletionStatus(Todo todo) {
    if (todo.completedAt == null || todo.dueDate == null) {
      return "Status: -";
    }

    final diff = todo.completedAt!.difference(todo.dueDate!);

    if (diff.inSeconds == 0) {
      return "Status: On Time";
    }

    final text = formatRemaining(diff.abs());

    if (diff.isNegative) {
      return "Status: Early $text";
    } else {
      return "Status: Overdue $text";
    }
  }

  Color getCompletionStatusColor(Todo todo) {
    if (todo.completedAt == null || todo.dueDate == null) {
      return Colors.grey;
    }

    final diff = todo.completedAt!.difference(todo.dueDate!);

    if (diff.inSeconds == 0) return Colors.blue;
    if (diff.isNegative) return Colors.green;

    return Colors.red;
  }

  // ============================================================
  // DIALOG
  // ============================================================
  void openTaskDialog(Todo? todo, String? currentSubContext) {
    if (todo != null) {
      // EDIT MODE
      descController.text = todo.description;
      workController.text = todo.workId ?? "";
      refController.text = todo.ref ?? "";
      priority = todo.priority;
      dueDate = todo.dueDate;
      selectedStartDate = todo.startDate;
      progress = todo.progress;
    } else {
      // ADD MODE
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
                  // ================= OFFICE MODE =================
                  if (contextFilter == "Office" &&
                      currentSubContext == "Project") ...[
                    const SizedBox(height: 10),

                    TextField(
                      controller: workController,
                      decoration: const InputDecoration(
                        labelText: "Project Code",
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: sequenceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Seq"),
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text("|"),
                        ),

                        Expanded(
                          flex: 5,
                          child: TextField(
                            controller: taskNameController,
                            decoration: const InputDecoration(
                              labelText: "Task",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (contextFilter == "Office" &&
                      currentSubContext == "General") ...[
                    const SizedBox(height: 10),

                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: "Task"),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: refController,
                      decoration: const InputDecoration(labelText: "Reference"),
                    ),
                  ],

                  // ================= START DATE =================
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Text(
                        "Start Date:",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 12),
                      Text(formatDate(selectedStartDate)),
                      const Spacer(),
                      TextButton(
                        child: const Text("Pick Date"),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedStartDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (picked != null) {
                            setStateDialog(() {
                              selectedStartDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),

                  // ================= DUE DATE =================
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Text(
                        "Due Date:",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 12),
                      Text(formatDate(dueDate)),
                      const Spacer(),
                      TextButton(
                        child: const Text("Pick Date"),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dueDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (picked != null) {
                            setStateDialog(() {
                              dueDate = picked;
                            });
                          }
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

                  // PRIORITY
                  DropdownButtonFormField<String>(
                    value: priority ?? "M",
                    decoration: const InputDecoration(labelText: "Priority"),
                    items: const [
                      DropdownMenuItem(value: "H", child: Text("High")),
                      DropdownMenuItem(value: "M", child: Text("Medium")),
                      DropdownMenuItem(value: "L", child: Text("Low")),
                    ],
                    onChanged: (value) {
                      setStateDialog(() {
                        priority = value;
                      });
                    },
                  ),

                  // PROGRESS
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Text("Progress"),
                      const SizedBox(width: 10),
                      Text("$progress%"),
                    ],
                  ),

                  Slider(
                    value: progress.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 10,
                    label: "$progress%",
                    onChanged: (value) {
                      setStateDialog(() {
                        progress = value.toInt();
                      });
                    },
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
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quickController,
                    decoration: const InputDecoration(
                      hintText: "Quick capture...",
                      border:
                          InputBorder.none, // penting biar tidak double border
                    ),
                  ),
                ),

                if (isTypingQuick)
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => quickAddTask(quickController.text),
                  ),
              ],
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

                      // reset subcontext kalau bukan Office
                      if (value != "Office") {
                        subContextFilter = null;
                      }
                    });

                    loadTodos(); // ✅ WAJIB
                  },
                ),

                if (contextFilter == "Office")
                  DropdownButton<String>(
                    value: subContextFilter,
                    items: const [
                      DropdownMenuItem(
                        value: "Project",
                        child: Text("Project"),
                      ),
                      DropdownMenuItem(
                        value: "General",
                        child: Text("General"),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        subContextFilter = value!;
                      });

                      loadTodos(); // ✅ WAJIB
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
                        openTaskDialog: (t) =>
                            openTaskDialog(t, subContextFilter),
                        confirmDelete: (t) => deleteTodo(t.id!),

                        priorityLabels: priorityLabels,
                        getPriorityColor: getPriorityColor,
                        getStartDateColor: getStartDateColor,

                        getRemainingTime: getRemainingTime,
                        formatRemaining: formatRemaining,

                        onStart: startTask,

                        getCompletionStatus: getCompletionStatus,
                        getCompletionStatusColor: getCompletionStatusColor,
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: isTypingQuick
          ? null
          : FloatingActionButton(
              backgroundColor: Colors.blue.shade900,
              onPressed: () => openTaskDialog(null, subContextFilter),
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}
