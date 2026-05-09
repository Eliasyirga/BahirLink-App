import 'package:flutter/material.dart';
import 'package:first_app/l10n/app_localizations.dart';
import '../../core/widgets/bottom_navbar.dart';
import 'dashboard_content.dart';
import '../reports/service_report_page.dart';
import '../profile/profile_page.dart';
import '../reports/reports_page.dart';
import '../settings/settings_page.dart';

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