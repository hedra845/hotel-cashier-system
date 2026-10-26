class MessageModel {
  final String id;
  final String sender; // e.g., 'Google', 'Hotel Company', 'Customer Support'
  final String subject;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String? senderEmail;

  MessageModel({
    required this.id,
    required this.sender,
    required this.subject,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.senderEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'subject': subject,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead ? 1 : 0,
      'senderEmail': senderEmail,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      sender: map['sender'],
      subject: map['subject'],
      body: map['body'],
      timestamp: DateTime.parse(map['timestamp']),
      isRead: map['isRead'] == 1,
      senderEmail: map['senderEmail'],
    );
  }

  MessageModel copyWith({bool? isRead}) {
    return MessageModel(
      id: id,
      sender: sender,
      subject: subject,
      body: body,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      senderEmail: senderEmail,
    );
  }
}
