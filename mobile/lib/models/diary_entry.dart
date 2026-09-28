import 'category.dart';
import 'mood.dart';
import 'tag.dart';

class DiaryEntry {
  final int id;
  final String title;
  final String content;
  final String date; // yyyy-MM-dd
  final String? time; // HH:mm:ss
  final Mood? mood;
  final DiaryCategory? category;
  final List<DiaryTag> tags;
  final bool isFavorite;
  final bool isPrivate;
  final String? coverImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.time,
    this.mood,
    this.category,
    this.tags = const [],
    this.isFavorite = false,
    this.isPrivate = false,
    this.coverImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as int,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString(),
      mood: json['mood'] is Map
          ? Mood.fromJson(Map<String, dynamic>.from(json['mood'] as Map))
          : null,
      category: json['category'] is Map
          ? DiaryCategory.fromJson(
              Map<String, dynamic>.from(json['category'] as Map))
          : null,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((t) => t is Map
                  ? DiaryTag.fromJson(Map<String, dynamic>.from(t))
                  : DiaryTag(id: 0, name: t.toString()))
              .toList() ??
          const [],
      isFavorite: json['is_favorite'] as bool? ?? false,
      isPrivate: json['is_private'] as bool? ?? false,
      coverImageUrl: json['cover_image']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  /// Builds the request body for create/update. Tags are sent as ids.
  Map<String, dynamic> toRequestJson({List<int>? tagIds}) => {
        'title': title,
        'content': content,
        'date': date,
        if (time != null) 'time': time,
        if (mood != null) 'mood': mood!.id,
        if (category != null) 'category': category!.id,
        'tags': tagIds ?? tags.map((t) => t.id).toList(),
        'is_favorite': isFavorite,
        'is_private': isPrivate,
      };

  DiaryEntry copyWith({
    String? title,
    String? content,
    String? date,
    String? time,
    Mood? mood,
    DiaryCategory? category,
    List<DiaryTag>? tags,
    bool? isFavorite,
    bool? isPrivate,
    String? coverImageUrl,
  }) {
    return DiaryEntry(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      time: time ?? this.time,
      mood: mood ?? this.mood,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      isPrivate: isPrivate ?? this.isPrivate,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
