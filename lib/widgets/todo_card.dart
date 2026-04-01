import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../utils/format_helper.dart';

DateTime normalize(DateTime d) {
  return DateTime(d.year, d.month, d.day);
}

class TodoCard extends StatelessWidget {
  final Todo todo;
  final bool isOverdue;

  final void Function(Todo) toggleTodo;
  final void Function(Todo) openTaskDialog;
  final void Function(Todo) confirmDelete;

  final Map<String, String> priorityLabels;
  final Color Function(String) getPriorityColor;

  final Color Function(Todo) getStartDateColor;

  final Function(Todo) onStart;

  final Duration Function(Todo) getRemainingTime;
  final String Function(Duration) formatRemaining;

  final String Function(Todo) getCompletionStatus;
  final Color Function(Todo) getCompletionStatusColor;

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
    required this.getCompletionStatus,
    required this.getCompletionStatusColor,
  });

  String formatDate(DateTime? date) {
    if (date == null) return "-";
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  String getStartStatus(Todo todo) {
    if (todo.startDate == null || todo.startedAt == null) return "";

    final diff = todo.startedAt!.difference(todo.startDate!).inDays;

    if (diff == 0) return " (On time)";
    if (diff > 0) return " (Delay ${diff}d)";
    return " (Early ${-diff}d)";
  }

  String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return "${h}h ${m}m ${s}s";
  }

  String getStartDeltaLabel() {
    if (todo.startDate == null || todo.startedAt == null) return "";

    final start = normalize(todo.startDate!);
    final started = normalize(todo.startedAt!);

    final diff = started.difference(start).inDays;

    if (diff == 0) return "(on time)";
    if (diff < 0) return "(${diff.abs()}d early)";
    return "(+${diff}d late)";
  }

  Color getStartDeltaColor() {
    if (todo.startDate == null || todo.startedAt == null) {
      return Colors.grey;
    }

    final diff = todo.startedAt!.difference(todo.startDate!);

    if (diff.inDays == 0) return Colors.blue;
    if (diff.isNegative) return Colors.green;
    return Colors.orange;
  }

  Duration getRunningDuration() {
    if (todo.startedAt == null) return Duration.zero;
    return DateTime.now().difference(todo.startedAt!);
  }

  String formatYMD(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  String daysBetween(DateTime a, DateTime b) {
    final da = DateTime(a.year, a.month, a.day);
    final db = DateTime(b.year, b.month, b.day);
    return (db.difference(da).inDays).toString();
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
            Checkbox(value: todo.isDone, onChanged: (_) => toggleTodo(todo)),

            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== 1. DESCRIPTION =====
                  Text(
                    todo.description ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: getScheduleColor(
                        todo.startDate,
                        todo.dueDate,
                        todo.startedAt,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ===== 2. WORK INFO =====
                  if (todo.context == "Office" && todo.subContext == "Project")
                    Text(
                      "${todo.workId ?? '-'}, Reg: ${todo.seq ?? '-'} | ${todo.task ?? '-'}",
                      style: smallText.copyWith(
                        color: todo.isDone ? Colors.grey : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                  const SizedBox(height: 6),

                  // ===== 3. DATE INFO (🔥 INI YANG BARU) =====
                  if (!todo.isDone)
                    Text(
                      buildDateInfo(
                        startDate: todo.startDate,
                        dueDate: todo.dueDate,
                        startedAt: todo.startedAt,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: getScheduleColor(
                          todo.startDate,
                          todo.dueDate,
                          todo.startedAt,
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Completed: ${formatDate(todo.completedAt)}",
                          style: smallText.copyWith(color: Colors.green),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          getCompletionStatus(todo),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: getCompletionStatusColor(todo),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 6),

                  // ===== 4. PROGRESS =====
                  if (!todo.isDone) ...[
                    Text("Progress: ${todo.progress ?? 0}%", style: smallText),

                    const SizedBox(height: 4),

                    LinearProgressIndicator(
                      value: (todo.progress ?? 0) / 100,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.blue,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ACTION BUTTONS
            Column(
              children: [
                if (!todo.isDone)
                  IconButton(
                    icon: Icon(
                      todo.startedAt == null ? Icons.play_arrow : Icons.pause,
                      size: 18,
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
