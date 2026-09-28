import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/diary_entry.dart';

class EntryCard extends StatelessWidget {
  const EntryCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.onFavoriteToggle,
  });

  final DiaryEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  String _formattedDate() {
    final parsed = DateTime.tryParse(entry.date);
    if (parsed == null) return entry.date;
    return DateFormat('MMM d, yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.coverImageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: entry.coverImageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 56,
                      height: 56,
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 56,
                      height: 56,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ] else if (entry.mood != null) ...[
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(entry.mood!.emoji, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.title.isNotEmpty ? entry.title : '(untitled entry)',
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onFavoriteToggle != null)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: entry.isFavorite ? Colors.redAccent : null,
                              size: 20,
                            ),
                            onPressed: onFavoriteToggle,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.content,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.outline),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 13, color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(_formattedDate(), style: theme.textTheme.labelSmall),
                        if (entry.category != null) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.folder_outlined,
                              size: 13, color: theme.colorScheme.outline),
                          const SizedBox(width: 4),
                          Text(entry.category!.name, style: theme.textTheme.labelSmall),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
