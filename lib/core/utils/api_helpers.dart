List<dynamic> extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map) {
    for (final key in ['data', 'orders', 'items', 'results', 'list']) {
      if (data[key] is List) return data[key] as List<dynamic>;
    }
  }
  return [];
}

Map<String, dynamic> extractMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is List && data.isNotEmpty) {
    final first = data.first;
    if (first is Map<String, dynamic>) return first;
    if (first is Map) return Map<String, dynamic>.from(first);
  }
  return {};
}

int parseInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}
