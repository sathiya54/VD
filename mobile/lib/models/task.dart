class DiaryTask {
  final int id;
  final String title;
  final String? description;
  final String? dueDate; // yyyy-MM-dd
  final String priority; // low/medium/high
  final bool isDone;
  final int? goalId;
  final int? diaryEntryId;

  const DiaryTask({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.priority = 'medium',
    this.isDone = false,
    this.goalId,
    this.diaryEntryId,
  });

  factory DiaryTask.fromJson(Map<String, dynamic> json) => DiaryTask(
        id: json['id'] as int,
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString(),
        dueDate: json['due_date']?.toString(),
        priority: json['priority']?.toString() ?? 'medium',
        isDone: json['is_done'] as bool? ?? false,
        goalId: json['goal'] as int?,
        diaryEntryId: json['diary_entry'] as int?,
      );

  Map<String, dynamic> toRequestJson() => {
        'title': title,
        'description': description,
        'due_date': dueDate,
        'priority': priority,
        'is_done': isDone,
        'goal': goalId,
        'diary_entry': diaryEntryId,
      };

  DiaryTask copyWith({
    String? title,
    String? description,
    String? dueDate,
    String? priority,
    bool? isDone,
    int? goalId,
    int? diaryEntryId,
  }) {
    return DiaryTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      goalId: goalId ?? this.goalId,
      diaryEntryId: diaryEntryId ?? this.diaryEntryId,
    );
  }
}
