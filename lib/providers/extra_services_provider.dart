import 'package:flutter/material.dart';
import '../models/extra_service.dart';
import '../utils/database_helper.dart';
import 'activity_log_provider.dart';

class ExtraServicesProvider with ChangeNotifier {
  List<ExtraService> _services = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ActivityLogProvider? logProvider;

  List<ExtraService> get services => [..._services];

  ExtraServicesProvider({this.logProvider}) {
    loadServices();
  }

  Future<void> loadServices() async {
    _services = await _dbHelper.getExtraServices();
    notifyListeners();
  }

  Future<void> addService(ExtraService service) async {
    await _dbHelper.insertExtraService(service);

    // سجل النشاط
    logProvider?.logAction(
      action: 'إضافة خدمة',
      details: 'تمت إضافة خدمة إضافية: ${service.name} بسعر ${service.price}',
      category: 'settings',
    );

    await loadServices();
  }

  Future<void> updateService(ExtraService service) async {
    await _dbHelper.updateExtraService(service);

    // سجل النشاط
    logProvider?.logAction(
      action: 'تحديث خدمة',
      details: 'تم تحديث خدمة إضافية: ${service.name}',
      category: 'settings',
    );

    await loadServices();
  }

  Future<void> deleteService(String id) async {
    final service = _services.firstWhere((s) => s.id == id);
    await _dbHelper.deleteExtraService(id);

    // سجل النشاط
    logProvider?.logAction(
      action: 'حذف خدمة',
      details: 'تم حذف خدمة إضافية: ${service.name}',
      category: 'settings',
    );

    await loadServices();
  }
}
