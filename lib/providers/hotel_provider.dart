import 'package:flutter/material.dart';
import '../models/hotel.dart';
import '../utils/database_helper.dart';
import 'activity_log_provider.dart';

class HotelProvider with ChangeNotifier {
  List<Hotel> _hotels = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  ActivityLogProvider? logProvider;

  List<Hotel> get hotels => [..._hotels];

  HotelProvider({this.logProvider}) {
    loadHotels();
  }

  void update(ActivityLogProvider? logs) {
    logProvider = logs;
  }

  Future<void> loadHotels() async {
    _hotels = await _dbHelper.getHotels();
    notifyListeners();
  }

  Future<void> addHotel(Hotel hotel) async {
    await _dbHelper.insertHotel(hotel);
    _hotels.add(hotel);

    // سجل النشاط
    logProvider?.logAction(
      action: 'إضافة فندق',
      details: 'تمت إضافة فندق جديد: ${hotel.name} في ${hotel.location}',
      category: 'hotel',
    );

    notifyListeners();
  }

  Future<void> updateHotel(Hotel hotel) async {
    final index = _hotels.indexWhere((h) => h.id == hotel.id);
    if (index >= 0) {
      await _dbHelper.insertHotel(hotel); // insert uses replace strategy
      _hotels[index] = hotel;

      // سجل النشاط
      logProvider?.logAction(
        action: 'تحديث فندق',
        details: 'تم تحديث بيانات فندق: ${hotel.name}',
        category: 'hotel',
      );

      notifyListeners();
    }
  }

  Future<void> removeHotel(String id) async {
    final hotel = _hotels.firstWhere((h) => h.id == id);
    await _dbHelper.deleteHotel(id);
    _hotels.removeWhere((hotel) => hotel.id == id);

    // سجل النشاط
    logProvider?.logAction(
      action: 'حذف فندق',
      details: 'تم حذف فندق: ${hotel.name}',
      category: 'hotel',
    );

    notifyListeners();
  }

  Hotel? getHotelById(String id) {
    try {
      return _hotels.firstWhere((hotel) => hotel.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Hotel> searchHotels(String query) {
    return _hotels
        .where(
          (hotel) =>
              hotel.name.toLowerCase().contains(query.toLowerCase()) ||
              hotel.location.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }
}
