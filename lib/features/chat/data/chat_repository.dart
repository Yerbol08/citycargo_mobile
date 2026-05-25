import '../../../core/api/api_client.dart';
import '../../../core/utils/api_helpers.dart';
import '../domain/models/chat_model.dart';
import '../domain/models/message_model.dart';

class ChatRepository {
  final ApiClient _client;

  ChatRepository(this._client);

  Future<ChatModel> getOrCreateChat(String orderId) async {
    final encodedId = Uri.encodeComponent(orderId);
    try {
      final existing = await getChats(orderId);
      if (existing.isNotEmpty) return existing.first;
    } catch (_) {
      // If the list endpoint is unavailable for an empty chat, create it below.
    }

    final data = await _client.post(
      '/api/v1/orders/$encodedId/chats',
      data: {'chat_type': 'order'},
    );
    return ChatModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<ChatModel>> getChats(String orderId) async {
    final encodedId = Uri.encodeComponent(orderId);
    final data = await _client.get('/api/v1/orders/$encodedId/chats');
    final list = extractList(data['data'] ?? data);
    return list
        .map((e) => ChatModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MessageModel>> getMessages(String chatId) async {
    final encodedId = Uri.encodeComponent(chatId);
    final data = await _client.get('/api/v1/chats/$encodedId/messages');
    final list = extractList(data['data'] ?? data);
    return list
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendMessage(String chatId, String authorId, String body) async {
    final encodedId = Uri.encodeComponent(chatId);
    await _client.post(
      '/api/v1/chats/$encodedId/messages',
      data: {'author_id': authorId, 'body': body},
    );
  }

  Future<void> markRead(String chatId) async {
    final encodedId = Uri.encodeComponent(chatId);
    await _client.post('/api/v1/chats/$encodedId/read');
  }
}
