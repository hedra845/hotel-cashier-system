class ActivityLog {
  final String id;
  final String action; // e.g., 'حجز جديد', 'تعديل فندق', 'إيداع في الخزنة'
  final String details; // e.g., 'تم إنشاء حجز للعميل: أحمد محمد بقيمة 500'
  final DateTime timestamp;
  final String? userId;
  final String? userName;
  final String category; // e.g., 'booking', 'vault', 'hotel', 'settings'

  ActivityLog({
    required this.id,
    required this.action,
    required this.details,
    required this.timestamp,
    this.userId,
    this.userName,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'userName': userName,
      'category': category,
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'],
      action: map['action'],
      details: map['details'],
      timestamp: DateTime.parse(map['timestamp']),
      userId: map['userId'],
      userName: map['userName'],
      category: map['category'] ?? 'other',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLog &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
