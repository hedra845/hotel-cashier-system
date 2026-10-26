enum TransactionType { deposit, withdrawal }

class VaultTransaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String? description;

  VaultTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.name,
      'description': description,
    };
  }

  factory VaultTransaction.fromMap(Map<String, dynamic> map) {
    return VaultTransaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      type: TransactionType.values.byName(map['type']),
      description: map['description'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
