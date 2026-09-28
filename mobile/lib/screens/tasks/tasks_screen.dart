import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/task.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/priority_chip.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksProvider>().load();
    });
  }

  Future<void> _showCreateTaskSheet() async {
    final titleController = TextEditingController();
    String priority = 'medium';
    DateTime? dueDate;

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
                  Text('New Task', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
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
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(dueDate == null
                        ? 'Set due date'
                        : DateFormat('MMM d, yyyy').format(dueDate!)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setModalState(() => dueDate = picked);
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) return;
                      final task = DiaryTask(
                        id: 0,
                        title: titleController.text.trim(),
                        priority: priority,
                        dueDate: dueDate != null
                            ? DateFormat('yyyy-MM-dd').format(dueDate!)
                            : null,
                      );
                      await context.read<TasksProvider>().createTask(task);
                      if (mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Create Task'),
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
    final provider = context.watch<TasksProvider>();

    Widget body;
    if (provider.isLoading && provider.tasks.isEmpty) {
      body = const LoadingIndicator();
    } else if (provider.errorMessage != null && provider.tasks.isEmpty) {
      body = ErrorView(
        message: provider.errorMessage!,
        onRetry: () => context.read<TasksProvider>().load(),
      );
    } else if (provider.tasks.isEmpty) {
      body = const EmptyState(icon: Icons.check_circle_outline, title: 'No tasks yet');
    } else {
      body = RefreshIndicator(
        onRefresh: () => context.read<TasksProvider>().load(),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: provider.tasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final task = provider.tasks[index];
            return Card(
              child: CheckboxListTile(
                value: task.isDone,
                onChanged: (_) => context.read<TasksProvider>().toggleComplete(task.id),
                title: Text(
                  task.title,
                  style: TextStyle(
                      decoration: task.isDone ? TextDecoration.lineThrough : null),
                ),
                subtitle: task.dueDate != null ? Text('Due ${task.dueDate}') : null,
                secondary: PriorityChip(priority: task.priority),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTaskSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}
