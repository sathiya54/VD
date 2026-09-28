import 'package:flutter/foundation.dart';

import '../models/memory.dart';
import '../services/memories_service.dart';

class MemoriesProvider extends ChangeNotifier {
  MemoriesProvider({MemoriesService? service})
      : _service = service ?? MemoriesService();

  final MemoriesService _service;

  List<Memory> memories = [];
  bool isLoading = false;
  bool isUploading = false;
  String? errorMessage;
  bool _hasMore = true;
  int _page = 1;

  bool get hasMore => _hasMore;

  Future<void> loadInitial() async {
    isLoading = true;
    _page = 1;
    notifyListeners();
    final result = await _service.list(page: _page);
    result.when(
      success: (page) {
        memories = page.results;
        _hasMore = page.hasMore;
      },
      failure: (error) => errorMessage = error.message,
    );
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final nextPage = _page + 1;
    final result = await _service.list(page: nextPage);
    result.when(
      success: (page) {
        memories = [...memories, ...page.results];
        _hasMore = page.hasMore;
        _page = nextPage;
      },
      failure: (error) => errorMessage = error.message,
    );
    notifyListeners();
  }

  Future<bool> upload({
    required String title,
    required String filePath,
    required String memoryType,
    DateTime? takenAt,
  }) async {
    isUploading = true;
    notifyListeners();
    final result = await _service.upload(
      title: title,
      filePath: filePath,
      memoryType: memoryType,
      takenAt: takenAt,
    );
    final success = result.when(
      success: (memory) {
        memories = [memory, ...memories];
        return true;
      },
      failure: (error) {
        errorMessage = error.message;
        return false;
      },
    );
    isUploading = false;
    notifyListeners();
    return success;
  }

  Future<bool> delete(int id) async {
    final result = await _service.delete(id);
    return result.when(
      success: (_) {
        memories = memories.where((m) => m.id != id).toList();
        notifyListeners();
        return true;
      },
      failure: (_) => false,
    );
  }
}
