class DiaryEvent {
  final int id;
  final String title;
  final String? description;
  final DateTime startDatetime;
  final DateTime? endDatetime;
  final bool allDay;
  final String? location;

  const DiaryEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startDatetime,
    this.endDatetime,
    this.allDay = false,
    this.location,
  });

  factory DiaryEvent.fromJson(Map<String, dynamic> json) => DiaryEvent(
        id: json['id'] as int,
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString(),
        startDatetime:
            DateTime.tryParse(json['start_datetime']?.toString() ?? '') ??
                DateTime.now(),
        endDatetime: json['end_datetime'] != null
            ? DateTime.tryParse(json['end_datetime'].toString())
            : null,
        allDay: json['all_day'] as bool? ?? false,
        location: json['location']?.toString(),
      );

  Map<String, dynamic> toRequestJson() => {
        'title': title,
        'description': description,
        'start_datetime': startDatetime.toIso8601String(),
        'end_datetime': endDatetime?.toIso8601String(),
        'all_day': allDay,
        'location': location,
      };

  DiaryEvent copyWith({
    String? title,
    String? description,
    DateTime? startDatetime,
    DateTime? endDatetime,
    bool? allDay,
    String? location,
  }) {
    return DiaryEvent(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDatetime: startDatetime ?? this.startDatetime,
      endDatetime: endDatetime ?? this.endDatetime,
      allDay: allDay ?? this.allDay,
      location: location ?? this.location,
    );
  }
}
