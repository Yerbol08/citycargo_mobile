import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:citycargo_mobile/gen_l10n/app_localizations.dart';
import 'router.dart';
import 'theme.dart';
import 'theme_provider.dart';
import 'locale_provider.dart';

class CityCargo extends ConsumerWidget {
  const CityCargo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'CityCargo',
      theme: buildAppTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
      backButtonDispatcher: CityCargoBackButtonDispatcher(router),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CityCargoBackButtonDispatcher extends RootBackButtonDispatcher {
  final GoRouter _router;

  CityCargoBackButtonDispatcher(this._router);

  @override
  Future<bool> didPopRoute() async {
    final path = _router.routerDelegate.currentConfiguration.uri.path;
    debugPrint('CityCargoBack: $path');

    if (path == '/orders' ||
        path == '/receipts' ||
        path == '/wallet' ||
        path == '/profile') {
      debugPrint('CityCargoBack: redirect to /home');
      _router.go('/home');
      return true;
    }

    if (path == '/courier/orders' ||
        path == '/courier/wallet' ||
        path == '/courier/profile') {
      debugPrint('CityCargoBack: redirect to /courier/dashboard');
      _router.go('/courier/dashboard');
      return true;
    }

    if (path == '/register' ||
        path == '/register/client' ||
        path == '/register/courier' ||
        path == '/courier/pending' ||
        path == '/courier/rejected') {
      debugPrint('CityCargoBack: redirect to /login');
      _router.go('/login');
      return true;
    }

    return super.didPopRoute();
  }
}
