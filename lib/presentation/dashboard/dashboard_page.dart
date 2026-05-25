import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_app/l10n/app_localizations.dart';
import '../../core/widgets/bottom_navbar.dart';
import '../../services/call_services.dart';
import 'dashboard_content.dart';
import '../reports/service_report_page.dart';
import '../profile/profile_page.dart';
import '../reports/reports_page.dart';
import '../settings/settings_page.dart';

const _kApiBaseUrl = 'http://localhost:5000';

class DashboardPage extends StatefulWidget {
  final String userId;
  final String token;

  const DashboardPage({
    super.key,
    required this.userId,
    required this.token,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // FIX #9: _ensureCallServiceConnected is called synchronously from
    // initState. The method itself is async only for the SharedPreferences
    // fallback path (cold start). The two fast paths — isConnected and
    // widget.token — are synchronous and complete before the first frame,
    // so onIncomingCall (wired by _MyAppState) is guaranteed to be set
    // before any call:incoming event can arrive.
    //
    // Previously this was called as an unawaited async void. While that
    // worked for the fast path, it introduced a subtle ordering risk: if
    // _MyAppState.onIncomingCall wasn't set yet when an incoming call fired
    // during the async gap, the call would be silently dropped.
    //
    // Nothing here needs to await the fallback path either — if we reach
    // SharedPreferences it means no token is in memory, so no call can
    // arrive before the socket finishes connecting anyway.
    _ensureCallServiceConnected();
  }

  // ── CallService wiring ────────────────────────────────────────────────────
  //
  // FIX #10: The original flow was:
  //   1. LoginPage calls CallService.I.connect()      ← socket starts connecting
  //   2. LoginPage calls Navigator.pushReplacement()  ← DashboardPage builds
  //   3. _MyAppState.onIncomingCall is set            ← but socket may already
  //                                                      have fired call:incoming
  //                                                      before step 3!
  //
  // The fix is purely ordering: LoginPage must set onIncomingCall BEFORE
  // calling connect(). That change lives in login_page.dart.
  // DashboardPage's role here is just the safety net for hot restart / cold
  // start where LoginPage was bypassed entirely.
  Future<void> _ensureCallServiceConnected() async {
    // Fast path 1 — socket is up or mid-handshake (normal login flow).
    // isConnected OR isConfigured means connect() was already called by
    // LoginPage, which also wired onIncomingCall first. Nothing to do.
    if (CallService.I.isConnected || CallService.I.isConfigured) {
      CallService.I.ensureConnected();
      return;
    }

    // Fast path 2 — hot restart: LoginPage was skipped but token was passed
    // as a constructor argument. Use it directly.
    if (widget.token.isNotEmpty) {
      CallService.I.connect(
        apiBaseUrl: _kApiBaseUrl,
        token: widget.token,
      );
      return;
    }

    // Fallback — cold start / deep-link: read persisted credentials.
    // By this point onIncomingCall is already set by _MyAppState, so the
    // async gap here is safe.
    final prefs = await SharedPreferences.getInstance();
    final storedToken =
        prefs.getString('accessToken') ?? prefs.getString('token');
    if (storedToken != null && storedToken.isNotEmpty) {
      CallService.I.connect(
        apiBaseUrl: _kApiBaseUrl,
        token: storedToken,
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const DashboardContent(),
          ServiceReportPage(
            userId: widget.userId,
            token: widget.token,
          ),
          const ProfilePage(),
          ReportsPage(
            userId: widget.userId,
            token: widget.token,
          ),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: BahirBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) => setState(() => _selectedIndex = index),
        labels: [
          l10n.navHome,
          l10n.navServices,
          l10n.navProfile,
          l10n.navReports,
          l10n.navSettings,
        ],
      ),
    );
  }
}
