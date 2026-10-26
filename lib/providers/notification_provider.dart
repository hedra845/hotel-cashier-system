import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../utils/database_helper.dart';
import 'booking_provider.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final BookingProvider? bookingProvider;

  List<NotificationModel> get notifications => [..._notifications];
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider({this.bookingProvider}) {
    loadNotifications();
    if (bookingProvider != null) {
      _generateAutomaticNotifications();
    }
  }

  Future<void> loadNotifications() async {
    _notifications = await _dbHelper.getNotifications();
    notifyListeners();
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? relatedId,
  }) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      relatedId: relatedId,
    );

    await _dbHelper.insertNotification(notification);
    _notifications.insert(0, notification);
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      final updated = _notifications[index].copyWith(isRead: true);
      await _dbHelper.updateNotification(updated);
      _notifications[index] = updated;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        await _dbHelper.updateNotification(_notifications[i]);
      }
    }
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    await _dbHelper.deleteNotification(id);
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _dbHelper.clearNotifications();
    _notifications.clear();
    notifyListeners();
  }

  void _generateAutomaticNotifications() {
    if (bookingProvider == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var booking in bookingProvider!.bookings) {
      // 1. تنبيه عن انتهاء الإقامة (اليوم أو غداً)
      final checkOut = DateTime(booking.checkOutDate.year, booking.checkOutDate.month, booking.checkOutDate.day);
      final difference = checkOut.difference(today).inDays;

      if (difference == 0) {
        _checkAndAddNotification(
          title: 'انتهاء إقامة اليوم',
          message: 'تنتهي اليوم إقامة العميل ${booking.customerName} في فندق ${booking.hotel.name}',
          type: NotificationType.checkoutSoon,
          relatedId: booking.id,
        );
      } else if (difference == 1) {
        _checkAndAddNotification(
          title: 'انتهاء إقامة غداً',
          message: 'تنتهي غداً إقامة العميل ${booking.customerName} في فندق ${booking.hotel.name}',
          type: NotificationType.checkoutSoon,
          relatedId: booking.id,
        );
      }

      // 2. تنبيه عن مبالغ متبقية
      final remaining = booking.totalAmount - booking.advancePayment;
      if (remaining > 0.01) {
        _checkAndAddNotification(
          title: 'مبلغ متبقي',
          message: 'يوجد مبلغ متبقي (\$${remaining.toStringAsFixed(2)}) على العميل ${booking.customerName}',
          type: NotificationType.remainingPayment,
          relatedId: booking.id,
        );
      }
    }
  }

  void _checkAndAddNotification({
    required String title,
    required String message,
    required NotificationType type,
    required String relatedId,
  }) {
    // التأكد من عدم تكرار نفس التنبيه لنفس الحجز في نفس اليوم
    final exists = _notifications.any((n) => 
      n.relatedId == relatedId && 
      n.type == type && 
      n.timestamp.day == DateTime.now().day &&
      n.timestamp.month == DateTime.now().month &&
      n.timestamp.year == DateTime.now().year
    );

    if (!exists) {
      addNotification(
        title: title,
        message: message,
        type: type,
        relatedId: relatedId,
      );
    }
  }
}
