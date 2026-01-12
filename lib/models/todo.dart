class Todo {
  int? id;

  /// Wajib
  String description;

  /// Optional (HB-ExeCon v1)
  final String? soNumber;
  final String? ref;
  final String priority;
  final DateTime? dueDate;
  final int? progress;

  /// Derived status
  bool isDone;

  Todo({
    this.id,
    required this.description,
    this.soNumber,
    this.ref,
    required this.priority,
    this.dueDate,
    this.progress,
    this.isDone = false,
  });

  // =====================================================
  // SQLite helper (future-proof)
  // =====================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'priority': priority,
      'so_number': soNumber,
      'ref': ref,
      'due_date': dueDate?.toIso8601String(),
      'progress': progress,
      'is_done': isDone ? 1 : 0,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      description: map['description'],
      priority: map['priority'],
      soNumber: map['so_number'],
      ref: map['ref'],
      dueDate:
          map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      progress: map['progress'],
      isDone: map['is_done'] == 1,
    );
  }
}
