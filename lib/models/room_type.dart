class RoomType {
  final String id;
  final String name; // e.g., Single, Double, Triple
  final double pricePerNight;
  final int capacity;
  final DateTime? priceStartDate;
  final DateTime? priceEndDate;

  RoomType({
    required this.id,
    required this.name,
    required this.pricePerNight,
    required this.capacity,
    this.priceStartDate,
    this.priceEndDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pricePerNight': pricePerNight,
      'capacity': capacity,
      'priceStartDate': priceStartDate?.toIso8601String(),
      'priceEndDate': priceEndDate?.toIso8601String(),
    };
  }

  factory RoomType.fromMap(Map<String, dynamic> map) {
    return RoomType(
      id: map['id'],
      name: map['name'],
      pricePerNight: (map['pricePerNight'] as num).toDouble(),
      capacity: map['capacity'] as int,
      priceStartDate:
          map['priceStartDate'] != null
              ? DateTime.parse(map['priceStartDate'])
              : null,
      priceEndDate:
          map['priceEndDate'] != null
              ? DateTime.parse(map['priceEndDate'])
              : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomType && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
