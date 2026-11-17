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

  Future<void> _changeLocale(Locale locale) async {
    if (!_supportedLocales.any((supported) => supported.languageCode == locale.languageCode)) return;
    setState(() => _locale = locale);
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('wisesell_language_code', locale.languageCode);
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
