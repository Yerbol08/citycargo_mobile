class ChatModel {
  final String id;
  final String orderId;
  final int unreadCount;

  const ChatModel({
    required this.id,
    required this.orderId,
    required this.unreadCount,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) => ChatModel(
        id: json['id'].toString(),
        orderId: (json['order_number'] ?? json['order_id']).toString(),
        unreadCount: int.tryParse('${json['unread_count'] ?? 0}') ?? 0,
      );
}
