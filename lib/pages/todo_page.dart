import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/todo.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  // =============================================================
  // STATE & CONTROLLERS
  // =============================================================

  final TextEditingController descController = TextEditingController();
  final TextEditingController refController = TextEditingController();

  int priority = 1; // 1=Low, 2=Moderate, 3=High
  DateTime? selectedDueDate;

  List<Todo> todos = [];

  // =============================================================
  // LIFECYCLE
  // =============================================================

  @override
  void initState() {
    super.initState();
    loadTodos();
  }

  // =============================================================
  // DATA / ACTIONS (CRUD)
  // =============================================================

  Future<void> loadTodos() async {
    final data = await DBHelper.instance.getTodos();
    setState(() {
      todos = data;
    });
  }

  Future<void> addTodo() async {
    if (descController.text.isEmpty) return;

    print('STEP 1: addTodo() called');

    final todo = Todo(
      description: descController.text,
      ref: refController.text.isEmpty ? null : refController.text,
      priority: priority,
      isDone: 0,
      dueDate: selectedDueDate,
    );

    print('STEP 2: Todo object = ${todo.toMap()}');

    await DBHelper.instance.insertTodo(todo);
    print('STEP 3: insertTodo() finished');

    await loadTodos();
    print('STEP 4: loadTodos() finished');

    descController.clear();
    refController.clear();

    setState(() {
      priority = 1;
      selectedDueDate = null;
    });
  }

  Future<void> deleteTodo(int id) async {
    await DBHelper.instance.deleteTodo(id);
    await loadTodos();
  }

  Future<void> toggleTodo(Todo todo) async {
    final newStatus = todo.isDone == 1 ? 0 : 1;

    await DBHelper.instance.updateTodoStatus(todo.id!, newStatus);

    await loadTodos();
  }

  // =============================================================
  // UI HELPERS
  // =============================================================

  Widget _priorityOption({required String label, required int value}) {
    return Row(
      children: [
        Radio<int>(
          value: value,
          groupValue: priority,
          onChanged: (val) {
            setState(() {
              priority = val!;
            });
          },
        ),
        Text(label),
      ],
    );
  }

  String _priorityLabel(int value) {
    switch (value) {
      case 1:
        return 'Low';
      case 2:
        return 'Moderate';
      case 3:
        return 'High';
      default:
        return '';
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDueDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _confirmDelete(Todo todo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (todo.id != null) {
                await deleteTodo(todo.id!);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // UI
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HB-ExeCon v1')),
      body: Column(
        children: [
          // ================= INPUT SECTION =================
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Task Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: refController,
                        decoration: const InputDecoration(
                          labelText: 'Ref (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        selectedDueDate == null
                            ? 'Due Date'
                            : _formatDate(selectedDueDate!),
                      ),
                      onPressed: _pickDueDate,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Text('Priority'),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _priorityOption(label: 'Low', value: 1),
                          _priorityOption(label: 'Moderate', value: 2),
                          _priorityOption(label: 'High', value: 3),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: addTodo,
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(),

          // ================= LIST SECTION =================
          Expanded(
            child: todos.isEmpty
                ? const Center(child: Text('No tasks yet'))
                : ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (_, index) {
                      final todo = todos[index];
                      return ListTile(
                        leading: Checkbox(
                          value: todo.isDone == 1,
                          onChanged: (_) => toggleTodo(todo),
                        ),
                        title: Text(
                          todo.description,
                          style: TextStyle(
                            decoration: todo.isDone == 1
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (todo.ref != null) Text('Ref: ${todo.ref}'),
                            if (todo.dueDate != null)
                              Text('Due: ${_formatDate(todo.dueDate!)}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _priorityLabel(todo.priority),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(todo),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
