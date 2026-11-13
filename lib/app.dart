import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
      home: HomeScreen(
        onLocaleChanged: (locale) => setState(() => _locale = locale),
      ),
    );
  }
}
