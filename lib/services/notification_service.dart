import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationType { borrow, returnReminder, returnSuccess, general }

class Notification {
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;

  Notification({
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  IconData get icon {
    switch (type) {
      case NotificationType.borrow:
        return Icons.book;
      case NotificationType.returnReminder:
        return Icons.notification_important;
      case NotificationType.returnSuccess:
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.index,
      'isRead': isRead,
    };
  }

  factory Notification.fromJson(Map<String, dynamic> json) {
    // Handle old format notifications that don't have type
    NotificationType notificationType;
    if (json['type'] != null) {
      notificationType = NotificationType.values[json['type'] as int];
    } else {
      // Try to infer type from the title or use general as fallback
      final title = json['title'].toString().toLowerCase();
      if (title.contains('pinjam')) {
        notificationType = NotificationType.borrow;
      } else if (title.contains('kembali')) {
        notificationType = NotificationType.returnSuccess;
      } else if (title.contains('pengingat')) {
        notificationType = NotificationType.returnReminder;
      } else {
        notificationType = NotificationType.general;
      }
    }

    return Notification(
      title: json['title'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      type: notificationType,
      isRead: json['isRead'] ?? false,
    );
  }
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal() {
    _loadNotifications();
  }

  final List<Notification> _notifications = [];
  int _unreadCount = 0;
  static const String _storageKey = 'notifications';

  List<Notification> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? notificationsJson = prefs.getString(_storageKey);

      if (notificationsJson != null) {
        final List<dynamic> decoded = jsonDecode(notificationsJson);
        _notifications.clear();
        _unreadCount = 0;

        for (var item in decoded) {
          try {
            final notification = Notification.fromJson(item);
            _notifications.add(notification);
            if (!notification.isRead) {
              _unreadCount++;
            }
          } catch (e) {
            print('Error parsing notification: $e');
            // Skip invalid notifications
            continue;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading notifications: $e');
      // If there's an error loading notifications, start fresh
      _notifications.clear();
      _unreadCount = 0;
    }
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _notifications.map((n) => n.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }

  void _showInAppNotification(BuildContext context, String title, String message) {
    final snackBar = SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(message),
        ],
      ),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> addNotification({
    required BuildContext context,
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    _notifications.insert(
      0,
      Notification(
        title: title,
        message: message,
        timestamp: DateTime.now(),
        type: type,
      ),
    );
    _unreadCount++;
    notifyListeners();
    await _saveNotifications();
    _showInAppNotification(context, title, message);
  }

  Future<void> markAsRead(int index) async {
    if (!_notifications[index].isRead) {
      _notifications[index].isRead = true;
      _unreadCount--;
      notifyListeners();
      await _saveNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    bool hasUnread = false;
    for (var notification in _notifications) {
      if (!notification.isRead) {
        notification.isRead = true;
        hasUnread = true;
      }
    }
    if (hasUnread) {
      _unreadCount = 0;
      notifyListeners();
      await _saveNotifications();
    }
  }

  Future<void> addBorrowNotification(
      BuildContext context, String bookTitle) async {
    await addNotification(
      context: context,
      title: 'Peminjaman Berhasil',
      message: 'Anda telah berhasil meminjam buku "$bookTitle".',
      type: NotificationType.borrow,
    );
  }

  Future<void> addReturnReminderNotification(
      BuildContext context, String bookTitle, DateTime dueDate) async {
    await addNotification(
      context: context,
      title: 'Pengingat Pengembalian',
      message:
          'Harap segera kembalikan buku "$bookTitle" sebelum ${_formatDate(dueDate)}.',
      type: NotificationType.returnReminder,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
