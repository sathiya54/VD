/// Generic wrapper for DRF-style paginated list responses:
/// {count, next, previous, results}
class PaginatedResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  const PaginatedResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  bool get hasMore => next != null;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawResults = json['results'] as List<dynamic>? ?? const [];
    return PaginatedResponse(
      count: json['count'] as int? ?? rawResults.length,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: rawResults
          .map((e) => fromJsonT(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
