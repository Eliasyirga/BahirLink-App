import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:first_app/services/user_service.dart';
import 'package:first_app/presentation/categories/user_category_selection_page.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  String fullName = "User";
  bool isLoading = true;
  List<dynamic> emergencyTypes = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([_fetchUser(), _fetchEmergencyTypes()]);
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _fetchUser() async {
    try {
      final response = await UserService.getProfile();
      if (response != null) {
        final userData = response.containsKey('user')
            ? response['user']
            : response;
        setState(() {
          fullName = userData["firstName"] ?? "User";
        });
      }
    } catch (e) {
      debugPrint("User fetch error: $e");
    }
  }

  Future<void> _fetchEmergencyTypes() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:5000/api/emergencyType"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => emergencyTypes = data["emergencyTypes"]);
      }
    } catch (e) {
      debugPrint("Emergency type error: $e");
    }
  }

  // ================= HELPERS =================

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
        return const Color(0xFFF87171);
      case "crime":
        return const Color(0xFF818CF8);
      case "medical":
        return const Color(0xFFF472B6);
      case "flood":
        return const Color(0xFF38BDF8);
      default:
        return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF1E40AF),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                _buildSectionLabel(
                  "High Alert Tracking",
                  "Real-time system updates",
                ),
                const SizedBox(height: 16),
                _buildAlertCarousel(),
                const SizedBox(height: 32),
                _buildSectionLabel("Emergency Report", "Quick action required"),
                const SizedBox(height: 16),
                _buildEmergencyGrid(),
                const SizedBox(height: 32),
                _buildSectionLabel(
                  "Public Utilities",
                  "Daily municipal services",
                ),
                const SizedBox(height: 16),
                _buildStaticGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
            letterSpacing: 1.1,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade400),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 35),
      decoration: const BoxDecoration(
        // Updated to a more vibrant, multi-tone blue gradient
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A), // Deep Navy Blue
            Color(0xFF2563EB), // Royal Blue
            Color(0xFF3B82F6), // Bright Azure
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x4D1E40AF), // Soft blue shadow
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Logo Container with Glass Effect
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    "assets/images/logo.webp",
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(
                      Icons.shield_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back,",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Notification badge with more contrast
          _buildNotificationBadge(),
        ],
      ),
    );
  }

  // Adjusted notification badge to match the brighter theme
  Widget _buildNotificationBadge() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: const Icon(
        Icons.notifications_active_outlined,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildAlertCarousel() {
    return SizedBox(
      height: 150,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildAdCard(
            "MISSING PERSON",
            "Jane Smith, Central Ave",
            "REWARD \$10k",
            [const Color(0xFFF59E0B), Colors.orange.shade700],
            Icons.person_search_rounded,
          ),
          const SizedBox(width: 12),
          _buildAdCard("WANTED", "ID #8829 - Dangerous", "PRIORITY", [
            const Color(0xFFEF4444),
            Colors.red.shade900,
          ], Icons.gavel_rounded),
        ],
      ),
    );
  }

  Widget _buildAdCard(
    String title,
    String sub,
    String badge,
    List<Color> colors,
    IconData icon,
  ) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(icon, size: 90, color: Colors.white.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  sub,
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
  }

  Widget _buildEmergencyGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: emergencyTypes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82, // Fixed height-to-width ratio
      ),
      itemBuilder: (context, index) {
        final type = emergencyTypes[index];
        final color = _getColor(type["name"]);
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserCategorySelectionPage(
                emergencyTypeId: type["id"],
                emergencyTypeName: type["name"],
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_getIcon(type["name"]), color: color, size: 20),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: Text(
                    type["name"],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Text(
                  "Report",
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaticGrid() {
    final s = [
      {'t': 'Health', 'i': Icons.health_and_safety_rounded, 'c': Colors.teal},
      {'t': 'Power', 'i': Icons.electric_bolt_rounded, 'c': Colors.amber},
      {'t': 'Water', 'i': Icons.water_drop_rounded, 'c': Colors.blue},
      {'t': 'Inquiry', 'i': Icons.help_center_rounded, 'c': Colors.blueGrey},
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: s.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (c, i) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
              ],
            ),
            child: Icon(
              s[i]['i'] as IconData,
              color: s[i]['c'] as Color,
              size: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s[i]['t'] as String,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
