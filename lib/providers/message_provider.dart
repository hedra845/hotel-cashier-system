import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../utils/database_helper.dart';
import 'settings_provider.dart';

class MessageProvider with ChangeNotifier {
  List<MessageModel> _messages = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SystemSettingsProvider? settingsProvider;

  List<MessageModel> get messages => [..._messages];
  int get unreadCount => _messages.where((m) => !m.isRead).length;

  MessageProvider({this.settingsProvider}) {
    loadMessages();
    if (settingsProvider != null) {
      _checkAndAddMockMessages();
    }
  }

  Future<void> loadMessages() async {
    _messages = await _dbHelper.getMessages();
    notifyListeners();
  }

  Future<void> addMessage(MessageModel message) async {
    await _dbHelper.insertMessage(message);
    _messages.insert(0, message);
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _messages.indexWhere((m) => m.id == id);
    if (index != -1 && !_messages[index].isRead) {
      final updated = _messages[index].copyWith(isRead: true);
      await _dbHelper.updateMessage(updated);
      _messages[index] = updated;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < _messages.length; i++) {
      if (!_messages[i].isRead) {
        _messages[i] = _messages[i].copyWith(isRead: true);
        await _dbHelper.updateMessage(_messages[i]);
      }
    }
    notifyListeners();
  }

  Future<void> deleteMessage(String id) async {
    await _dbHelper.deleteMessage(id);
    _messages.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  void _checkAndAddMockMessages() {
    if (settingsProvider == null || settingsProvider!.email.isEmpty) return;

    // إضافة رسائل تجريبية توضح كيف ستظهر الإيميلات
    final mockMessages = [
      MessageModel(
        id: 'mock_1',
        sender: 'Google Cloud',
        senderEmail: 'noreply@google.com',
        subject: 'تنبيه أمان لنظام الفنادق',
        body: 'تم تسجيل دخول جديد لنظامك من جهاز غير معروف. يرجى التأكد من هويتك.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      MessageModel(
        id: 'mock_2',
        sender: 'شركة الفنادق العالمية',
        senderEmail: 'info@hotel-corp.com',
        subject: 'تحديث أسعار الغرف السنوي',
        body: 'نحيطكم علماً بأنه سيتم تحديث قائمة الأسعار اعتباراً من الشهر القادم.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    for (var msg in mockMessages) {
      final exists = _messages.any((m) => m.id == msg.id);
      if (!exists) {
        addMessage(msg);
      }
    }
  }
}
