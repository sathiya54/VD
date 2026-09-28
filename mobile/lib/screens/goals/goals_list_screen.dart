import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/goal.dart';
import '../../providers/goals_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/priority_chip.dart';
import 'goal_detail_screen.dart';

class GoalsListScreen extends StatefulWidget {
  const GoalsListScreen({super.key});

  @override
  State<GoalsListScreen> createState() => _GoalsListScreenState();
}

class _GoalsListScreenState extends State<GoalsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoalsProvider>().load();
    });
  }

  Future<void> _showCreateGoalSheet() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String priority = 'medium';
    DateTime startDate = DateTime.now();
    DateTime? targetDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('New Goal', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: AppConstants.priorities
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => setModalState(() => priority = v ?? 'medium'),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Create Goal',
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) return;
                      final goal = Goal(
                        id: 0,
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        startDate:
                            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
                        targetDate: targetDate != null
                            ? '${targetDate!.year}-${targetDate!.month.toString().padLeft(2, '0')}-${targetDate!.day.toString().padLeft(2, '0')}'
                            : null,
                        priority: priority,
                      );
                      await context.read<GoalsProvider>().createGoal(goal);
                      if (mounted) Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GoalsProvider>();

    Widget body;
    if (provider.isLoading && provider.goals.isEmpty) {
      body = const LoadingIndicator();
    } else if (provider.errorMessage != null && provider.goals.isEmpty) {
      body = ErrorView(
        message: provider.errorMessage!,
        onRetry: () => context.read<GoalsProvider>().load(),
      );
    } else if (provider.goals.isEmpty) {
      body = const EmptyState(
        icon: Icons.flag_outlined,
        title: 'No goals yet',
        message: 'Set a goal to start tracking your progress.',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () => context.read<GoalsProvider>().load(),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: provider.goals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final goal = provider.goals[index];
            return Card(
              child: ListTile(
                title: Text(goal.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: goal.progress / 100),
                    const SizedBox(height: 4),
                    Text('${goal.progress}% complete'),
                  ],
                ),
                trailing: PriorityChip(priority: goal.priority),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => GoalDetailScreen(goalId: goal.id)),
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGoalSheet,
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }
}
