class Todo {
  // =============================================================
  // FIELDS (DATABASE COLUMNS)
  // =============================================================

  int? id;
  String description;
  String? ref;

  /// Priority:
  /// 1 = Low
  /// 2 = Moderate
  /// 3 = High
  int priority;

  /// Completion status:
  /// 0 = Not done
  /// 1 = Done
  int isDone;

  /// Due date (nullable)
  DateTime? dueDate;

  // =============================================================
  // CONSTRUCTOR
  // =============================================================

  Todo({
    this.id,
    required this.description,
    this.ref,
    required this.priority,
    required this.isDone,
    this.dueDate,
  });

  // =============================================================
  // OBJECT → DATABASE (INSERT / UPDATE)
  // =============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'ref': ref,
      'priority': priority,
      'isDone': isDone,
      'due_date': dueDate?.toIso8601String(),
    };
  }

  // =============================================================
  // DATABASE → OBJECT (SELECT)
  // =============================================================

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      description: map['description'],
      ref: map['ref'],
      priority: map['priority'] ?? 1,
      isDone: map['isDone'] ?? 0,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'])
          : null,
    );
  }
}
