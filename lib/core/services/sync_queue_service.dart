import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SyncAction {
  final String id;
  final String method;
  final String path;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  SyncAction({
    required this.id,
    required this.method,
    required this.path,
    this.data,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'path': path,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SyncAction.fromJson(Map<String, dynamic> json) => SyncAction(
        id: json['id'],
        method: json['method'],
        path: json['path'],
        data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class SyncQueueService {
  static const _boxName = 'sync_queue';
  final Dio _dio;
  late Box<String> _box;
  StreamSubscription? _subscription;
  bool _isProcessing = false;

  SyncQueueService(this._dio);

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    
    // Listen for connection changes
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      if (!result.contains(ConnectivityResult.none)) {
        processQueue();
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
  }

  Future<void> enqueue(String method, String path, {Map<String, dynamic>? data}) async {
    final action = SyncAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      method: method,
      path: path,
      data: data,
      createdAt: DateTime.now(),
    );
    
    await _box.put(action.id, jsonEncode(action.toJson()));
    
    if (kDebugMode) {
      debugPrint('SyncQueue: Action enqueued - ${action.method} ${action.path}');
    }
  }

  Future<void> processQueue() async {
    if (_isProcessing || _box.isEmpty) return;
    
    _isProcessing = true;
    if (kDebugMode) {
      debugPrint('SyncQueue: Processing ${_box.length} actions');
    }

    final keys = _box.keys.toList();
    for (final key in keys) {
      try {
        final jsonString = _box.get(key);
        if (jsonString == null) continue;
        
        final action = SyncAction.fromJson(jsonDecode(jsonString));
        
        if (action.method == 'POST') {
          await _dio.post(action.path, data: action.data);
        } else if (action.method == 'PUT') {
          await _dio.put(action.path, data: action.data);
        } else if (action.method == 'PATCH') {
          await _dio.patch(action.path, data: action.data);
        }
        
        await _box.delete(key);
        if (kDebugMode) {
          debugPrint('SyncQueue: Action success - ${action.method} ${action.path}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('SyncQueue: Action failed - $e');
        }
        // Keep in queue if it failed due to network
      }
    }
    
    _isProcessing = false;
  }
}
