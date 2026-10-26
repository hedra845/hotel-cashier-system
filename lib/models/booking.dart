import 'hotel.dart';
import 'room_type.dart';
import 'extra_service.dart';

class Booking {
  final String id;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final Hotel hotel;
  final RoomType roomType;
  final int numberOfNights;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final List<ExtraService> extraServices;
  final int numberOfPeople;
  final double advancePayment;

  Booking({
    required this.id,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    required this.hotel,
    required this.roomType,
    required this.numberOfNights,
    required this.checkInDate,
    required this.checkOutDate,
    this.extraServices = const [],
    required this.numberOfPeople,
    this.advancePayment = 0.0,
  });

  double get roomTotal =>
      roomType.pricePerNight * numberOfNights * numberOfPeople;

  double get servicesTotal =>
      extraServices.fold(0, (sum, service) => sum + service.price);

  double get totalAmount => roomTotal + servicesTotal;

  double get remainingAmount => totalAmount - advancePayment;

  double get pricePerPerson => totalAmount / numberOfPeople;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'hotel': hotel.toMap(),
      'roomType': roomType.toMap(),
      'numberOfNights': numberOfNights,
      'checkInDate': checkInDate.toIso8601String(),
      'checkOutDate': checkOutDate.toIso8601String(),
      'extraServices': extraServices.map((x) => x.toMap()).toList(),
      'numberOfPeople': numberOfPeople,
      'advancePayment': advancePayment,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'],
      customerName: map['customerName'],
      customerPhone: map['customerPhone'],
      customerEmail: map['customerEmail'],
      hotel: Hotel.fromMap(map['hotel']),
      roomType: RoomType.fromMap(map['roomType']),
      numberOfNights: map['numberOfNights'],
      checkInDate: DateTime.parse(map['checkInDate']),
      checkOutDate: DateTime.parse(map['checkOutDate']),
      extraServices: List<ExtraService>.from(
        map['extraServices']?.map((x) => ExtraService.fromMap(x)) ?? [],
      ),
      numberOfPeople: map['numberOfPeople'],
      advancePayment: (map['advancePayment'] ?? 0.0).toDouble(),
    );
  }

  Booking copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    Hotel? hotel,
    RoomType? roomType,
    int? numberOfNights,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    List<ExtraService>? extraServices,
    int? numberOfPeople,
    double? advancePayment,
  }) {
    return Booking(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      hotel: hotel ?? this.hotel,
      roomType: roomType ?? this.roomType,
      numberOfNights: numberOfNights ?? this.numberOfNights,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      extraServices: extraServices ?? this.extraServices,
      numberOfPeople: numberOfPeople ?? this.numberOfPeople,
      advancePayment: advancePayment ?? this.advancePayment,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Booking && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
