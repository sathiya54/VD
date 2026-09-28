class Mood {
  final int id;
  final String name;
  final String emoji;

  const Mood({required this.id, required this.name, required this.emoji});

  factory Mood.fromJson(Map<String, dynamic> json) => Mood(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        emoji: json['emoji']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'emoji': emoji};
}
