import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Services
import 'package:first_app/services/user_service.dart';
import 'package:first_app/services/case_service.dart';
import 'package:first_app/services/service_type_service.dart';
import 'package:first_app/services/emergency_type_service.dart';

// Models & Pages
import 'package:first_app/model/emergency_type.dart';
import 'package:first_app/presentation/categories/user_category_selection_page.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  // --- State Variables ---
  String fullName = "User";
  bool isLoading = true;
  List<dynamic> cases = [];
  List<EmergencyType> emergencyTypes = [];
  List<dynamic> serviceTypes = [];

  // --- Design System ---
  static const Color primaryBlue = Color(0xFF2B7CFF);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color surfaceWhite = Colors.white;
  static const Color backgroundGray = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color iconBg = Color(0xFFF1F5F9);

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      await Future.wait([
        _fetchUser(),
        _fetchEmergencyTypes(),
        _fetchServiceTypes(),
        _fetchCases(),
      ]);
    } catch (e) {
      debugPrint("Dashboard Sync Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- Logic Layer ---

  Future<void> _fetchUser() async {
    final response = await UserService.getProfile();
    if (response != null && mounted) {
      final userData = response['user'] ?? response;
      setState(() => fullName = userData["firstName"] ?? "User");
    }
  }

  Future<void> _fetchEmergencyTypes() async {
    try {
      final data = await EmergencyTypeService.fetchEmergencyTypes();
      if (mounted) setState(() => emergencyTypes = data);
    } catch (e) {
      debugPrint("Emergency Fetch Error: $e");
    }
  }

  Future<void> _fetchServiceTypes() async {
    final data = await ServiceTypeService.getAllServiceTypes();
    if (mounted) setState(() => serviceTypes = data ?? []);
  }

  Future<void> _fetchCases() async {
    final data = await CaseService.getAllCases();
    if (mounted) setState(() => cases = data ?? []);
  }

  /// Extracts only the display name from the case type data
  String _formatCaseType(dynamic caseType) {
    if (caseType == null) return "ALERT";

    // If it's a Map (JSON object), pull the 'name' field
    if (caseType is Map && caseType.containsKey('name')) {
      return caseType['name'].toString().toUpperCase();
    }

    // Otherwise, treat as raw string and clean it
    return caseType.toString().toUpperCase();
  }

  // --- Build Layer ---

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: backgroundGray,
        body: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundGray,
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        color: primaryBlue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Active Intel", () {}),
                    const SizedBox(height: 16),
                    _buildIntelSlider(),

                    const SizedBox(height: 32),
                    _buildSectionHeader("Emergency Protocols", () {}),
                    const SizedBox(height: 16),
                    _buildEmergencyGrid(),

                    const SizedBox(height: 32),
                    _buildSectionHeader("Service Network", () {}),
                    const SizedBox(height: 16),
                    _buildServiceList(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: primaryBlue,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, $fullName ",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Bahir Dar, Ethiopia",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              _buildAppBarAction(Icons.notifications_none_rounded),
            ],
          ),
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
    );
  }

  Widget _buildIntelSlider() {
    if (cases.isEmpty) return _buildEmptyState("No active intel reports.");

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: cases.length,
        itemBuilder: (context, index) {
          final c = cases[index];
          final String imageUrl = c['mediaUrl'] != null
              ? "http://localhost:5000${c['mediaUrl']}"
              : "https://via.placeholder.com/400";

          return Container(
            width: MediaQuery.of(context).size.width * 0.82,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4),
                  BlendMode.darken,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _badge(
                      "${c['reward'] ?? '0'} ETB",
                      primaryBlue,
                      Colors.white,
                    ),
                    _badge(
                      _formatCaseType(c['caseType']),
                      accentRed,
                      Colors.white,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  c['fullName'] ?? "Unnamed Incident",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _infoIcon(
                      Icons.location_on_rounded,
                      c['Kebele']?['name'] ?? "Unknown Area",
                    ),
                    const SizedBox(width: 16),
                    _infoIcon(
                      Icons.access_time_filled_rounded,
                      _formatDate(c['updatedAt']),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmergencyGrid() {
    if (emergencyTypes.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: emergencyTypes.length,
      itemBuilder: (context, index) {
        final type = emergencyTypes[index];
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserCategorySelectionPage(
                emergencyTypeId: type.id,
                emergencyTypeName: type.name,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: surfaceWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: iconBg,
                  child: Icon(_getIcon(type.name), color: primaryBlue),
                ),
                const SizedBox(height: 10),
                Text(
                  type.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceList() {
    return Column(
      children: serviceTypes
          .map(
            (s) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: surfaceWhite,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: iconBg,
                  child: Icon(Icons.hub_outlined, color: primaryBlue, size: 20),
                ),
                title: Text(
                  s['name'] ?? "Service",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: textMuted,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textDark,
        ),
      ),
      TextButton(
        onPressed: onSeeAll,
        child: const Text(
          "View All",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );

  Widget _buildAppBarAction(IconData icon) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      shape: BoxShape.circle,
    ),
    child: IconButton(
      icon: Icon(icon, color: Colors.white, size: 22),
      onPressed: () {},
    ),
  );

  Widget _badge(String label, Color bg, Color txt) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: txt,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _infoIcon(IconData icon, String text) => Row(
    children: [
      Icon(icon, color: Colors.white70, size: 16),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
    ],
  );

  Widget _buildEmptyState(String msg) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(
      color: surfaceWhite,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        Icon(Icons.query_stats, color: textMuted.withOpacity(0.3), size: 48),
        const SizedBox(height: 12),
        Text(msg, style: const TextStyle(color: textMuted)),
      ],
    ),
  );

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "Recent";
    try {
      return DateFormat('MMM d, h:mm a').format(DateTime.parse(dateStr));
    } catch (_) {
      return "Recent";
    }
  }

  IconData _getIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains("fire")) return Icons.local_fire_department_rounded;
    if (n.contains("police") || n.contains("crime"))
      return Icons.shield_rounded;
    if (n.contains("medical")) return Icons.health_and_safety_rounded;
    return Icons.grid_view_rounded;
  }
}
