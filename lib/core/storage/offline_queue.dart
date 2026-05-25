import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class OfflineRequest {
  final String method;
  final String path;
  final Map<String, dynamic>? data;
  final int timestamp;

  OfflineRequest({
    required this.method,
    required this.path,
    this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'method': method,
      'path': path,
      'data': data,
      'timestamp': timestamp,
    };
  }

  factory OfflineRequest.fromMap(Map<String, dynamic> map) {
    return OfflineRequest(
      method: map['method'] ?? '',
      path: map['path'] ?? '',
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      timestamp: map['timestamp'] ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory OfflineRequest.fromJson(String source) => OfflineRequest.fromMap(json.decode(source));
}

class OfflineQueue {
  static const String boxName = 'offline_requests';
  late Box<String> _box;

  OfflineQueue() {
    _box = Hive.box<String>(boxName);
  }

  Future<void> enqueue(String method, String path, {Map<String, dynamic>? data}) async {
    final request = OfflineRequest(
      method: method,
      path: path,
      data: data,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await _box.add(request.toJson());
  }

  List<MapEntry<int, OfflineRequest>> getPendingRequests() {
    final requests = <MapEntry<int, OfflineRequest>>[];
    for (var key in _box.keys) {
      final value = _box.get(key);
      if (value != null) {
        requests.add(MapEntry(key as int, OfflineRequest.fromJson(value)));
      }
    }
    // Sort by timestamp
    requests.sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
    return requests;
  }

  Future<void> remove(int key) async {
    await _box.delete(key);
  }
}
