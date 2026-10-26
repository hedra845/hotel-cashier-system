import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/hotel.dart';
import '../models/booking.dart';
import '../models/room_type.dart';
import '../models/extra_service.dart';
import '../models/user.dart';
import '../models/activity_log.dart';
import '../models/vault_transaction.dart';
import '../models/notification_model.dart';
import '../models/message_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'hotel_cashier.db');
    return await openDatabase(
      path,
      version: 12, // الترقية لإضافة سعة الفندق (totalCapacity, currentBookings)
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE hotels (
        id TEXT PRIMARY KEY,
        name TEXT,
        location TEXT,
        starRating INTEGER,
        availableRooms TEXT,
        imagePath TEXT,
        totalCapacity INTEGER DEFAULT 0,
        currentBookings INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE bookings (
        id TEXT PRIMARY KEY,
        customerName TEXT,
        customerPhone TEXT,
        customerEmail TEXT,
        hotelData TEXT,
        roomTypeData TEXT,
        numberOfNights INTEGER,
        checkInDate TEXT,
        checkOutDate TEXT,
        extraServices TEXT,
        numberOfPeople INTEGER,
        advancePayment REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT,
        email TEXT,
        password TEXT,
        role TEXT,
        imagePath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE vault_transactions (
        id TEXT PRIMARY KEY,
        title TEXT,
        amount REAL,
        date TEXT,
        type TEXT,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE extra_services (
        id TEXT PRIMARY KEY,
        name TEXT,
        price REAL,
        type TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE activity_logs (
        id TEXT PRIMARY KEY,
        action TEXT,
        details TEXT,
        timestamp TEXT,
        userId TEXT,
        userName TEXT,
        category TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        title TEXT,
        message TEXT,
        timestamp TEXT,
        isRead INTEGER,
        type INTEGER,
        relatedId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        sender TEXT,
        subject TEXT,
        body TEXT,
        timestamp TEXT,
        isRead INTEGER,
        senderEmail TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          name TEXT,
          email TEXT,
          role TEXT,
          imagePath TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          name TEXT,
          email TEXT,
          role TEXT,
          imagePath TEXT
        )
      ''');
    }
    if (oldVersion < 4) {
      // إضافة عمود كلمة المرور إذا لم يكن موجوداً
      try {
        await db.execute(
          'ALTER TABLE users ADD COLUMN password TEXT DEFAULT "123456"',
        );
      } catch (e) {
        debugPrint('Column password might already exist: $e');
      }
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS vault_transactions (
          id TEXT PRIMARY KEY,
          title TEXT,
          amount REAL,
          date TEXT,
          type TEXT,
          description TEXT
        )
      ''');
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS extra_services (
          id TEXT PRIMARY KEY,
          name TEXT,
          price REAL,
          type TEXT
        )
      ''');

      // إضافة خدمات افتراضية
      await db.insert('extra_services', {
        'id': 'transfer',
        'name': 'انتقال (Transfer)',
        'price': 50.0,
        'type': 'transfer',
      });
      await db.insert('extra_services', {
        'id': 'sea_trip',
        'name': 'رحلة بحرية',
        'price': 100.0,
        'type': 'other',
      });
      await db.insert('extra_services', {
        'id': 'extra_meal',
        'name': 'وجبة إضافية',
        'price': 30.0,
        'type': 'meal',
      });
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS activity_logs (
          id TEXT PRIMARY KEY,
          action TEXT,
          details TEXT,
          timestamp TEXT,
          userId TEXT,
          userName TEXT,
          category TEXT
        )
      ''');

      // إضافة الأعمدة المفقودة لجدول الحجوزات
      try {
        await db.execute('ALTER TABLE bookings ADD COLUMN customerPhone TEXT');
        await db.execute('ALTER TABLE bookings ADD COLUMN customerEmail TEXT');
        await db.execute(
          'ALTER TABLE bookings ADD COLUMN advancePayment REAL DEFAULT 0.0',
        );
      } catch (e) {
        debugPrint('Columns might already exist: $e');
      }
    }
    if (oldVersion < 9) {
      // التأكد من وجود كافة أعمدة الحجوزات في حالة الترقية
      try {
        await db.execute('ALTER TABLE bookings ADD COLUMN customerPhone TEXT');
      } catch (e) {}
      try {
        await db.execute('ALTER TABLE bookings ADD COLUMN customerEmail TEXT');
      } catch (e) {}
      try {
        await db.execute('ALTER TABLE bookings ADD COLUMN hotelData TEXT');
      } catch (e) {}
      try {
        await db.execute('ALTER TABLE bookings ADD COLUMN roomTypeData TEXT');
      } catch (e) {}
      try {
        await db.execute(
          'ALTER TABLE bookings ADD COLUMN advancePayment REAL DEFAULT 0.0',
        );
      } catch (e) {}
    }

    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id TEXT PRIMARY KEY,
          title TEXT,
          message TEXT,
          timestamp TEXT,
          isRead INTEGER,
          type INTEGER,
          relatedId TEXT
        )
      ''');
    }

    if (oldVersion < 11) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS messages (
          id TEXT PRIMARY KEY,
          sender TEXT,
          subject TEXT,
          body TEXT,
          timestamp TEXT,
          isRead INTEGER,
          senderEmail TEXT
        )
      ''');
    }

    if (oldVersion < 12) {
      try {
        await db.execute(
          'ALTER TABLE hotels ADD COLUMN totalCapacity INTEGER DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE hotels ADD COLUMN currentBookings INTEGER DEFAULT 0',
        );
      } catch (e) {
        debugPrint('Columns for hotel capacity might already exist: $e');
      }
    }
  }

  // عمليات الخدمات الإضافية
  Future<int> insertExtraService(ExtraService service) async {
    Database db = await database;
    return await db.insert(
      'extra_services',
      service.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExtraService>> getExtraServices() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('extra_services');
    return List.generate(maps.length, (i) {
      return ExtraService.fromMap(maps[i]);
    });
  }

  Future<int> updateExtraService(ExtraService service) async {
    Database db = await database;
    return await db.update(
      'extra_services',
      service.toMap(),
      where: 'id = ?',
      whereArgs: [service.id],
    );
  }

  Future<int> deleteExtraService(String id) async {
    Database db = await database;
    return await db.delete('extra_services', where: 'id = ?', whereArgs: [id]);
  }

  // عمليات الخزنة
  Future<int> insertTransaction(VaultTransaction transaction) async {
    Database db = await database;
    return await db.insert(
      'vault_transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<VaultTransaction>> getTransactions() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'vault_transactions',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return VaultTransaction.fromMap(maps[i]);
    });
  }

  // عمليات المستخدمين
  Future<int> insertUser(AppUser user) async {
    Database db = await database;
    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AppUser?> getUser() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('users', limit: 1);
    if (maps.isNotEmpty) {
      return AppUser.fromMap(maps.first);
    }
    return null;
  }

  Future<List<AppUser>> getAllUsers() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) {
      return AppUser.fromMap(maps[i]);
    });
  }

  Future<int> deleteUser(String id) async {
    Database db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearUsers() async {
    Database db = await database;
    await db.delete('users');
  }

  // عمليات الفنادق
  Future<int> insertHotel(Hotel hotel) async {
    Database db = await database;
    Map<String, dynamic> row = hotel.toMap();
    // تحويل قائمة الغرف إلى JSON لحفظها في TEXT
    row['availableRooms'] = json.encode(row['availableRooms']);
    return await db.insert(
      'hotels',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Hotel>> getHotels() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('hotels');
    return List.generate(maps.length, (i) {
      Map<String, dynamic> map = Map<String, dynamic>.from(maps[i]);
      if (map['availableRooms'] != null) {
        map['availableRooms'] = json.decode(map['availableRooms'] as String);
      }
      return Hotel.fromMap(map);
    });
  }

  Future<int> deleteHotel(String id) async {
    Database db = await database;
    return await db.delete('hotels', where: 'id = ?', whereArgs: [id]);
  }

  // عمليات الحجوزات
  Future<int> insertBooking(Booking booking) async {
    Database db = await database;
    Map<String, dynamic> row = {
      'id': booking.id,
      'customerName': booking.customerName,
      'customerPhone': booking.customerPhone,
      'customerEmail': booking.customerEmail,
      'hotelData': json.encode(booking.hotel.toMap()),
      'roomTypeData': json.encode(booking.roomType.toMap()),
      'numberOfNights': booking.numberOfNights,
      'checkInDate': booking.checkInDate.toIso8601String(),
      'checkOutDate': booking.checkOutDate.toIso8601String(),
      'extraServices': json.encode(
        booking.extraServices.map((x) => x.toMap()).toList(),
      ),
      'numberOfPeople': booking.numberOfPeople,
      'advancePayment': booking.advancePayment,
    };
    return await db.insert(
      'bookings',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Booking>> getBookings() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('bookings');
    return List.generate(maps.length, (i) {
      Map<String, dynamic> map = maps[i];

      final hotelData =
          json.decode(map['hotelData'] as String) as Map<String, dynamic>;
      final roomTypeData =
          json.decode(map['roomTypeData'] as String) as Map<String, dynamic>;
      final extraServicesData =
          json.decode(map['extraServices'] as String) as List<dynamic>;

      return Booking(
        id: map['id'] as String,
        customerName: map['customerName'] as String,
        customerPhone: map['customerPhone'] as String?,
        customerEmail: map['customerEmail'] as String?,
        hotel: Hotel.fromMap(hotelData),
        roomType: RoomType.fromMap(roomTypeData),
        numberOfNights: map['numberOfNights'] as int,
        checkInDate: DateTime.parse(map['checkInDate'] as String),
        checkOutDate: DateTime.parse(map['checkOutDate'] as String),
        extraServices:
            extraServicesData
                .map<ExtraService>(
                  (x) => ExtraService.fromMap(x as Map<String, dynamic>),
                )
                .toList(),
        numberOfPeople: map['numberOfPeople'] as int,
        advancePayment: (map['advancePayment'] ?? 0.0).toDouble(),
      );
    });
  }

  Future<int> deleteBooking(String id) async {
    Database db = await database;
    return await db.delete('bookings', where: 'id = ?', whereArgs: [id]);
  }

  // عمليات سجل النشاط
  Future<int> insertActivityLog(ActivityLog log) async {
    Database db = await database;
    return await db.insert(
      'activity_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ActivityLog>> getActivityLogs() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'activity_logs',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) {
      return ActivityLog.fromMap(maps[i]);
    });
  }

  Future<void> clearActivityLogs() async {
    Database db = await database;
    await db.delete('activity_logs');
  }

  // عمليات الإشعارات
  Future<int> insertNotification(NotificationModel notification) async {
    Database db = await database;
    return await db.insert(
      'notifications',
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NotificationModel>> getNotifications() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) {
      return NotificationModel.fromMap(maps[i]);
    });
  }

  Future<int> updateNotification(NotificationModel notification) async {
    Database db = await database;
    return await db.update(
      'notifications',
      notification.toMap(),
      where: 'id = ?',
      whereArgs: [notification.id],
    );
  }

  Future<int> deleteNotification(String id) async {
    Database db = await database;
    return await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearNotifications() async {
    Database db = await database;
    await db.delete('notifications');
  }

  // عمليات الرسائل (صندوق الوارد)
  Future<int> insertMessage(MessageModel message) async {
    Database db = await database;
    return await db.insert(
      'messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MessageModel>> getMessages() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'messages',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) {
      return MessageModel.fromMap(maps[i]);
    });
  }

  Future<int> updateMessage(MessageModel message) async {
    Database db = await database;
    return await db.update(
      'messages',
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  Future<int> deleteMessage(String id) async {
    Database db = await database;
    return await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearMessages() async {
    Database db = await database;
    await db.delete('messages');
  }

  // عمليات النسخ الاحتياطي
  Future<Map<String, dynamic>> exportDatabase() async {
    final hotels = await getHotels();
    final bookings = await getBookings();

    // ملاحظة: الحجوزات تحتاج لتحويل خاص لأنها تحتوي على كائنات
    final bookingsJson =
        bookings
            .map(
              (b) => {
                'id': b.id,
                'customerName': b.customerName,
                'customerPhone': b.customerPhone,
                'customerEmail': b.customerEmail,
                'hotel': b.hotel.toMap(),
                'roomType': b.roomType.toMap(),
                'numberOfNights': b.numberOfNights,
                'checkInDate': b.checkInDate.toIso8601String(),
                'checkOutDate': b.checkOutDate.toIso8601String(),
                'extraServices': b.extraServices.map((s) => s.toMap()).toList(),
                'numberOfPeople': b.numberOfPeople,
                'advancePayment': b.advancePayment,
              },
            )
            .toList();

    return {
      'hotels': hotels.map((h) => h.toMap()).toList(),
      'bookings': bookingsJson,
      'exportDate': DateTime.now().toIso8601String(),
      'version': 1,
    };
  }

  Future<void> importDatabase(Map<String, dynamic> data) async {
    Database db = await database;
    await db.transaction((txn) async {
      // مسح البيانات الحالية
      await txn.delete('hotels');
      await txn.delete('bookings');

      // استيراد الفنادق
      if (data['hotels'] != null) {
        for (var hotelMap in data['hotels']) {
          Map<String, dynamic> row = Map<String, dynamic>.from(hotelMap);
          row['availableRooms'] = json.encode(row['availableRooms']);
          await txn.insert('hotels', row);
        }
      }

      // استيراد الحجوزات
      if (data['bookings'] != null) {
        for (var bookingMap in data['bookings']) {
          Map<String, dynamic> row = {
            'id': bookingMap['id'],
            'customerName': bookingMap['customerName'],
            'customerPhone': bookingMap['customerPhone'],
            'customerEmail': bookingMap['customerEmail'],
            'hotelData': json.encode(bookingMap['hotel']),
            'roomTypeData': json.encode(bookingMap['roomType']),
            'numberOfNights': bookingMap['numberOfNights'],
            'checkInDate': bookingMap['checkInDate'],
            'checkOutDate': bookingMap['checkOutDate'],
            'extraServices': json.encode(bookingMap['extraServices']),
            'numberOfPeople': bookingMap['numberOfPeople'],
            'advancePayment': bookingMap['advancePayment'] ?? 0.0,
          };
          await txn.insert('bookings', row);
        }
      }
    });
  }
}
