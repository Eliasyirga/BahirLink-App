import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:first_app/services/user_service.dart';
import 'package:first_app/services/service_type_service.dart';
import 'package:first_app/services/case_service.dart';
import 'package:first_app/presentation/categories/user_category_selection_page.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  String fullName = "User";
  bool isLoading = true;

  // Initialize as empty lists to prevent .isEmpty errors on null
  List<dynamic> emergencyTypes = [];
  List<dynamic> serviceTypes = [];
  List<dynamic> cases = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Future.wait([
        _fetchUser(),
        _fetchEmergencyTypes(),
        _fetchServiceTypes(),
        _fetchCases(),
      ]);
    } catch (e) {
      debugPrint("Initialization error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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
      // Changed to localhost for Web compatibility
      final response = await http.get(
        Uri.parse("http://localhost:5000/api/emergencyType"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => emergencyTypes = data["emergencyTypes"] ?? []);
      }
    } catch (e) {
      debugPrint("Emergency type error: $e");
      setState(() => emergencyTypes = []);
    }
  }

  Future<void> _fetchServiceTypes() async {
    try {
      final data = await ServiceTypeService.getAllServiceTypes();
      setState(() => serviceTypes = data ?? []);
    } catch (e) {
      debugPrint("Service type error: $e");
      setState(() => serviceTypes = []);
    }
  }

  Future<void> _fetchCases() async {
    try {
      final data = await CaseService.getAllCases();
      setState(() => cases = data ?? []);
    } catch (e) {
      debugPrint("Cases fetch error: $e");
      setState(() => cases = []);
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
      case "health":
        return Icons.health_and_safety_rounded;
      case "power":
      case "electricity":
        return Icons.electric_bolt_rounded;
      case "water":
        return Icons.water_drop_rounded;
      case "missing":
        return Icons.person_search_rounded;
      case "wanted":
        return Icons.gavel_rounded;
      default:
        return Icons.grid_view_rounded;
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
        return const Color(0xFF64748B);
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
                _buildDynamicServiceGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 35),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildLogo(),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back,",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildNotificationBadge(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          "assets/images/logo.webp",
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) =>
              const Icon(Icons.shield_rounded, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildNotificationBadge() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.notifications_active_outlined,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildAlertCarousel() {
    // Added explicit null check before calling .isEmpty
    if (cases.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Text(
          "No active alerts",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: cases.length,
        itemBuilder: (context, index) {
          final item = cases[index];
          final type = item['type']?.toString().toLowerCase() ?? "";
          final isWanted = type == 'wanted';

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildAdCard(
              (item['title'] ?? "Alert").toUpperCase(),
              item['description'] ?? "No details available",
              (item['label'] ?? "Priority").toUpperCase(),
              isWanted
                  ? [const Color(0xFFEF4444), Color(0xFF7F1D1D)]
                  : [const Color(0xFFF59E0B), Color(0xFFC2410C)],
              isWanted ? Icons.gavel_rounded : Icons.person_search_rounded,
            ),
          );
        },
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  sub,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

  Widget _buildEmergencyGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: emergencyTypes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final type = emergencyTypes[index];
        final color = _getColor(type["name"] ?? "");
        return InkWell(
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
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getIcon(type["name"] ?? ""), color: color, size: 20),
                const SizedBox(height: 6),
                Text(
                  type["name"] ?? "Report",
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDynamicServiceGrid() {
    if (serviceTypes.isEmpty) {
      return const Center(
        child: Text(
          "No services found",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: serviceTypes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final service = serviceTypes[index];
        final name = service["name"] ?? "Utility";
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getIcon(name),
                color: const Color(0xFF2563EB),
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        );
      },
    );
  }
}
