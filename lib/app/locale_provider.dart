import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  static const _key = 'app_locale';
  final FlutterSecureStorage _storage;

  LocaleNotifier(this._storage) : super(const Locale('ru')) {
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await _storage.read(key: _key);
      if (value != null && ['ru', 'kk', 'en'].contains(value)) {
        state = Locale(value);
      }
    } catch (_) {}
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    try {
      await _storage.write(key: _key, value: locale.languageCode);
    } catch (_) {}
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(const FlutterSecureStorage());
});
