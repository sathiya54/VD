import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/diary_entry.dart';
import '../../providers/diary_provider.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import 'diary_editor_screen.dart';

class DiaryDetailScreen extends StatefulWidget {
  const DiaryDetailScreen({super.key, required this.entryId});

  final int entryId;

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  DiaryEntry? _entry;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final provider = context.read<DiaryProvider>();
    // Prefer the already-loaded copy from the list (keeps favorite state in
    // sync), otherwise fetch fresh.
    final cached = provider.entries.where((e) => e.id == widget.entryId);
    if (cached.isNotEmpty) {
      setState(() {
        _entry = cached.first;
        _isLoading = false;
      });
      return;
    }
    // Not in the cached list (e.g. opened from search): fetch it directly.
    setState(() => _isLoading = false);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to trash?'),
        content: const Text('This entry will be moved to Trash and can be restored later.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final ok = await context.read<DiaryProvider>().deleteEntry(widget.entryId);
      if (ok && mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiaryProvider>();
    final matches = provider.entries.where((e) => e.id == widget.entryId);
    final entry = matches.isNotEmpty ? matches.first : _entry;

    if (_isLoading) {
      return const Scaffold(body: LoadingIndicator());
    }
    if (entry == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: _error ?? 'Entry not found.', onRetry: _load),
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: entry.isFavorite ? Colors.redAccent : null),
            onPressed: () => context.read<DiaryProvider>().toggleFavorite(entry.id),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Share.share('${entry.title}\n\n${entry.content}'),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DiaryEditorScreen(existingEntry: entry)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (entry.coverImageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: entry.coverImageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),
          Text(entry.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              if (entry.mood != null) ...[
                Text(entry.mood!.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(entry.mood!.name),
                const SizedBox(width: 16),
              ],
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: Theme.of(context).colorScheme.outline),
              const SizedBox(width: 4),
              Text(DateFormat('MMM d, yyyy').format(
                  DateTime.tryParse(entry.date) ?? DateTime.now())),
            ],
          ),
          if (entry.category != null) ...[
            const SizedBox(height: 8),
            Chip(label: Text(entry.category!.name)),
          ],
          if (entry.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: entry.tags.map((t) => Chip(label: Text(t.name))).toList(),
            ),
          ],
          const Divider(height: 32),
          Text(entry.content, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
