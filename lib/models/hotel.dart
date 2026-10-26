import 'room_type.dart';

class Hotel {
  final String id;
  final String name;
  final String location; // City/Country
  final int starRating;
  final List<RoomType> availableRooms;
  final String? imagePath;
  final int totalCapacity; // إجمالي الغرف المتاحة
  final int currentBookings; // عدد الغرف المشغولة حالياً

  Hotel({
    required this.id,
    required this.name,
    required this.location,
    required this.starRating,
    required this.availableRooms,
    this.imagePath,
    this.totalCapacity = 0,
    this.currentBookings = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'starRating': starRating,
      'availableRooms': availableRooms.map((x) => x.toMap()).toList(),
      'imagePath': imagePath,
      'totalCapacity': totalCapacity,
      'currentBookings': currentBookings,
    };
  }

  factory Hotel.fromMap(Map<String, dynamic> map) {
    return Hotel(
      id: map['id'],
      name: map['name'],
      location: map['location'],
      starRating: map['starRating'] as int,
      availableRooms: List<RoomType>.from(
        map['availableRooms']?.map((x) => RoomType.fromMap(x)) ?? [],
      ),
      imagePath: map['imagePath'],
      totalCapacity: map['totalCapacity'] ?? 0,
      currentBookings: map['currentBookings'] ?? 0,
    );
  }

  Hotel copyWith({
    String? id,
    String? name,
    String? location,
    int? starRating,
    List<RoomType>? availableRooms,
    String? imagePath,
    int? totalCapacity,
    int? currentBookings,
  }) {
    return Hotel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      starRating: starRating ?? this.starRating,
      availableRooms: availableRooms ?? this.availableRooms,
      imagePath: imagePath ?? this.imagePath,
      totalCapacity: totalCapacity ?? this.totalCapacity,
      currentBookings: currentBookings ?? this.currentBookings,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Hotel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
