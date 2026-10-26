import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'database_helper.dart';
import '../providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  Timer? _timer;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  void start(SystemSettingsProvider settings) {
    _timer?.cancel();
    // التحقق كل دقيقة
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndPerformBackup(settings);
    });
    debugPrint('Backup Service started');
  }

  void stop() {
    _timer?.cancel();
    debugPrint('Backup Service stopped');
  }

  Future<void> _checkAndPerformBackup(SystemSettingsProvider settings) async {
    if (!settings.autoBackupEnabled || settings.backupDirectory == null) return;

    final now = DateTime.now();
    // هل نحن في الساعة 12 صباحاً؟ (00:xx)
    if (now.hour == 0 && now.minute == 0) {
      final prefs = await SharedPreferences.getInstance();
      final lastBackupDate = prefs.getString('last_auto_backup_date') ?? '';
      final todayStr = '${now.year}-${now.month}-${now.day}';

      if (lastBackupDate != todayStr) {
        debugPrint('Starting scheduled backup at 12 AM...');
        await _performBackup(settings.backupDirectory!);
        await prefs.setString('last_auto_backup_date', todayStr);
      }
    }
  }

  Future<void> _performBackup(String directoryPath) async {
    try {
      final data = await _dbHelper.exportDatabase();
      final jsonString = jsonEncode(data);

      final now = DateTime.now();
      final fileName =
          'auto_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.json';
      
      final filePath = p.join(directoryPath, fileName);
      final file = File(filePath);
      
      // التأكد من وجود المجلد
      if (!await Directory(directoryPath).exists()) {
        await Directory(directoryPath).create(recursive: true);
      }

      await file.writeAsString(jsonString);
      debugPrint('Auto backup completed: $filePath');
    } catch (e) {
      debugPrint('Error during auto backup: $e');
    }
  }
}
