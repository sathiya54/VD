import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/goal.dart';
import '../../providers/goals_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/priority_chip.dart';

class GoalDetailScreen extends StatefulWidget {
  const GoalDetailScreen({super.key, required this.goalId});

  final int goalId;

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final _milestoneController = TextEditingController();

  @override
  void dispose() {
    _milestoneController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(Goal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text('This will permanently remove "${goal.title}".'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<GoalsProvider>().deleteGoal(goal.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GoalsProvider>();
    final matches = provider.goals.where((g) => g.id == widget.goalId);
    if (matches.isEmpty) {
      return const Scaffold(body: LoadingIndicator());
    }
    final goal = matches.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.title),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _confirmDelete(goal)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              PriorityChip(priority: goal.priority),
              const SizedBox(width: 8),
              Chip(label: Text(goal.status.replaceAll('_', ' '))),
            ],
          ),
          const SizedBox(height: 16),
          if (goal.description != null && goal.description!.isNotEmpty) ...[
            Text(goal.description!, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
          ],
          Text('Progress', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: goal.progress / 100, minHeight: 8),
          const SizedBox(height: 4),
          Text('${goal.progress}%'),
          const SizedBox(height: 8),
          Slider(
            value: goal.progress.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            label: '${goal.progress}%',
            onChanged: (v) {
              context
                  .read<GoalsProvider>()
                  .updateGoal(goal.id, goal.copyWith(progress: v.round()));
            },
          ),
          const SizedBox(height: 8),
          Text('Start: ${goal.startDate}'),
          if (goal.targetDate != null) Text('Target: ${goal.targetDate}'),
          const Divider(height: 32),
          Text('Milestones', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...goal.milestones.map(
            (m) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: m.isDone,
              title: Text(
                m.title,
                style: TextStyle(decoration: m.isDone ? TextDecoration.lineThrough : null),
              ),
              secondary: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () =>
                    context.read<GoalsProvider>().deleteMilestone(goal.id, m.id),
              ),
              onChanged: (_) =>
                  context.read<GoalsProvider>().toggleMilestone(goal.id, m),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _milestoneController,
                  decoration: const InputDecoration(hintText: 'Add a milestone'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: () {
                  final text = _milestoneController.text.trim();
                  if (text.isEmpty) return;
                  context.read<GoalsProvider>().addMilestone(goal.id, text);
                  _milestoneController.clear();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
