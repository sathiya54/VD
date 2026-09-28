import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/notification.dart';
import '../../services/notifications_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationsService();
  List<AppNotification> _items = [];
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
    final result = await _service.list();
    result.when(
      success: (page) => setState(() => _items = page.results),
      failure: (error) => setState(() => _error = error.message),
    );
    setState(() => _isLoading = false);
  }

  Future<void> _markRead(AppNotification notification) async {
    if (notification.isRead) return;
    await _service.markRead(notification.id);
    setState(() {
      _items = _items
          .map((n) => n.id == notification.id
              ? AppNotification(
                  id: n.id,
                  type: n.type,
                  title: n.title,
                  message: n.message,
                  isRead: true,
                  createdAt: n.createdAt,
                )
              : n)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isLoading) {
      body = const LoadingIndicator();
    } else if (_error != null && _items.isEmpty) {
      body = ErrorView(message: _error!, onRetry: _load);
    } else if (_items.isEmpty) {
      body = const EmptyState(icon: Icons.notifications_none, title: 'No notifications');
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final n = _items[index];
            return ListTile(
              leading: Icon(
                n.isRead ? Icons.notifications_none : Icons.notifications,
                color: n.isRead ? null : Theme.of(context).colorScheme.primary,
              ),
              title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
              subtitle: Text(n.message),
              trailing: Text(DateFormat('MMM d').format(n.createdAt)),
              onTap: () => _markRead(n),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: body,
    );
  }
}
