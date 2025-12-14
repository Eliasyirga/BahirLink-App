import 'package:flutter/material.dart';
import '../../core/widgets/bottom_navbar.dart';
import 'dashboard_content.dart';
import '../categories/categories_page.dart';
import '../profile/profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(),
      bottomNavigationBar: BahirBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardContent(); // Post-login dashboard
      case 1:
        return const CategoriesPage();
      case 2:
        return const ProfilePage(); // Fixed: no userData passed
      default:
        return const DashboardContent();
    }
  }
}
