import 'package:flutter/material.dart';
import '../models/todo.dart';

// ============================================================
// FORMAT DURATION (HELPER)
// ============================================================
// Mengubah jam menjadi format manusiawi
String formatDuration(int hours) {
  if (hours < 24) return "$hours hours";

  int days = hours ~/ 24;
  if (days < 30) return "$days days";

  int months = days ~/ 30;
  return "$months months";
}

class TodoCard extends StatelessWidget {
  final Todo todo;
  final bool isOverdue;

  // ============================================================
  // ACTIONS (DARI PAGE)
  // ============================================================
  final void Function(Todo) toggleTodo;
  final void Function(Todo) openTaskDialog;
  final void Function(Todo) confirmDelete;

  const TodoCard({
    super.key,
    required this.todo,
    required this.isOverdue,
    required this.toggleTodo,
    required this.openTaskDialog,
    required this.confirmDelete,
  });

  // ============================================================
  // LOCAL HELPER (BIAR TIDAK TERGANTUNG PAGE)
  // ============================================================
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

  String formatDate(DateTime? date) {
    if (date == null) return "-";
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  String getPriorityLabel(String p) {
    switch (p) {
      case "H":
        return "High";
      case "M":
        return "Medium";
      case "L":
        return "Low";
      default:
        return "-";
    }
  }

  String getContextLabel() {
    if (todo.context == "Learning" && todo.subContext != null) {
      return "${todo.context} • ${todo.subContext}";
    }
    return todo.context;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      child: Padding(
        padding: const EdgeInsets.all(12),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================================================
            // CHECKBOX
            // ====================================================
            Checkbox(value: todo.isDone, onChanged: (_) => toggleTodo(todo)),

            const SizedBox(width: 8),

            // ====================================================
            // CONTENT
            // ====================================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================= TITLE =================
                  Text(
                    todo.description,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isOverdue ? Colors.red : Colors.black,
                      decoration: todo.isDone
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ================= META =================
                  todo.isDone
                      // ===== COMPLETED =====
                      ? Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            children: [
                              TextSpan(
                                text: "${getContextLabel()}   ",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              TextSpan(
                                text: "WorkID: ${todo.workId ?? "-"}   ",
                              ),

                              TextSpan(text: "Ref: ${todo.ref ?? "-"}   "),

                              TextSpan(
                                text:
                                    "Created: ${formatDate(todo.createdAt)}   ",
                              ),

                              TextSpan(
                                text:
                                    "Completed: ${formatDate(todo.completedAt)}   ",
                              ),

                              TextSpan(
                                text:
                                    "Duration: ${formatDuration(todo.duration ?? 0)}",
                              ),
                            ],
                          ),
                        )
                      // ===== ACTIVE =====
                      : Text.rich(
                          TextSpan(
                            style: const TextStyle(fontSize: 12),
                            children: [
                              TextSpan(
                                text: "${getContextLabel()}   ",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              TextSpan(
                                text: "WorkID: ${todo.workId ?? "-"}   ",
                              ),
                              TextSpan(text: "Ref: ${todo.ref ?? "-"}   "),

                              TextSpan(
                                text:
                                    "Priority: ${getPriorityLabel(todo.priority)}   ",
                                style: TextStyle(
                                  color: getPriorityColor(todo.priority),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              TextSpan(text: "Progress: ${todo.progress}%   "),

                              TextSpan(
                                text: "Due: ${formatDate(todo.dueDate)}",
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),

            // ====================================================
            // ACTION BUTTONS
            // ====================================================
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => openTaskDialog(todo),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => confirmDelete(todo),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
