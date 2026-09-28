class DiaryCategory {
  final int id;
  final String name;
  final bool isDefault;

  const DiaryCategory({
    required this.id,
    required this.name,
    this.isDefault = false,
  });

  factory DiaryCategory.fromJson(Map<String, dynamic> json) => DiaryCategory(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        isDefault: json['is_default'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {'name': name};

  // Equality by id so widgets like DropdownButtonFormField can match a
  // category value against a separately-fetched options list.
  @override
  bool operator ==(Object other) => other is DiaryCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
