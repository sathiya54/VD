import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/diary_provider.dart';
import '../../widgets/empty_state.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiaryProvider>().loadTrash();
    });
  }

  Future<void> _confirmPermanentDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete forever?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<DiaryProvider>().permanentDelete(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiaryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Trash')),
      body: provider.trashEntries.isEmpty
          ? const EmptyState(
              icon: Icons.delete_outline,
              title: 'Trash is empty',
              message: 'Deleted entries appear here for 30 days before permanent removal.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.trashEntries.length,
              itemBuilder: (context, index) {
                final entry = provider.trashEntries[index];
                return Card(
                  child: ListTile(
                    title: Text(entry.title.isNotEmpty ? entry.title : '(untitled)'),
                    subtitle: Text(DateFormat('MMM d, yyyy').format(
                        DateTime.tryParse(entry.date) ?? DateTime.now())),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restore),
                          tooltip: 'Restore',
                          onPressed: () =>
                              context.read<DiaryProvider>().restoreEntry(entry.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever_outlined),
                          tooltip: 'Delete forever',
                          onPressed: () => _confirmPermanentDelete(entry.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
