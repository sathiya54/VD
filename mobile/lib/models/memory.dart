class Memory {
  final int id;
  final String title;
  final String? fileUrl;
  final String memoryType; // photo/document/screenshot/certificate/project_file
  final DateTime? takenAt;
  final DateTime? createdAt;

  const Memory({
    required this.id,
    required this.title,
    this.fileUrl,
    this.memoryType = 'photo',
    this.takenAt,
    this.createdAt,
  });

  factory Memory.fromJson(Map<String, dynamic> json) => Memory(
        id: json['id'] as int,
        title: json['title']?.toString() ?? '',
        fileUrl: json['file']?.toString(),
        memoryType: json['memory_type']?.toString() ?? 'photo',
        takenAt: json['taken_at'] != null
            ? DateTime.tryParse(json['taken_at'].toString())
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );

  bool get isImage => memoryType == 'photo' || memoryType == 'screenshot';
}
