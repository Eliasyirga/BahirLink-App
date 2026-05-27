import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:first_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'presentation/home/home_page.dart';
import 'presentation/call/call_page.dart';
import 'services/call_services.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

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
  Locale _locale = const Locale('en');
  bool _callRouteOpen = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
    CallService.I.onIncomingCall = _handleIncomingCall;
    _coldStartConnect();
  }

  @override
  void dispose() {
    CallService.I.onIncomingCall = null;
    super.dispose();
  }

  // ── Cold-start / hot-restart connect ─────────────────────────────────────
  Future<void> _coldStartConnect() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (CallService.I.isConnected || CallService.I.isConfigured) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    if (token != null && token.isNotEmpty) {
      // CallService.wsServerUrl handles local vs production internally
      CallService.I.connect(token: token);
    }
  }

  // ── Incoming call handler ─────────────────────────────────────────────────
  void _handleIncomingCall(CallInvite invite) {
    if (_callRouteOpen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pushCallPage(invite);
    });
  }

  void _pushCallPage(CallInvite invite) {
    if (_callRouteOpen) return;

    final nav = appNavigatorKey.currentState;
    if (nav == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _pushCallPage(invite));
      return;
    }

    appMessengerKey.currentState?.clearSnackBars();
    _callRouteOpen = true;

    nav
        .push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => CallPage(invite: invite),
      ),
    )
        .whenComplete(() {
      _callRouteOpen = false;
      CallService.I.clearCall(invite.emergencyId);
    });
  }

  // ── Locale ────────────────────────────────────────────────────────────────
  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language_code');
    if (langCode != null && mounted) {
      setState(() => _locale = Locale(langCode));
    }
  }

  void setLocale(Locale value) {
    if (mounted) setState(() => _locale = value);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'BahirLink',
      locale: _locale,
      supportedLocales: const [
        Locale('en'),
        Locale('am'),
      ],
      localizationsDelegates: const [
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
