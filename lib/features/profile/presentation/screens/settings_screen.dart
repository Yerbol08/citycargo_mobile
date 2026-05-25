import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme_provider.dart';
import '../../../../app/locale_provider.dart';
import 'package:citycargo_mobile/gen_l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _SectionHeader(title: l10n.appearance),
          ListTile(
            leading: Icon(Icons.brightness_auto, color: Theme.of(context).colorScheme.primary),
            title: Text(l10n.appTheme),
            subtitle: Text(_themeModeString(themeMode, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => _ThemeSelector(
                  currentMode: themeMode,
                  onChanged: (mode) {
                    ref.read(themeModeProvider.notifier).setThemeMode(mode);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
          const Divider(height: 32),
          _SectionHeader(title: l10n.language),
          ListTile(
            leading: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
            title: Text(l10n.appLanguage),
            subtitle: Text(_localeString(locale)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => _LocaleSelector(
                  currentLocale: locale,
                  onChanged: (newLocale) {
                    ref.read(localeProvider.notifier).setLocale(newLocale);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _themeModeString(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.system:
        return l10n.themeSystem;
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
    }
  }

  String _localeString(Locale locale) {
    switch (locale.languageCode) {
      case 'ru':
        return 'Русский';
      case 'kk':
        return 'Қазақша';
      case 'en':
        return 'English';
      default:
        return 'Русский';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeSelector({
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppLocalizations.of(context)!.selectTheme,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _ThemeTile(
            title: AppLocalizations.of(context)!.themeSystem,
            mode: ThemeMode.system,
            currentMode: currentMode,
            onTap: () => onChanged(ThemeMode.system),
          ),
          _ThemeTile(
            title: AppLocalizations.of(context)!.themeLight,
            mode: ThemeMode.light,
            currentMode: currentMode,
            onTap: () => onChanged(ThemeMode.light),
          ),
          _ThemeTile(
            title: AppLocalizations.of(context)!.themeDark,
            mode: ThemeMode.dark,
            currentMode: currentMode,
            onTap: () => onChanged(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String title;
  final ThemeMode mode;
  final ThemeMode currentMode;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.title,
    required this.mode,
    required this.currentMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: mode == currentMode
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _LocaleSelector extends StatelessWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onChanged;

  const _LocaleSelector({
    required this.currentLocale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppLocalizations.of(context)!.selectLanguage,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _LocaleTile(
            title: 'Русский',
            locale: const Locale('ru'),
            currentLocale: currentLocale,
            onTap: () => onChanged(const Locale('ru')),
          ),
          _LocaleTile(
            title: 'Қазақша',
            locale: const Locale('kk'),
            currentLocale: currentLocale,
            onTap: () => onChanged(const Locale('kk')),
          ),
          _LocaleTile(
            title: 'English',
            locale: const Locale('en'),
            currentLocale: currentLocale,
            onTap: () => onChanged(const Locale('en')),
          ),
        ],
      ),
    );
  }
}

class _LocaleTile extends StatelessWidget {
  final String title;
  final Locale locale;
  final Locale currentLocale;
  final VoidCallback onTap;

  const _LocaleTile({
    required this.title,
    required this.locale,
    required this.currentLocale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: locale.languageCode == currentLocale.languageCode
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
