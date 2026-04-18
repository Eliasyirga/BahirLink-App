import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:first_app/services/kebele_service.dart';
import 'package:first_app/services/case_service.dart';
import '../categories/category_selection_page.dart';
import '../auth/signup_page.dart';

class GuestDashboardContent extends StatefulWidget {
  const GuestDashboardContent({super.key});

  @override
  State<GuestDashboardContent> createState() => _GuestDashboardContentState();
}

class _GuestDashboardContentState extends State<GuestDashboardContent> {
  // --- 1. BRIGHT THEME COLORS ---
  final Color _kPrimaryBlue = const Color(0xFF1E3A8A); // Rich Navy
  final Color _kAccentBlue = const Color(0xFF3B82F6); // Bright Sky Blue
  final Color _kBackground = const Color(0xFFF8FAFC); // Nearly White Gray
  final Color _kTextPrimary = const Color(0xFF1E293B); // Dark Slate
  final Color _kTextSecondary = const Color(0xFF64748B); // Medium Gray

  // We use a Future to track the loading state properly (Crucial for Web)
  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();
    _dashboardData = _initDashboard();
  }

  Future<Map<String, dynamic>> _initDashboard() async {
    try {
      // 1. Fetch Kebeles
      final kebeleList = await KebeleService().getAllKebeles();
      final Map<String, String> kebeleMap = {};
      for (var k in kebeleList) {
        kebeleMap[k['id'].toString()] = k['name'].toString();
      }

      // 2. Fetch Types
      final typeRes = await http.get(
        Uri.parse("http://localhost:5000/api/emergencyType"),
      );
      final List<dynamic> types =
          jsonDecode(typeRes.body)["emergencyTypes"] ?? [];

      // 3. Fetch Cases
      final cases = await CaseService.getAllCases() ?? [];

      return {'kebeles': kebeleMap, 'types': types, 'cases': cases};
    } catch (e) {
      debugPrint("Data Fetch Error: $e");
      // Fallbacks on error
      return {'kebeles': <String, String>{}, 'types': [], 'cases': []};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground, // BRIGHT background
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          // While loading, show the spinner in the primary blue color
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: _kPrimaryBlue),
            );
          }

          // Safe data extraction with fallbacks
          final data =
              snapshot.data ?? {'kebeles': {}, 'types': [], 'cases': []};
          final List<dynamic> cases = data['cases'] as List<dynamic>;
          final List<dynamic> types = data['types'] as List<dynamic>;
          final Map<String, String> kebeleMap =
              data['kebeles'] as Map<String, String>;

          return Column(
            children: [
              _buildModernHeader(), // BRIGHT gradient header
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  children: [
                    _buildSectionLabel(
                      "Live Alerts",
                      "Stay updated on local safety",
                    ),
                    const SizedBox(height: 16),
                    _buildCaseSlider(cases, kebeleMap), // BRIGHT alert cards
                    const SizedBox(height: 32),
                    _buildSectionLabel(
                      "Quick Report",
                      "Tap a category to begin",
                    ),
                    const SizedBox(height: 16),
                    _buildEmergencyGrid(types), // BRIGHT white grid
                    const SizedBox(height: 32),
                    _buildPremiumSignupCard(), // BRIGHT signup card
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- REWRITTEN SLIDER (Bright, professional cards) ---
  Widget _buildCaseSlider(List<dynamic> cases, Map<String, String> kebeleMap) {
    if (cases.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            "No active reports at this time.",
            style: TextStyle(color: _kTextSecondary, fontSize: 13),
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: cases.length,
        itemBuilder: (context, index) {
          final c = cases[index];
          final dynamic loc = c['lastSeenLocationId'];

          String kebeleDisplay = "Unknown Area";
          if (loc is Map) {
            kebeleDisplay = loc['name']?.toString() ?? "Unnamed Area";
          } else if (loc != null) {
            kebeleDisplay = kebeleMap[loc.toString()] ?? "Kebele $loc";
          }

          final String imageUrl =
              (c['mediaUrl'] != null && c['mediaUrl'].isNotEmpty)
              ? "http://localhost:5000${c['mediaUrl']}"
              : "https://via.placeholder.com/150";

          return Container(
            width: 260,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                _buildGradientOverlay(), // Subtle dark gradient for white text legibility
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopChips(c),
                      const Spacer(),
                      Text(
                        c['fullName'] ?? "Incident",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        kebeleDisplay,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- REWRITTEN EMERGENCY GRID (Bright white cards) ---
  Widget _buildEmergencyGrid(List<dynamic> types) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: types.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final type = types[index];
        final Color typeColor = _getColor(type["name"]);
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
              color: Colors.white, // Bright white background
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon wrapper with faint color background
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(type["name"]),
                    color: typeColor,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  type["name"],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: _kTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- HEADER (Bright Blue Gradient) ---
  Widget _buildModernHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimaryBlue, _kAccentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: _kPrimaryBlue.withOpacity(0.2),
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
                  color: Colors.white70,
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
                ),
              ),
            ],
          ),
          _buildGuestAvatar(),
        ],
      ),
    );
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
            color: _kPrimaryBlue,
          ),
        ),
        Text(sub, style: TextStyle(fontSize: 13, color: _kTextSecondary)),
      ],
    );
  }

  Widget _buildTopChips(dynamic c) {
    return Row(
      children: [
        _buildMiniChip(
          "${c['reward'] ?? '0'} ETB",
          Colors.white.withOpacity(0.2),
          Colors.white,
        ),
        const SizedBox(width: 5),
        // Use accent blue for case type chip on white
        _buildMiniChip(
          (c['caseType'] is Map ? c['caseType']['name'] : "Alert")
              .toString()
              .toUpperCase(),
          _kAccentBlue,
          Colors.white,
        ),
      ],
    );
  }

  Widget _buildMiniChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
      ),
    ),
  );

  Widget _buildGuestAvatar() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
    child: const CircleAvatar(
      backgroundColor: Colors.transparent,
      child: Icon(Icons.person_outline, color: Colors.white),
    ),
  );

  Widget _buildPremiumSignupCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
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
          const Icon(Icons.stars_rounded, color: Colors.orangeAccent, size: 40),
          const SizedBox(height: 16),
          Text(
            "Unlock Full Access",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create an account to track response times and save locations.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _kTextSecondary, height: 1.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignUpPage()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "SIGN UP FOR FREE",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Utility Helpers ---
  IconData _getIcon(String name) {
    if (name.toLowerCase().contains("fire"))
      return Icons.local_fire_department_rounded;
    if (name.toLowerCase().contains("crime")) return Icons.shield_rounded;
    if (name.toLowerCase().contains("medical"))
      return Icons.medical_services_rounded;
    return Icons.warning_rounded;
  }

  Color _getColor(String name) {
    if (name.toLowerCase().contains("fire")) return Colors.redAccent;
    if (name.toLowerCase().contains("crime")) return Colors.indigoAccent;
    if (name.toLowerCase().contains("medical")) return Colors.pinkAccent;
    return Colors.orangeAccent;
  }
}
