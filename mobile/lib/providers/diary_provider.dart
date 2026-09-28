import 'package:flutter/foundation.dart';

import '../models/category.dart';
import '../models/diary_entry.dart';
import '../models/mood.dart';
import '../models/tag.dart';
import '../services/diary_service.dart';

enum LoadState { idle, loading, loadingMore, loaded, error }

class DiaryProvider extends ChangeNotifier {
  DiaryProvider({DiaryService? service}) : _service = service ?? DiaryService();

  final DiaryService _service;

  List<DiaryEntry> entries = [];
  List<DiaryEntry> trashEntries = [];
  List<DiaryCategory> categories = [];
  List<DiaryTag> tags = [];
  List<Mood> moods = [];
  String? todaysPrompt;

  DiaryFilters filters = const DiaryFilters();
  int _page = 1;
  bool _hasMore = true;
  LoadState state = LoadState.idle;
  String? errorMessage;

  bool get hasMore => _hasMore;

  Future<void> loadInitial() async {
    state = LoadState.loading;
    notifyListeners();
    _page = 1;
    final result = await _service.list(page: _page, filters: filters);
    result.when(
      success: (page) {
        entries = page.results;
        _hasMore = page.hasMore;
        state = LoadState.loaded;
      },
      failure: (error) {
        errorMessage = error.message;
        state = LoadState.error;
      },
    );
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!_hasMore || state == LoadState.loadingMore) return;
    state = LoadState.loadingMore;
    notifyListeners();
    final nextPage = _page + 1;
    final result = await _service.list(page: nextPage, filters: filters);
    result.when(
      success: (page) {
        entries = [...entries, ...page.results];
        _hasMore = page.hasMore;
        _page = nextPage;
        state = LoadState.loaded;
      },
      failure: (error) {
        errorMessage = error.message;
        state = LoadState.loaded; // keep existing list visible
      },
    );
    notifyListeners();
  }

  Future<void> applyFilters(DiaryFilters newFilters) async {
    filters = newFilters;
    await loadInitial();
  }

  Future<void> loadMeta() async {
    final catResult = await _service.categories();
    catResult.when(success: (c) => categories = c, failure: (_) {});
    final tagResult = await _service.tags();
    tagResult.when(success: (t) => tags = t, failure: (_) {});
    final moodResult = await _service.moods();
    moodResult.when(success: (m) => moods = m, failure: (_) {});
    final promptResult = await _service.todaysPrompt();
    promptResult.when(success: (p) => todaysPrompt = p, failure: (_) {});
    notifyListeners();
  }

  Future<DiaryEntry?> createEntry(DiaryEntry entry,
      {List<int>? tagIds, String? coverImagePath}) async {
    final result =
        await _service.create(entry, tagIds: tagIds, coverImagePath: coverImagePath);
    return result.when(
      success: (created) {
        entries = [created, ...entries];
        notifyListeners();
        return created;
      },
      failure: (error) {
        errorMessage = error.message;
        notifyListeners();
        return null;
      },
    );
  }

  Future<DiaryEntry?> updateEntry(int id, DiaryEntry entry,
      {List<int>? tagIds, String? coverImagePath}) async {
    final result =
        await _service.update(id, entry, tagIds: tagIds, coverImagePath: coverImagePath);
    return result.when(
      success: (updated) {
        entries = entries.map((e) => e.id == id ? updated : e).toList();
        notifyListeners();
        return updated;
      },
      failure: (error) {
        errorMessage = error.message;
        notifyListeners();
        return null;
      },
    );
  }

  Future<bool> deleteEntry(int id) async {
    final result = await _service.delete(id);
    return result.when(
      success: (_) {
        entries = entries.where((e) => e.id != id).toList();
        notifyListeners();
        return true;
      },
      failure: (error) {
        errorMessage = error.message;
        notifyListeners();
        return false;
      },
    );
  }

  Future<void> toggleFavorite(int id) async {
    final result = await _service.toggleFavorite(id);
    result.when(
      success: (updated) {
        entries = entries.map((e) => e.id == id ? updated : e).toList();
        notifyListeners();
      },
      failure: (_) {},
    );
  }

  Future<void> loadTrash() async {
    final result = await _service.trash();
    result.when(
      success: (page) {
        trashEntries = page.results;
        notifyListeners();
      },
      failure: (error) {
        errorMessage = error.message;
        notifyListeners();
      },
    );
  }

  Future<bool> restoreEntry(int id) async {
    final result = await _service.restore(id);
    return result.when(
      success: (_) {
        trashEntries = trashEntries.where((e) => e.id != id).toList();
        notifyListeners();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> permanentDelete(int id) async {
    final result = await _service.permanentDelete(id);
    return result.when(
      success: (_) {
        trashEntries = trashEntries.where((e) => e.id != id).toList();
        notifyListeners();
        return true;
      },
      failure: (_) => false,
    );
  }
}
