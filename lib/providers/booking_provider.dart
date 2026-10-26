import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../models/hotel.dart';
import '../utils/database_helper.dart';
import 'activity_log_provider.dart';
import 'hotel_provider.dart';

class BookingProvider with ChangeNotifier {
  List<Booking> _bookings = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ActivityLogProvider? logProvider;
  final HotelProvider? hotelProvider;

  List<Booking> get bookings => [..._bookings];

  BookingProvider({this.logProvider, this.hotelProvider}) {
    loadBookings();
  }

  Future<void> loadBookings() async {
    final list = await _dbHelper.getBookings();
    // إزالة أي تكرار محتمل بناءً على المعرف (ID)
    final Map<String, Booking> uniqueMap = {};
    for (var b in list) {
      uniqueMap[b.id] = b;
    }
    _bookings = uniqueMap.values.toList();
    notifyListeners();
  }

  Future<void> addBooking(Booking booking) async {
    await _dbHelper.insertBooking(booking);
    // التأكد من عدم إضافة الحجز مرتين إذا كان موجوداً بالفعل
    _bookings.removeWhere((b) => b.id == booking.id);
    _bookings.add(booking);

    // تحديث عدد الحجوزات الحالية للفندق
    final hotel = hotelProvider?.getHotelById(booking.hotel.id);
    if (hotel != null) {
      final updatedHotel = hotel.copyWith(
        currentBookings: hotel.currentBookings + 1,
      );
      await hotelProvider?.updateHotel(updatedHotel);
    }

    // سجل النشاط
    logProvider?.logAction(
      action: 'حجز جديد',
      details:
          'تم إنشاء حجز للعميل ${booking.customerName} في فندق ${booking.hotel.name} بقيمة ${booking.totalAmount}',
      category: 'booking',
    );

    notifyListeners();
  }

  Future<void> removeBooking(String id) async {
    final booking = _bookings.firstWhere((b) => b.id == id);
    await _dbHelper.deleteBooking(id);
    _bookings.removeWhere((booking) => booking.id == id);

    // تحديث عدد الحجوزات الحالية للفندق
    final hotel = hotelProvider?.getHotelById(booking.hotel.id);
    if (hotel != null) {
      final updatedHotel = hotel.copyWith(
        currentBookings: (hotel.currentBookings - 1).clamp(0, 99999),
      );
      await hotelProvider?.updateHotel(updatedHotel);
    }

    // سجل النشاط
    logProvider?.logAction(
      action: 'حذف حجز',
      details:
          'تم حذف حجز العميل ${booking.customerName} من فندق ${booking.hotel.name}',
      category: 'booking',
    );

    notifyListeners();
  }

  Future<void> updateBooking(Booking booking) async {
    await _dbHelper.insertBooking(booking); // DatabaseHelper uses replace
    final index = _bookings.indexWhere((b) => b.id == booking.id);
    if (index != -1) {
      _bookings[index] = booking;
    } else {
      _bookings.add(booking);
    }

    // سجل النشاط
    logProvider?.logAction(
      action: 'تحديث حجز',
      details: 'تم تحديث بيانات حجز العميل ${booking.customerName}',
      category: 'booking',
    );

    notifyListeners();
  }

  Future<void> updateCustomerData({
    required String oldName,
    required String newName,
    String? newPhone,
    String? newEmail,
  }) async {
    final key = oldName.trim().toLowerCase();
    final bookingsToUpdate =
        _bookings
            .where((b) => b.customerName.trim().toLowerCase() == key)
            .toList();

    for (var booking in bookingsToUpdate) {
      final updatedBooking = booking.copyWith(
        customerName: newName,
        customerPhone: newPhone,
        customerEmail: newEmail,
      );
      await _dbHelper.insertBooking(updatedBooking);
      final index = _bookings.indexWhere((b) => b.id == booking.id);
      if (index != -1) {
        _bookings[index] = updatedBooking;
      }
    }

    if (bookingsToUpdate.isNotEmpty) {
      logProvider?.logAction(
        action: 'تحديث بيانات عميل',
        details: 'تم تحديث بيانات العميل: $oldName إلى $newName',
        category: 'customer',
      );
      notifyListeners();
    }
  }

  double get totalRevenue => _bookings.fold(0, (sum, b) => sum + b.totalAmount);

  Map<String, int> get topHotels {
    final Map<String, int> stats = {};
    for (var booking in _bookings) {
      stats[booking.hotel.name] = (stats[booking.hotel.name] ?? 0) + 1;
    }
    return stats;
  }

  List<Booking> getBookingsByHotel(String hotelId) {
    return _bookings.where((b) => b.hotel.id == hotelId).toList();
  }

  List<Map<String, dynamic>> comparePrices(
    List<Hotel> hotels,
    String roomName,
    int nights,
  ) {
    final List<Map<String, dynamic>> comparisons = [];
    for (var hotel in hotels) {
      final room = hotel.availableRooms.firstWhere(
        (r) => r.name.toLowerCase() == roomName.toLowerCase(),
        orElse:
            () =>
                hotel.availableRooms.isNotEmpty
                    ? hotel.availableRooms.first
                    : throw Exception("No rooms"),
      );
      comparisons.add({
        'hotel': hotel.name,
        'room': room.name,
        'total': room.pricePerNight * nights,
        'perNight': room.pricePerNight,
      });
    }
    comparisons.sort(
      (a, b) => (a['total'] as double).compareTo(b['total'] as double),
    );
    return comparisons;
  }
}
