import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:first_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'presentation/home/home_page.dart';
import 'presentation/call/call_page.dart';
import 'services/call_services.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _callRouteOpen = false;
  CallInvite? _activeInvite;
  Locale _locale = const Locale('en'); 

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();

    CallService.I.onIncomingCall = (invite) {
      final nav = appNavigatorKey.currentState;
      if (nav == null) return;

      if (_callRouteOpen &&
          _activeInvite != null &&
          _activeInvite!.emergencyId == invite.emergencyId &&
          _activeInvite!.fromSocketId == invite.fromSocketId) {
        return;
      }
      if (_callRouteOpen) return;

      _callRouteOpen = true;
      _activeInvite = invite;

      nav.push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => CallPage(invite: invite),
        ),
      ).whenComplete(() {
        _callRouteOpen = false;
        _activeInvite = null;
        CallService.I.pendingInvite = null;
      });
    };
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? langCode = prefs.getString('language_code');
    if (langCode != null) {
      setState(() {
        _locale = Locale(langCode);
      });
    }
  }

  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  @override
  void dispose() {
    CallService.I.onIncomingCall = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'BahirLink',
      
      locale: _locale,
      supportedLocales: const [
        Locale('en'),
        Locale('am'),
      ],
      // REMOVED 'const' FROM HERE:
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A3BAA),
          primary: const Color(0xFF1A3BAA),
        ),
        useMaterial3: true,
        // Added a consistent AppBar theme for your industrial design
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFF1A3BAA),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}
