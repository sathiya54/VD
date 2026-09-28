import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/mood.dart';

/// A horizontal picker for mood selection. Falls back to
/// [AppConstants.defaultMoods] when the live moods list from the API hasn't
/// loaded yet (ids will be 0 in that case and should be re-resolved before
/// submitting if possible).
class MoodPicker extends StatelessWidget {
  const MoodPicker({
    super.key,
    required this.moods,
    required this.selected,
    required this.onSelected,
  });

  final List<Mood> moods;
  final Mood? selected;
  final ValueChanged<Mood> onSelected;

  @override
  Widget build(BuildContext context) {
    final effectiveMoods = moods.isNotEmpty
        ? moods
        : AppConstants.defaultMoods
            .asMap()
            .entries
            .map((e) => Mood(id: e.key + 1, name: e.value['name']!, emoji: e.value['emoji']!))
            .toList();

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: effectiveMoods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final mood = effectiveMoods[index];
          final isSelected = selected?.id == mood.id;
          final theme = Theme.of(context);
          return GestureDetector(
            onTap: () => onSelected(mood),
            child: Container(
              width: 68,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(mood.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 4),
                  Text(
                    mood.name,
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
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
