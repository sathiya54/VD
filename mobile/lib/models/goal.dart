import 'milestone.dart';

class Goal {
  final int id;
  final String title;
  final String? description;
  final String startDate; // yyyy-MM-dd
  final String? targetDate;
  final String priority; // low/medium/high
  final int progress; // 0-100
  final String status; // not_started/in_progress/completed/abandoned
  final List<Milestone> milestones;

  const Goal({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    this.targetDate,
    this.priority = 'medium',
    this.progress = 0,
    this.status = 'not_started',
    this.milestones = const [],
  });

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] as int,
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString(),
        startDate: json['start_date']?.toString() ?? '',
        targetDate: json['target_date']?.toString(),
        priority: json['priority']?.toString() ?? 'medium',
        progress: (json['progress'] as num?)?.toInt() ?? 0,
        status: json['status']?.toString() ?? 'not_started',
        milestones: (json['milestones'] as List<dynamic>?)
                ?.map((m) => Milestone.fromJson(Map<String, dynamic>.from(m)))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toRequestJson() => {
        'title': title,
        'description': description,
        'start_date': startDate,
        'target_date': targetDate,
        'priority': priority,
        'progress': progress,
        'status': status,
      };

  Goal copyWith({
    String? title,
    String? description,
    String? startDate,
    String? targetDate,
    String? priority,
    int? progress,
    String? status,
    List<Milestone>? milestones,
  }) {
    return Goal(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      priority: priority ?? this.priority,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      milestones: milestones ?? this.milestones,
    );
  }
}
