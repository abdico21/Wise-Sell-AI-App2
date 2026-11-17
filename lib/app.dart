import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
import 'l10n/app_localizations.dart';

class WiseSellApp extends StatefulWidget {
  const WiseSellApp({super.key});

  @override
  State<WiseSellApp> createState() => _WiseSellAppState();
}

class _WiseSellAppState extends State<WiseSellApp> {
  Locale _locale = const Locale('en');
  bool _localeReady = false;

  @override
  void initState() {
    super.initState();
    _restoreLocale();
  }

  Future<void> _restoreLocale() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedCode = preferences.getString('wisesell_language_code');
      if (savedCode != null && mounted) {
        final savedLocale = _supportedLocales.firstWhere(
          (locale) => locale.languageCode == savedCode,
          orElse: () => const Locale('en'),
        );
        setState(() => _locale = savedLocale);
      }
    } catch (_) {
      // Keep English as a safe fallback when local storage is unavailable.
    } finally {
      if (mounted) setState(() => _localeReady = true);
    }
  }

  void _changeLocale(Locale locale) {
    if (!_supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    )) {
      return;
    }
    if (_locale.languageCode == locale.languageCode) return;

    // Update the UI immediately; saving the preference must never delay a
    // locale rebuild or block the language selector.
    setState(() => _locale = locale);
    unawaited(_persistLocale(locale.languageCode));
  }

  Future<void> _persistLocale(String languageCode) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('wisesell_language_code', languageCode);
    } catch (_) {
      // The selected language remains active for this session if saving fails.
    }
  }

  static const _supportedLocales = [
    Locale('en'),
    Locale('am'),
    Locale('om'),
    Locale('ti'),
    Locale('so'),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiseSell AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: _locale,
      supportedLocales: _supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        // Flutter's built-in Material, Widgets and Cupertino delegates do not
        // include Afaan Oromo ('om'). Keep app text in Oromo while providing
        // English framework labels/direction for standard Flutter controls.
        _OromoMaterialLocalizationsDelegate(),
        _OromoWidgetsLocalizationsDelegate(),
        _OromoCupertinoLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _localeReady
          ? HomeScreen(onLocaleChanged: _changeLocale)
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class _OromoMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _OromoMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'om';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(_OromoMaterialLocalizationsDelegate old) => false;
}

class _OromoWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _OromoWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'om';

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(_OromoWidgetsLocalizationsDelegate old) => false;
}

class _OromoCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _OromoCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'om';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(_OromoCupertinoLocalizationsDelegate old) => false;
}
