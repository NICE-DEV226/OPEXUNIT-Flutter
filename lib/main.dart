import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_locale.dart';
import 'core/auth/session_storage.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await loadSavedLocale();
  await SessionStorage.load();
  runApp(const OpexUnitApp());
}

class OpexUnitApp extends StatefulWidget {
  const OpexUnitApp({super.key});

  @override
  State<OpexUnitApp> createState() => _OpexUnitAppState();
}

class _OpexUnitAppState extends State<OpexUnitApp> {
  @override
  void initState() {
    super.initState();
    appLocaleNotifier.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    appLocaleNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OPEXUNIT',
      locale: appLocaleNotifier.value,
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
