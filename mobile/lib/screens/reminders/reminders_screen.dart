import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/reminder.dart';
import '../../providers/reminders_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RemindersProvider>().load();
    });
  }

  Future<void> _showCreateReminderSheet() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String repeat = 'one_time';
    DateTime remindAt = DateTime.now().add(const Duration(hours: 1));

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
                  Text('New Reminder', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageController,
                    decoration: const InputDecoration(labelText: 'Message'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.schedule),
                    label: Text(DateFormat('MMM d, yyyy h:mm a').format(remindAt)),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: remindAt,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date == null) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(remindAt),
                      );
                      if (time == null) return;
                      setModalState(() {
                        remindAt =
                            DateTime(date.year, date.month, date.day, time.hour, time.minute);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: repeat,
                    decoration: const InputDecoration(labelText: 'Repeat'),
                    items: AppConstants.repeatOptions
                        .map((r) => DropdownMenuItem(value: r, child: Text(r.replaceAll('_', ' '))))
                        .toList(),
                    onChanged: (v) => setModalState(() => repeat = v ?? 'one_time'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) return;
                      final reminder = Reminder(
                        id: 0,
                        title: titleController.text.trim(),
                        message: messageController.text.trim(),
                        remindAt: remindAt,
                        repeat: repeat,
                      );
                      await context.read<RemindersProvider>().createReminder(reminder);
                      if (mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Create Reminder'),
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
    final provider = context.watch<RemindersProvider>();

    Widget body;
    if (provider.isLoading && provider.reminders.isEmpty) {
      body = const LoadingIndicator();
    } else if (provider.errorMessage != null && provider.reminders.isEmpty) {
      body = ErrorView(
        message: provider.errorMessage!,
        onRetry: () => context.read<RemindersProvider>().load(),
      );
    } else if (provider.reminders.isEmpty) {
      body = const EmptyState(icon: Icons.alarm, title: 'No reminders set');
    } else {
      body = RefreshIndicator(
        onRefresh: () => context.read<RemindersProvider>().load(),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: provider.reminders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final reminder = provider.reminders[index];
            return Card(
              child: SwitchListTile(
                value: reminder.isActive,
                onChanged: (v) => context
                    .read<RemindersProvider>()
                    .updateReminder(reminder.id, reminder.copyWith(isActive: v)),
                title: Text(reminder.title),
                subtitle: Text(
                    '${DateFormat('MMM d, h:mm a').format(reminder.remindAt)} - ${reminder.repeat.replaceAll('_', ' ')}'),
                secondary: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      context.read<RemindersProvider>().deleteReminder(reminder.id),
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateReminderSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}
