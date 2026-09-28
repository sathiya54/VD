import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/diary_provider.dart';
import '../../services/diary_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/entry_card.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import 'diary_detail_screen.dart';
import 'diary_editor_screen.dart';

class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({super.key, this.initialFavoriteOnly = false});

  final bool initialFavoriteOnly;

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _categoryFilter;
  String? _moodFilter;
  bool _favoriteOnly = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _favoriteOnly = widget.initialFavoriteOnly;
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 200) {
        context.read<DiaryProvider>().loadMore();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<DiaryProvider>();
        provider.loadMeta();
        _applyFilters();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<DiaryProvider>().applyFilters(DiaryFilters(
          category: _categoryFilter,
          mood: _moodFilter,
          favorite: _favoriteOnly ? true : null,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiaryProvider>();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search entries...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _applyFilters(),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  label: const Text('Favorites'),
                  selected: _favoriteOnly,
                  onSelected: (v) {
                    setState(() => _favoriteOnly = v);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                ...provider.categories.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(c.name),
                      selected: _categoryFilter == c.name,
                      onSelected: (v) {
                        setState(() => _categoryFilter = v ? c.name : null);
                        _applyFilters();
                      },
                    ),
                  ),
                ),
                ...provider.moods.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('${m.emoji} ${m.name}'),
                      selected: _moodFilter == m.name,
                      onSelected: (v) {
                        setState(() => _moodFilter = v ? m.name : null);
                        _applyFilters();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(provider)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DiaryEditorScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
      ),
    );
  }

  Widget _buildBody(DiaryProvider provider) {
    if (provider.state == LoadState.loading) {
      return const LoadingIndicator(message: 'Loading entries...');
    }
    if (provider.state == LoadState.error && provider.entries.isEmpty) {
      return ErrorView(
        message: provider.errorMessage ?? 'Failed to load entries.',
        onRetry: _applyFilters,
      );
    }
    if (provider.entries.isEmpty) {
      return EmptyState(
        icon: Icons.book_outlined,
        title: 'No entries yet',
        message: 'Start journaling by tapping "New Entry" below.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _applyFilters(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        itemCount: provider.entries.length + (provider.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= provider.entries.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final entry = provider.entries[index];
          return EntryCard(
            entry: entry,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DiaryDetailScreen(entryId: entry.id)),
            ),
            onFavoriteToggle: () => provider.toggleFavorite(entry.id),
          );
        },
      ),
    );
  }
}
