import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SystemSettingsProvider with ChangeNotifier {
  String _companyName = 'نظام حجز الفنادق';
  String? _logoPath;
  String _currencySymbol = '\$';
  String _email = '';
  double _taxPercentage = 0.0;
  bool _autoBackupEnabled = false;
  String? _backupDirectory;

  String get companyName => _companyName;
  String? get logoPath => _logoPath;
  String get currencySymbol => _currencySymbol;
  String get email => _email;
  double get taxPercentage => _taxPercentage;
  bool get autoBackupEnabled => _autoBackupEnabled;
  String? get backupDirectory => _backupDirectory;

  SystemSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _companyName = prefs.getString('company_name') ?? 'نظام حجز الفنادق';
    _logoPath = prefs.getString('logo_path');
    _currencySymbol = prefs.getString('currency_symbol') ?? '\$';
    _email = prefs.getString('company_email') ?? '';
    _taxPercentage = prefs.getDouble('tax_percentage') ?? 0.0;
    _autoBackupEnabled = prefs.getBool('auto_backup_enabled') ?? false;
    _backupDirectory = prefs.getString('backup_directory');
    notifyListeners();
  }

  Future<void> updateSettings({
    required String name,
    String? logo,
    String? currency,
    String? email,
    double? taxPercentage,
    bool? autoBackup,
    String? backupDir,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _companyName = name;
    if (logo != null) _logoPath = logo;
    if (currency != null) _currencySymbol = currency;
    if (email != null) _email = email;
    if (taxPercentage != null) _taxPercentage = taxPercentage;
    if (autoBackup != null) _autoBackupEnabled = autoBackup;
    if (backupDir != null) _backupDirectory = backupDir;

    await prefs.setString('company_name', name);
    if (logo != null) {
      await prefs.setString('logo_path', logo);
    }
    if (currency != null) {
      await prefs.setString('currency_symbol', currency);
    }
    if (email != null) {
      await prefs.setString('company_email', email);
    }
    if (taxPercentage != null) {
      await prefs.setDouble('tax_percentage', taxPercentage);
    }
    if (autoBackup != null) {
      await prefs.setBool('auto_backup_enabled', autoBackup);
    }
    if (backupDir != null) {
      await prefs.setString('backup_directory', backupDir);
    }
    notifyListeners();
  }
}
