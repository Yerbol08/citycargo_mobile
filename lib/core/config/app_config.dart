import 'env.dart';

class AppConfig {
  static String get baseUrl => Env.baseUrl;
  static String get wsUrl => Env.wsUrl;
  static String get sentryDsn => Env.sentryDsn;
  
  static String get apiUrl => baseUrl;
}
