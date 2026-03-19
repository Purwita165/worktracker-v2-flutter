class Todo {
  // ========================================================
  // PRIMARY KEY
  // ========================================================
  // Diisi oleh database (AUTOINCREMENT)
  int? id;

  // ========================================================
  // USER IDENTIFICATION
  // ========================================================
  // Disiapkan untuk future multi-user / sync system
  final String userId;

  //CONTEXT AND SUB CONTEXT

  final String context;
  final String? subContext;

  // ========================================================
  // CORE TASK CONTENT
  // ========================================================
  // Isi utama task (harus selalu ada)
  String description;

  // ========================================================
  // CONTEXT IDENTIFIER
  // ========================================================
  // workId → relasi ke pekerjaan / project
  // ref    → relasi ke equipment / lokasi / unit
  final String? workId;
  final String? ref;

  // ========================================================
  // PRIORITY LEVEL
  // ========================================================
  // Disarankan konsisten:
  // H = High, M = Medium, L = Low
  final String priority;

  // ========================================================
  // DEADLINE
  // ========================================================
  // Optional → tidak semua task punya deadline
  final DateTime? dueDate;

  // ========================================================
  // PROGRESS TRACKING
  // ========================================================
  // Selalu punya nilai (default = 0)
  // Hindari null → mencegah bug di UI & perhitungan
  int progress;

  // ========================================================
  // TASK DATE
  // ========================================================
  // Tanggal task dibuat oleh user (logika bisnis)
  final DateTime taskDate;

  // ========================================================
  // SYSTEM TIMESTAMP
  // ========================================================
  // createdAt → kapan data dibuat di sistem
  // updatedAt → kapan terakhir diubah
  final DateTime createdAt;
  DateTime? updatedAt;
  final DateTime? startDate;
  DateTime? startedAt;

  // ========================================================
  // COMPLETION DATA
  // ========================================================
  // completedAt → kapan task selesai
  // duration    → durasi pengerjaan (opsional)
  DateTime? completedAt;
  int? duration;

  // ========================================================
  // STATUS MANAGEMENT
  // ========================================================
  // isDone → boolean cepat untuk UI
  // status → lebih fleksibel untuk workflow
  //
  // contoh status:
  // open, in_progress, pending, done, cancelled
  bool isDone;
  String status;

  // ========================================================
  // CLASSIFICATION
  // ========================================================
  // Untuk grouping:
  // maintenance, inspection, audit, dll
  String? category;

  // ========================================================
  // ADDITIONAL NOTES
  // ========================================================
  // Catatan lapangan / remark teknisi / inspector
  String? notes;

  // ========================================================
  // CONSTRUCTOR
  // ========================================================
  // Default value penting untuk mencegah null issue
  Todo({
    this.id,
    required this.userId,
    required this.context,
    this.subContext,
    required this.description,
    this.workId,
    this.ref,
    required this.priority,
    this.dueDate,
    this.progress = 0,
    DateTime? taskDate,
    DateTime? createdAt,
    this.updatedAt,
    this.completedAt,
    this.duration,
    this.isDone = false,
    this.status = 'open',
    this.category,
    this.notes,
    this.startDate,
    this.startedAt,
  }) : taskDate = taskDate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  // ========================================================
  // OBJECT → MAP (UNTUK DATABASE)
  // ========================================================
  // Semua DateTime diubah ke ISO String
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'context': context,
      'sub_context': subContext,
      'description': description,
      'priority': priority,
      'work_id': workId,
      'ref': ref,
      'due_date': dueDate?.toIso8601String(),
      'progress': progress,
      'task_date': taskDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'duration': duration,
      'is_done': isDone ? 1 : 0,
      'status': status,
      'category': category,
      'notes': notes,
    };
  }

  // ========================================================
  // MAP → OBJECT (DARI DATABASE)
  // ========================================================
  // Handle null dengan aman (defensive programming)
  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      context: map['context'] ?? 'General',
      subContext: map['sub_context'],
      userId: map['user_id'],
      description: map['description'],
      priority: map['priority'],
      workId: map['work_id'],
      ref: map['ref'],
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      progress: map['progress'] ?? 0,
      taskDate: map['task_date'] != null
          ? DateTime.parse(map['task_date'])
          : DateTime.now(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),

      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'])
          : null,

      startedAt: map['started_at'] != null
          ? DateTime.parse(map['started_at'])
          : null,

      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'])
          : null,
      duration: map['duration'],
      isDone: map['is_done'] == 1,
      status: map['status'] ?? 'open',
      category: map['category'],
      notes: map['notes'],
    );
  }

  // ========================================================
  // COPY WITH (IMMUTABLE UPDATE)
  // ========================================================
  // Dipakai untuk update tanpa mengubah object asli
  // Penting untuk state management (Flutter best practice)
  Todo copyWith({
  int? id,
  String? userId,
  String? description,
  String? workId,
  String? ref,
  String? priority,
  DateTime? dueDate,
  int? progress,
  DateTime? taskDate,
  DateTime? startDate,
  DateTime? startedAt,
  DateTime? completedAt,
  bool? isDone,
}) {
  return Todo(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    context: context?? this.context,
    subContext: subContext?? this.subContext,
    description: description ?? this.description,
    workId: workId ?? this.workId,
    ref: ref ?? this.ref,
    priority: priority ?? this.priority,
    dueDate: dueDate ?? this.dueDate,
    progress: progress ?? this.progress,
    taskDate: taskDate ?? this.taskDate,
    startDate: startDate ?? this.startDate,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt ?? this.completedAt,
    isDone: isDone ?? this.isDone,
  );
}
}
