import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Dotenv is removed in favor of envied for secure API keys

    await initializeDateFormatting('ru');
    await initializeDateFormatting('ru_KZ');

    try {
      await Hive.initFlutter();
      await Hive.openBox('orders_cache');
      await Hive.openBox<String>('offline_requests');
    } catch (e) {
      debugPrint('Hive init failed: $e');
    }

    if (AppConfig.sentryDsn.isNotEmpty) {
      await SentryFlutter.init(
        (options) {
          options.dsn = AppConfig.sentryDsn;
          options.tracesSampleRate = 1.0;
        },
        appRunner: () => _runApp(),
      );
    } else {
      _runApp();
    }

    unawaited(_initializeOptionalServices());
  }, (error, stack) async {
    if (AppConfig.sentryDsn.isNotEmpty) {
      await Sentry.captureException(error, stackTrace: stack);
    }
    debugPrint('Uncaught error: $error');
    debugPrintStack(stackTrace: stack);
  });
}

void _runApp() {
  runApp(const ProviderScope(child: CityCargo()));
}

Future<void> _initializeOptionalServices() async {
  try {
    await Firebase.initializeApp();
    await NotificationService.instance.initialize();
  } catch (e, stackTrace) {
    debugPrint('Optional services initialization failed: $e');
    debugPrintStack(stackTrace: stackTrace);
  }
}
