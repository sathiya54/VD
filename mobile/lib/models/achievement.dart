class Achievement {
  final int id;
  final String title;
  final String description;
  final DateTime? achievedAt;
  final String? icon;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.achievedAt,
    this.icon,
  });

  bool get isUnlocked => achievedAt != null;

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'] as int,
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        achievedAt: json['achieved_at'] != null
            ? DateTime.tryParse(json['achieved_at'].toString())
            : null,
        icon: json['icon']?.toString(),
      );
}
