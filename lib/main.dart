import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:first_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'presentation/home/home_page.dart';
import 'presentation/call/call_page.dart';
import 'services/call_services.dart';

final GlobalKey<NavigatorState>          appNavigatorKey        = GlobalKey<NavigatorState>();

// ── KEY FIX 1 ─────────────────────────────────────────────────────────────────
// Give the root ScaffoldMessenger its own key so we can call
// clearSnackBars() on it before pushing a fullscreen call route.
// Without this, SnackBar _OverlayEntryWidgetState GlobalKeys created by a
// previous page's scaffold linger in the root _Theater while the new page's
// scaffold tries to register them again → "Duplicate GlobalKeys" crash.
final GlobalKey<ScaffoldMessengerState>  appMessengerKey        = GlobalKey<ScaffoldMessengerState>();

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
  // ── KEY FIX 2 ─────────────────────────────────────────────────────────────
  // Track whether a CallPage is being *pushed* (not just open). Using a flag
  // is not enough because CallService.I.connect() is called on every ChatPage
  // initState, which disconnects + reconnects the socket and can fire
  // onIncomingCall a second time during the animation of the first push,
  // causing a second CallPage to be added to the same _Theater.
  //
  // Solution: set _callRouteOpen = true BEFORE the push (synchronously),
  // and keep a Set of known invite fingerprints so reconnect-echoes that
  // arrive for the exact same call are silently dropped even if the flag
  // races.
  bool         _callRouteOpen = false;
  CallInvite?  _activeInvite;
  final Set<String> _seenInviteKeys = {};

  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();

    CallService.I.onIncomingCall = (invite) {
      // Fingerprint — emergencyId + fromSocketId is stable across reconnects
      // for the same physical call.
      final fp = '${invite.emergencyId}|${invite.fromSocketId}';

      // Drop duplicates: same call already open OR seen within this session.
      if (_callRouteOpen) return;
      if (_seenInviteKeys.contains(fp)) return;

      final nav = appNavigatorKey.currentState;
      if (nav == null) return;

      // ── KEY FIX 3 ─────────────────────────────────────────────────────────
      // Clear any in-flight SnackBar overlay entries from the root messenger
      // BEFORE pushing the fullscreen route.  This is the direct fix for the
      // "Duplicate GlobalKeys in _Theater" error: stale
      // _OverlayEntryWidgetState keys are removed from the overlay while the
      // old scaffold is still alive, so the new route's scaffold never sees
      // them.
      appMessengerKey.currentState?.clearSnackBars();

      // Mark as open synchronously — must happen before the async push so any
      // re-entrant socket event that fires during the push animation is blocked.
      _callRouteOpen = true;
      _activeInvite  = invite;
      _seenInviteKeys.add(fp);

      nav.push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => CallPage(invite: invite),
        ),
      ).whenComplete(() {
        _callRouteOpen = false;
        _activeInvite  = null;
        // Remove the fingerprint so the user can receive a genuinely new call
        // for the same emergency after hanging up.
        _seenInviteKeys.remove(fp);
        CallService.I.pendingInvite = null;
      });
    };
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? langCode = prefs.getString('language_code');
    if (langCode != null && mounted) {
      setState(() => _locale = Locale(langCode));
    }
  }

  void setLocale(Locale value) {
    if (mounted) setState(() => _locale = value);
  }

  @override
  void dispose() {
    CallService.I.onIncomingCall = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey:          appNavigatorKey,
      // ── KEY FIX 1 (cont.) ───────────────────────────────────────────────
      scaffoldMessengerKey:  appMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'BahirLink',

      locale: _locale,
      supportedLocales: const [
        Locale('en'),
        Locale('am'),
      ],
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
          primary:   const Color(0xFF1A3BAA),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle:     true,
          backgroundColor: Color(0xFF1A3BAA),
          foregroundColor: Colors.white,
          elevation:       0,
        ),
      ),
      home: const HomePage(),
    );
  }
}