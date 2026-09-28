class DiaryTag {
  final int id;
  final String name;

  const DiaryTag({required this.id, required this.name});

  factory DiaryTag.fromJson(Map<String, dynamic> json) => DiaryTag(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {'name': name};
}
