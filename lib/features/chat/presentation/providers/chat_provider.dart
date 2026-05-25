import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/websocket_chat_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/chat_repository.dart';
import '../../domain/models/message_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(apiClientProvider));
});

class ChatState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isSending;
  final bool realtimeUnavailable;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.realtimeUnavailable = false,
    this.error,
  });

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isSending,
    bool? realtimeUnavailable,
    String? error,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        isSending: isSending ?? this.isSending,
        realtimeUnavailable: realtimeUnavailable ?? this.realtimeUnavailable,
        error: error,
      );
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repo;
  final String chatId;
  final String _userId;
  final TokenStorage _tokenStorage;
  WebSocketChatService? _ws;
  Timer? _fallbackTimer;

  ChatNotifier(
    this._repo, {
    required this.chatId,
    required String userId,
    required TokenStorage tokenStorage,
  })  : _userId = userId,
        _tokenStorage = tokenStorage,
        super(const ChatState());

  Future<void> connect() async {
    await loadMessages();
    final ws = WebSocketChatService(
      chatId: chatId,
      tokenStorage: _tokenStorage,
      onNewMessage: loadMessages,
    );
    _ws = ws;

    final connected = await ws.connect();
    if (!connected) {
      if (kDebugMode) {
        debugPrint('WS[$chatId] unavailable, using REST polling');
      }
      state = state.copyWith(realtimeUnavailable: true, error: null);
      _startFallbackPolling();
    }
  }

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: state.messages.isEmpty, error: null);
    try {
      final msgs = await _repo.getMessages(chatId);
      state = state.copyWith(messages: msgs, isLoading: false, error: null);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error:
            '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0437\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044c \u0441\u043e\u043e\u0431\u0449\u0435\u043d\u0438\u044f',
      );
    }
  }

  Future<void> sendMessage(String text) async {
    state = state.copyWith(isSending: true, error: null);
    try {
      await _repo.sendMessage(chatId, _userId, text);
      await loadMessages();
    } catch (_) {
      state = state.copyWith(
        isSending: false,
        error:
            '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u043e\u0442\u043f\u0440\u0430\u0432\u0438\u0442\u044c \u0441\u043e\u043e\u0431\u0449\u0435\u043d\u0438\u0435',
      );
      return;
    }
    state = state.copyWith(isSending: false, error: null);
  }

  Future<void> markRead() async {
    try {
      await _repo.markRead(chatId);
    } catch (e) {
      if (kDebugMode) debugPrint('markRead[$chatId] failed: $e');
    }
  }

  void _startFallbackPolling() {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => loadMessages(),
    );
  }

  @override
  void dispose() {
    _ws?.dispose();
    _fallbackTimer?.cancel();
    super.dispose();
  }
}

final chatProvider =
    StateNotifierProvider.family<ChatNotifier, ChatState, String>(
  (ref, chatId) => ChatNotifier(
    ref.watch(chatRepositoryProvider),
    chatId: chatId,
    userId: ref.read(authProvider).user?.id ?? '',
    tokenStorage: ref.read(tokenStorageProvider),
  ),
);
