import 'package:flutter/material.dart';
import '../../core/widgets/bottom_navbar.dart';
import 'dashboard_content.dart';
import '../reports/service_report_page.dart';
import '../profile/profile_page.dart';
import '../reports/reports_page.dart';
import '../settings/settings_page.dart';

class DashboardPage extends StatefulWidget {
  final String userId;
  final String token; // 1. Added token parameter

  const DashboardPage({
    super.key,
    required this.userId,
    required this.token, // Required in constructor
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 2. Added IndexedStack to preserve scroll state of pages when switching tabs
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const DashboardContent(),
          ServiceReportPage(
            userId: widget.userId,
            token: widget.token, // Passing token here
          ),
          const ProfilePage(),
          ReportsPage(
            userId: widget.userId,
            token: widget.token, // Passing token here
          ),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: BahirBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  // Note: I replaced the switch statement with IndexedStack above.
  // It's more efficient for BottomNavBars as it doesn't "re-init"
  // the pages every time you tap a tab.
}
