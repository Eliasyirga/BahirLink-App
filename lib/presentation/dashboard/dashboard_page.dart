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
    _ensureCallServiceConnected();
  }

  // ── CallService wiring ────────────────────────────────────────────────────
  //
  // LoginPage already called CallService.I.connect() synchronously.
  // This method is a safety-net for:
  //   • Hot restart  — LoginPage was skipped, socket is null.
  //   • Cold start   — deep-link straight to DashboardPage.
  //   • Transport drop between LoginPage and here.
  //
  // isConfigured is true the moment connect() is called (before the socket
  // physically connects), so the fast-path catches the normal login flow
  // and avoids destroying the mid-handshake socket.
  Future<void> _ensureCallServiceConnected() async {
    // Fast path — socket is up or mid-handshake (normal login flow).
    if (CallService.I.isConnected || CallService.I.isConfigured) {
      CallService.I.ensureConnected();
      return;
    }

    // widget.token is the authoritative source right after login.
    if (widget.token.isNotEmpty) {
      CallService.I.connect(
        apiBaseUrl: _kApiBaseUrl,
        token:      widget.token,
      );
      return;
    }

    // Fallback: hot restart / cold start — read persisted credentials.
    final prefs = await SharedPreferences.getInstance();
    final storedToken =
        prefs.getString('accessToken') ?? prefs.getString('token');
    if (storedToken != null && storedToken.isNotEmpty) {
      CallService.I.connect(
        apiBaseUrl: _kApiBaseUrl,
        token:      storedToken,
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
            token:  widget.token,
          ),
          const ProfilePage(),
          ReportsPage(
            userId: widget.userId,
            token:  widget.token,
          ),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: BahirBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) =>
            setState(() => _selectedIndex = index),
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