import 'package:flutter/material.dart';
import '../models/activity_log.dart';
import '../utils/database_helper.dart';
import 'auth_provider.dart';

class ActivityLogProvider with ChangeNotifier {
  List<ActivityLog> _logs = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AuthProvider? authProvider;

  List<ActivityLog> get logs => [..._logs];

  ActivityLogProvider({this.authProvider}) {
    loadLogs();
  }

  Future<void> loadLogs() async {
    _logs = await _dbHelper.getActivityLogs();
    notifyListeners();
  }

  Future<void> logAction({
    required String action,
    required String details,
    required String category,
  }) async {
    final user = authProvider?.currentUser;
    
    final log = ActivityLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      action: action,
      details: details,
      timestamp: DateTime.now(),
      userId: user?.id,
      userName: user?.name,
      category: category,
    );

    await _dbHelper.insertActivityLog(log);
    _logs.insert(0, log); // إضافة في البداية لأننا نعرض الأحدث أولاً
    notifyListeners();
  }

  Future<void> clearLogs() async {
    await _dbHelper.clearActivityLogs();
    _logs.clear();
    notifyListeners();
  }

  List<ActivityLog> filterLogs({String? category, String? query}) {
    return _logs.where((log) {
      bool matchesCategory = category == null || category == 'الكل' || log.category == category;
      bool matchesQuery = query == null || 
          log.action.contains(query) || 
          log.details.contains(query) ||
          (log.userName?.contains(query) ?? false);
      return matchesCategory && matchesQuery;
    }).toList();
  }
}
