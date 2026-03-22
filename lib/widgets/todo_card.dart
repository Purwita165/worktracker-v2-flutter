import 'package:flutter/material.dart';
import '../models/todo.dart';

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
                  // TITLE
                  Text(
                    todo.description,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: todo.isDone
                          ? Colors.grey
                          : (isOverdue ? Colors.red : getStartDateColor(todo)),
                      decoration: todo.isDone
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ================= META =================
                  if (todo.context == "Office" && todo.subContext == "Project")
                    RichText(
                      text: TextSpan(
                        style: smallText.copyWith(
                          color: todo.isDone ? Colors.grey : Colors.black,
                        ),
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
                    )
                  else if (todo.context == "Office" &&
                      todo.subContext == "General")
                    RichText(
                      text: TextSpan(
                        style: smallText.copyWith(
                          color: todo.isDone ? Colors.grey : Colors.black,
                        ),
                        children: [
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
                    )
                  else
                    RichText(
                      text: TextSpan(
                        style: smallText.copyWith(
                          color: todo.isDone ? Colors.grey : Colors.black,
                        ),
                        children: [
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

                  // ================= STATUS =================
                  if (!todo.isDone) ...[
                    // -------- GENERAL --------
                    if (todo.context == "Office" &&
                        todo.subContext == "General") ...[
                      Text(
                        "Due: ${formatDate(todo.dueDate)}",
                        style: smallText,
                      ),

                      const SizedBox(height: 4),

                      Builder(
                        builder: (_) {
                          final now = DateTime.now();
                          final start = todo.startDate;
                          final due = todo.dueDate;

                          String formatYMD(DateTime d) =>
                              "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

                          int daysBetween(DateTime a, DateTime b) {
                            final da = DateTime(a.year, a.month, a.day);
                            final db = DateTime(b.year, b.month, b.day);
                            return db.difference(da).inDays;
                          }

                          if (start != null && now.isBefore(start)) {
                            final days = daysBetween(now, start);
                            return Text(
                              "Starts in $days d (${formatYMD(start)})",
                              style: smallText.copyWith(color: Colors.blueGrey),
                            );
                          }

                          if (due != null) {
                            if (now.isAfter(due)) {
                              final days = daysBetween(due, now);
                              return Text(
                                "Overdue $days d",
                                style: smallText.copyWith(color: Colors.red),
                              );
                            } else {
                              final days = daysBetween(now, due);
                              return Text(
                                "Remaining $days d",
                                style: smallText.copyWith(color: Colors.green),
                              );
                            }
                          }

                          return Text(
                            "No schedule",
                            style: smallText.copyWith(color: Colors.grey),
                          );
                        },
                      ),
                    ]
                    // -------- PROJECT --------
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (todo.startedAt != null)
                                  Text(
                                    "Started: ${formatDate(todo.startedAt)}",
                                    style: smallText,
                                  ),
                                if (todo.dueDate != null)
                                  Text(
                                    "Due: ${formatDate(todo.dueDate)}",
                                    style: smallText,
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (todo.startedAt != null)
                                  Text(
                                    "Running: ${formatDuration(getRunningDuration())}",
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
                    ],
                  ] else ...[
                    // -------- COMPLETED --------
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Start: ${formatDate(todo.startDate)}",
                                style: smallText,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "Due: ${formatDate(todo.dueDate)}",
                                style: smallText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Completed: ${formatDate(todo.completedAt)}",
                                style: smallText.copyWith(color: Colors.green),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                todo.startedAt != null &&
                                        todo.completedAt != null
                                    ? "Duration: ${formatDuration(todo.completedAt!.difference(todo.startedAt!))}"
                                    : "Duration: -",
                                style: smallText,
                              ),
                            ),
                          ],
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
