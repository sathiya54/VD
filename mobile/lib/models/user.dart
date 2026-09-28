class UserProfile {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? bio;
  final String? avatarUrl;
  final bool aiEnabled;
  final bool aiAllowSummary;
  final bool aiAllowImprove;
  final bool aiAllowSearch;
  final String darkModePref; // light/dark/system
  final String language;

  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.bio,
    this.avatarUrl,
    this.aiEnabled = false,
    this.aiAllowSummary = false,
    this.aiAllowImprove = false,
    this.aiAllowSearch = false,
    this.darkModePref = 'system',
    this.language = 'en',
  });

  String get displayName {
    final name = [firstName, lastName]
        .where((e) => e != null && e.trim().isNotEmpty)
        .join(' ');
    return name.isNotEmpty ? name : username;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Some payloads nest profile fields under `profile`, others flatten them.
    final profile = json['profile'] is Map
        ? Map<String, dynamic>.from(json['profile'] as Map)
        : json;
    return UserProfile(
      id: json['id'] as int? ?? profile['id'] as int? ?? 0,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      bio: profile['bio']?.toString(),
      avatarUrl: profile['avatar']?.toString() ?? profile['avatar_url']?.toString(),
      aiEnabled: profile['ai_enabled'] as bool? ?? false,
      aiAllowSummary: profile['ai_allow_summary'] as bool? ?? false,
      aiAllowImprove: profile['ai_allow_improve'] as bool? ?? false,
      aiAllowSearch: profile['ai_allow_search'] as bool? ?? false,
      darkModePref: profile['dark_mode_pref']?.toString() ?? 'system',
      language: profile['language']?.toString() ?? 'en',
    );
  }

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'bio': bio,
        'ai_enabled': aiEnabled,
        'ai_allow_summary': aiAllowSummary,
        'ai_allow_improve': aiAllowImprove,
        'ai_allow_search': aiAllowSearch,
        'dark_mode_pref': darkModePref,
        'language': language,
      };

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? bio,
    String? avatarUrl,
    bool? aiEnabled,
    bool? aiAllowSummary,
    bool? aiAllowImprove,
    bool? aiAllowSearch,
    String? darkModePref,
    String? language,
  }) {
    return UserProfile(
      id: id,
      username: username,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      aiAllowSummary: aiAllowSummary ?? this.aiAllowSummary,
      aiAllowImprove: aiAllowImprove ?? this.aiAllowImprove,
      aiAllowSearch: aiAllowSearch ?? this.aiAllowSearch,
      darkModePref: darkModePref ?? this.darkModePref,
      language: language ?? this.language,
    );
  }
}
