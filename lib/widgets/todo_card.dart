import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

DateTime normalize(DateTime d) {
  return DateTime(d.year, d.month, d.day);
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
  // ================= DATA DARI PARENT =================
  final Map<String, String> priorityLabels;
  final Color Function(String) getPriorityColor;

  final Color Function(Todo) getStartDateColor;

  final Function(Todo) onStart;

  final Duration Function(Todo) getRemainingTime;
  final String Function(Duration) formatRemaining;

  const TodoCard({
    super.key,
    required this.todo,
    required this.isOverdue,
    required this.toggleTodo,
    required this.openTaskDialog,
    required this.confirmDelete,
    required this.priorityLabels,
    required this.getPriorityColor,
    required this.getStartDateColor,
    required this.onStart,
    required this.getRemainingTime,
    required this.formatRemaining,
  });

  // ============================================================
  // LOCAL HELPER (BIAR TIDAK TERGANTUNG PAGE)
  // ============================================================

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

  String getStartDeltaLabel(Todo todo) {
    if (todo.startDate == null || todo.startedAt == null) return "";

    final start = normalize(todo.startDate!);
    final started = normalize(todo.startedAt!);

    final diff = started.difference(start).inDays;

    if (diff == 0) return "(on time)";
    if (diff < 0) return "(${diff.abs()}d early)";
    return "(+${diff}d late)";
  }

  Duration getRunningDuration(Todo todo) {
    if (todo.startedAt == null) return Duration.zero;

    return DateTime.now().difference(todo.startedAt!);
  }

  String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;

    return "${h}h ${m}m ${s}s";
  }

  Color getStartDeltaColor(Todo todo) {
    if (todo.startDate == null || todo.startedAt == null) {
      return Colors.grey;
    }

    final start = normalize(todo.startDate!);
    final started = normalize(todo.startedAt!);

    final diff = started.difference(start).inDays;

    if (diff == 0) return Colors.blue; // on time
    if (diff < 0) return Colors.green; // early
    return Colors.orange; // late
  }

  @override
  Widget build(BuildContext context) {
    const smallText = TextStyle(fontSize: 12);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      child: Padding(
        padding: const EdgeInsets.all(12),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= CHECKBOX =================
            Checkbox(value: todo.isDone, onChanged: (_) => toggleTodo(todo)),

            const SizedBox(width: 8),

            // ================= CONTENT =================
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
                      color: isOverdue ? Colors.red : getStartDateColor(todo),
                      decoration: todo.isDone
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ================= META =================
                  RichText(
                    text: TextSpan(
                      style: smallText.copyWith(color: Colors.black),
                      children: [
                        TextSpan(text: "WorkID: ${todo.workId ?? '-'}   "),
                        TextSpan(text: "Ref: ${todo.ref ?? '-'}   "),
                        const TextSpan(text: "Priority: "),
                        TextSpan(
                          text: priorityLabels[todo.priority] ?? "-",
                          style: TextStyle(
                            color: getPriorityColor(todo.priority),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ================= TIME GRID =================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (todo.startedAt != null)
                              Text(
                                "Started: ${formatDate(todo.startedAt)} ${getStartDeltaLabel(todo)}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: getStartDeltaColor(
                                    todo,
                                  ).withOpacity(0.9),
                                ),
                              ),

                            if (todo.dueDate != null)
                              Text(
                                "Due: ${formatDate(todo.dueDate)}",
                                style: smallText,
                              ),
                          ],
                        ),
                      ),

                      // RIGHT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (todo.startedAt != null && !todo.isDone)
                              Text(
                                "Running: ${formatDuration(getRunningDuration(todo))}",
                                style: smallText,
                              ),

                            if (todo.dueDate != null)
                              Text(
                                getRemainingTime(todo).isNegative
                                    ? "Overdue: ${formatRemaining(getRemainingTime(todo))}"
                                    : "Remaining: ${formatRemaining(getRemainingTime(todo))}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: getRemainingTime(todo).isNegative
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ================= PROGRESS =================
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Progress: ${todo.progress}%", style: smallText),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: todo.progress / 100,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4),
                        backgroundColor: Colors.grey.shade300,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ================= ACTION =================
            Column(
              children: [
                IconButton(
                  icon: Icon(
                    todo.startedAt == null ? Icons.play_arrow : Icons.pause, size:18,
                    color: Colors.green,
                  ),
                  onPressed: () => onStart(todo),
                ),

                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => openTaskDialog(todo),
                ),

                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
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
