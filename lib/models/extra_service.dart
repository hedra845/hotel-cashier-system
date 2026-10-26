enum ServiceType { transfer, tour, meal, other }

class ExtraService {
  final String id;
  final String name;
  final double price;
  final ServiceType type;

  ExtraService({
    required this.id,
    required this.name,
    required this.price,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'price': price, 'type': type.name};
  }

  factory ExtraService.fromMap(Map<String, dynamic> map) {
    return ExtraService(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      type: ServiceType.values.byName(map['type']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtraService &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
