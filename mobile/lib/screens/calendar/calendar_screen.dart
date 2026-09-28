import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../providers/calendar_provider.dart';
import '../../widgets/empty_state.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalendarProvider>().loadMonth(
            year: _focusedDay.year,
            month: _focusedDay.month,
          );
    });
  }

  IconData _iconFor(String kind) {
    switch (kind) {
      case 'entry':
        return Icons.book_outlined;
      case 'task':
        return Icons.check_circle_outline;
      case 'goal':
        return Icons.flag_outlined;
      case 'reminder':
        return Icons.alarm;
      case 'event':
      default:
        return Icons.event_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final dayItems =
        _selectedDay != null ? provider.itemsForDay(_selectedDay!) : <Map<String, dynamic>>[];

    return Scaffold(
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2015, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              context
                  .read<CalendarProvider>()
                  .loadMonth(year: focusedDay.year, month: focusedDay.month);
            },
            eventLoader: (day) => provider.itemsForDay(day),
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(shape: BoxShape.circle),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: dayItems.isEmpty
                ? const EmptyState(
                    icon: Icons.event_available_outlined,
                    title: 'Nothing on this day',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: dayItems.length,
                    itemBuilder: (context, index) {
                      final item = dayItems[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(_iconFor(item['kind'] as String)),
                          title: Text(item['title']?.toString() ?? 'Untitled'),
                          subtitle: Text((item['kind'] as String).toUpperCase()),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
