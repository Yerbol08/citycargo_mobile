import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';

class WebSocketChatService {
  final String chatId;
  final TokenStorage _tokenStorage;
  final void Function() onNewMessage;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  bool _disposed = false;

  WebSocketChatService({
    required this.chatId,
    required TokenStorage tokenStorage,
    required this.onNewMessage,
  }) : _tokenStorage = tokenStorage;

  Future<bool> connect() async {
    if (_disposed) return false;
    final token = await _tokenStorage.getToken();
    if (token == null) return false;

    try {
      final uri = _buildUri(token);
      if (kDebugMode) debugPrint('WS[$chatId] connecting: ${_masked(uri)}');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _sub = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      if (kDebugMode) debugPrint('WS[$chatId] connected');
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('WS[$chatId] connect failed: ${_safeError(e)}');
      }
      return false;
    }
  }

  void _onData(dynamic raw) {
    if (kDebugMode) debugPrint('WS[$chatId] message: $raw');
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = json['type'] as String?;
      if (type == 'new_message' ||
          type == 'message' ||
          type == 'chat_message') {
        onNewMessage();
      }
    } catch (_) {
      // Unknown format, treat as "something happened, refresh".
      onNewMessage();
    }
  }

  void _onError(Object error) {
    if (kDebugMode) debugPrint('WS[$chatId] error: ${_safeError(error)}');
    _scheduleReconnect();
  }

  void _onDone() {
    if (kDebugMode) debugPrint('WS[$chatId] connection closed');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 30), connect);
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
  }

  Uri _buildUri(String token) {
    final configured = Uri.parse(AppConfig.wsUrl);
    final apiBase = Uri.parse(AppConfig.apiUrl);
    final source = configured.host.isNotEmpty ? configured : apiBase;
    final scheme = switch (source.scheme) {
      'ws' || 'wss' => source.scheme,
      'http' => 'ws',
      _ => 'wss',
    };

    final path = source.pathSegments.where((s) => s.isNotEmpty).toList();
    final hasApiV1 = path.length >= 2 &&
        path[path.length - 2] == 'api' &&
        path[path.length - 1] == 'v1';
    final segments = <String>[
      ...path,
      if (!hasApiV1) ...['api', 'v1'],
      'chats',
      chatId,
      'ws',
    ];

    return Uri(
      scheme: scheme,
      host: source.host,
      port: source.hasPort && source.port > 0 ? source.port : null,
      pathSegments: segments,
      queryParameters: {'token': token},
    );
  }

  String _masked(Uri uri) {
    return uri.replace(queryParameters: {'token': '***'}).toString();
  }

  String _safeError(Object error) {
    return error.toString().replaceAll(RegExp(r'token=[^&#\s]+'), 'token=***');
  }
}
