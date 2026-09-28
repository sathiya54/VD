class Milestone {
  final int id;
  final int goalId;
  final String title;
  final bool isDone;
  final int order;

  const Milestone({
    required this.id,
    required this.goalId,
    required this.title,
    this.isDone = false,
    this.order = 0,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
        id: json['id'] as int,
        goalId: json['goal'] as int? ?? 0,
        title: json['title']?.toString() ?? '',
        isDone: json['is_done'] as bool? ?? false,
        order: json['order'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'is_done': isDone,
        'order': order,
      };

  Milestone copyWith({String? title, bool? isDone, int? order}) => Milestone(
        id: id,
        goalId: goalId,
        title: title ?? this.title,
        isDone: isDone ?? this.isDone,
        order: order ?? this.order,
      );
}
