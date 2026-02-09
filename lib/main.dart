import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_locale.dart';
import 'core/auth/session_storage.dart';
import 'core/offline/connectivity_service.dart';
import 'core/offline/sync_service.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    if (kDebugMode) debugPrint('Firebase init (optionnel): $e');
  }
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await loadSavedLocale();
  await SessionStorage.load();
  await ConnectivityService.checkOnline();
  runApp(const OpexUnitApp());
}

class OpexUnitApp extends StatefulWidget {
  const OpexUnitApp({super.key});

  @override
  State<OpexUnitApp> createState() => _OpexUnitAppState();
}

class _OpexUnitAppState extends State<OpexUnitApp> {
  StreamSubscription<bool>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    appLocaleNotifier.addListener(_onLocaleChanged);
    _connectivitySubscription = ConnectivityService.onConnectivityChanged.listen((online) {
      if (online) {
        SyncService.syncPending();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
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
