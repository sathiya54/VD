import 'package:flutter/foundation.dart';

import '../services/analytics_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsProvider({AnalyticsService? service})
      : _service = service ?? AnalyticsService();

  final AnalyticsService _service;

  AnalyticsSummary summary = const AnalyticsSummary();
  List<OnThisDayEntry> onThisDay = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    final summaryResult = await _service.summary();
    summaryResult.when(
      success: (s) => summary = s,
      failure: (error) => errorMessage = error.message,
    );

    final onThisDayResult = await _service.onThisDay();
    onThisDayResult.when(
      success: (list) => onThisDay = list,
      failure: (_) {},
    );

    isLoading = false;
    notifyListeners();
  }
}
