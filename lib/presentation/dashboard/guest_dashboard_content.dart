import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../categories/category_selection_page.dart';
import '../auth/signup_page.dart'; // Ensure the class inside this file is named 'SignupPage'

class GuestDashboardContent extends StatefulWidget {
  const GuestDashboardContent({super.key});

  @override
  State<GuestDashboardContent> createState() => _GuestDashboardContentState();
}

class _GuestDashboardContentState extends State<GuestDashboardContent> {
  bool isLoading = true;
  List<dynamic> emergencyTypes = [];

  // Consistent Brand Colors
  final Color primaryBlue = const Color(0xFF1E3A8A);
  final Color accentBlue = const Color(0xFF3B82F6);
  final Color backgroundGray = const Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _fetchEmergencyTypes();
  }

  Future<void> _fetchEmergencyTypes() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:5000/api/emergencyType"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          emergencyTypes = data["emergencyTypes"];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("API Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: backgroundGray,
        body: Center(child: CircularProgressIndicator(color: primaryBlue)),
      );
    }

    return Scaffold(
      backgroundColor: backgroundGray,
      body: Column(
        children: [
          _buildModernHeader(),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                _buildSectionLabel(
                  "Live Alerts",
                  "Stay updated on local safety",
                ),
                const SizedBox(height: 16),
                _buildAlertCarousel(),
                const SizedBox(height: 32),
                _buildSectionLabel("Quick Report", "Tap a category to begin"),
                const SizedBox(height: 16),
                _buildGlassEmergencyGrid(),
                const SizedBox(height: 32),
                _buildPremiumSignupCard(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "BAHIRLINK ASSIST",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Guest Mode",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          _buildGuestAvatar(),
        ],
      ),
    );
  }

  Widget _buildGuestAvatar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: const CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Icon(Icons.person_outline, color: Colors.white),
      ),
    );
  }

  Widget _buildGlassEmergencyGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: emergencyTypes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final type = emergencyTypes[index];
        final color = _getColor(type["name"]);
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategorySelectionPage(
                emergencyTypeId: type["id"],
                emergencyTypeName: type["name"],
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getIcon(type["name"]), color: color, size: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  type["name"],
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: primaryBlue.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumSignupCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.blue.shade100.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.stars_rounded, color: accentBlue, size: 40),
          const SizedBox(height: 16),
          Text(
            "Unlock Full Access",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Create an account to track response times and save locations.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.blueGrey, height: 1.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignUpPage(),
                  ), // Capital 'U' added here
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "SIGN UP FOR FREE",
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Utility Builders ---

  IconData _getIcon(String name) {
    switch (name.toLowerCase()) {
      case "fire":
        return Icons.local_fire_department_rounded;
      case "crime":
        return Icons.shield_rounded;
      case "medical":
        return Icons.medical_services_rounded;
      case "flood":
        return Icons.tsunami_rounded;
      default:
        return Icons.warning_rounded;
    }
  }

  Color _getColor(String name) {
    switch (name.toLowerCase()) {
      case "fire":
        return const Color(0xFFEF4444);
      case "crime":
        return const Color(0xFF6366F1);
      case "medical":
        return const Color(0xFFEC4899);
      case "flood":
        return const Color(0xFF0EA5E9);
      default:
        return Colors.orangeAccent;
    }
  }

  Widget _buildSectionLabel(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1.5,
            color: primaryBlue.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.blueGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCarousel() {
    return SizedBox(
      height: 150,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildAlertCard(
            "MISSING PERSON",
            "REWARD: \$10,000",
            Icons.person_search,
            [const Color(0xFFF59E0B), const Color(0xFFD97706)],
          ),
          const SizedBox(width: 14),
          _buildAlertCard(
            "STORM ALERT",
            "STAY INDOORS",
            Icons.thunderstorm_rounded,
            [const Color(0xFF1E293B), const Color(0xFF475569)],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(
    String title,
    String tag,
    IconData icon,
    List<Color> colors,
  ) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            bottom: -15,
            child: Icon(icon, size: 90, color: Colors.white.withOpacity(0.15)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tag,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
