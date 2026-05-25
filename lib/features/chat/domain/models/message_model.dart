class MessageModel {
  final String id;
  final String message;
  final String senderId;
  final String senderName;
  final bool isSystem;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.message,
    required this.senderId,
    required this.senderName,
    required this.isSystem,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'].toString(),
        message:
            (json['message'] ?? json['body'] ?? json['text'] ?? '').toString(),
        senderId: (json['sender_id'] ?? json['author_id'] ?? '').toString(),
        senderName:
            (json['sender_name'] ?? json['author_name'] ?? '').toString(),
        isSystem: json['is_system'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
