class Reminder {
  final int id;
  final String title;
  final String? message;
  final DateTime remindAt;
  final String repeat; // one_time/daily/weekly/monthly
  final bool isActive;

  const Reminder({
    required this.id,
    required this.title,
    this.message,
    required this.remindAt,
    this.repeat = 'one_time',
    this.isActive = true,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as int,
        title: json['title']?.toString() ?? '',
        message: json['message']?.toString(),
        remindAt: DateTime.tryParse(json['remind_at']?.toString() ?? '') ??
            DateTime.now(),
        repeat: json['repeat']?.toString() ?? 'one_time',
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toRequestJson() => {
        'title': title,
        'message': message,
        'remind_at': remindAt.toIso8601String(),
        'repeat': repeat,
        'is_active': isActive,
      };

  Reminder copyWith({
    String? title,
    String? message,
    DateTime? remindAt,
    String? repeat,
    bool? isActive,
  }) {
    return Reminder(
      id: id,
      title: title ?? this.title,
      message: message ?? this.message,
      remindAt: remindAt ?? this.remindAt,
      repeat: repeat ?? this.repeat,
      isActive: isActive ?? this.isActive,
    );
  }
}
