import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Internal Services
import 'package:first_app/services/user_service.dart';
import 'package:first_app/services/case_service.dart';
import 'package:first_app/services/emergency_type_service.dart';

// Models & Pages
import 'package:first_app/model/emergency_type.dart';
import 'package:first_app/model/service_type.dart'; // Ensure this model exists
import 'package:first_app/presentation/categories/user_category_selection_page.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  // --- State Variables ---
  String _fullName = "User";
  bool _isLoading = true;
  List<dynamic> _cases = [];
  List<EmergencyType> _emergencyTypes = [];
  List<ServiceType> _serviceTypes = []; // Updated to Model Type

  // --- Design System Constants ---
  static const Color _kPrimaryBlue = Color(0xFF2B7CFF);
  static const Color _kAccentRed = Color(0xFFEF4444);
  static const Color _kSurfaceWhite = Colors.white;
  static const Color _kBackgroundGray = Color(0xFFF8FAFC);
  static const Color _kTextDark = Color(0xFF0F172A);
  static const Color _kTextMuted = Color(0xFF64748B);
  static const Color _kIconBg = Color(0xFFF1F5F9);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Logic Layer ---

  Future<void> _fetchUser() async {
    final response = await UserService.getProfile();
    if (response != null && mounted) {
      final userData = response['user'] ?? response;
      setState(() => _fullName = userData["firstName"] ?? "User");
    }
  }

  Future<void> _fetchEmergencyTypes() async {
    try {
      final data = await EmergencyTypeService.fetchEmergencyTypes();
      if (mounted) setState(() => _emergencyTypes = data);
    } catch (e) {
      debugPrint("Emergency Fetch Error: $e");
    }
  }

  Future<void> _fetchServiceTypes() async {
    try {
      final data = await ServiceTypeService.getAllServiceTypes();
      if (mounted) setState(() => _serviceTypes = data);
    } catch (e) {
      debugPrint("Service Fetch Error: $e");
    }
  }

  Future<void> _fetchCases() async {
    final data = await CaseService.getAllCases();
    if (mounted) setState(() => _cases = data ?? []);
  }

  // --- Build Layer ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _kBackgroundGray,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _kPrimaryBlue,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kBackgroundGray,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: _kPrimaryBlue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionHeader("Active Intel", () {}),
                  const SizedBox(height: 16),
                  _buildIntelSlider(),
                  const SizedBox(height: 32),
                  _buildSectionHeader("Emergency Protocols", () {}),
                  const SizedBox(height: 16),
                  _buildBentoGrid(_emergencyTypes, isEmergency: true),
                  const SizedBox(height: 32),
                  _buildSectionHeader("Service Network", () {}),
                  const SizedBox(height: 16),
                  _buildBentoGrid(_serviceTypes, isEmergency: false),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: _kPrimaryBlue,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
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
                      "Hello, $_fullName 👋",
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
    if (_cases.isEmpty) return _buildEmptyState("No active intel reports.");

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _cases.length,
        itemBuilder: (context, index) {
          final c = _cases[index];
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
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBadge("${c['reward'] ?? '0'} ETB", _kPrimaryBlue),
                    _buildBadge(
                      (c['caseType']?['name'] ?? "ALERT")
                          .toString()
                          .toUpperCase(),
                      _kAccentRed,
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
                    _buildInfoItem(
                      Icons.location_on_rounded,
                      c['Kebele']?['name'] ?? "Unknown Area",
                    ),
                    const SizedBox(width: 16),
                    _buildInfoItem(Icons.access_time_filled_rounded, "Recent"),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBentoGrid(List<dynamic> items, {required bool isEmergency}) {
    if (items.isEmpty) return _buildEmptyState("No resources available.");

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        // Now consistently uses .name and .id because both are model objects
        final String name = item.name;
        final String id = item.id.toString();

        return Material(
          color: _kSurfaceWhite,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserCategorySelectionPage(
                    emergencyTypeId: id,
                    emergencyTypeName: name,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: _kIconBg,
                    child: Icon(
                      isEmergency
                          ? _getEmergencyIcon(name)
                          : _getServiceIcon(name),
                      color: _kPrimaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _kTextDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- UI Helpers ---
  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: _kTextDark,
        ),
      ),
      TextButton(
        onPressed: onSeeAll,
        child: const Text("View All", style: TextStyle(color: _kPrimaryBlue)),
      ),
    ],
  );

  Widget _buildAppBarAction(IconData icon) => Container(
    margin: const EdgeInsets.only(left: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      shape: BoxShape.circle,
    ),
    child: IconButton(
      icon: Icon(icon, color: Colors.white, size: 20),
      onPressed: () {},
    ),
  );

  Widget _buildBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
    ),
  );

  Widget _buildInfoItem(IconData icon, String text) => Row(
    children: [
      Icon(icon, color: Colors.white70, size: 14),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
    ],
  );

  Widget _buildEmptyState(String msg) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: _kSurfaceWhite,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        Icon(Icons.query_stats, color: _kTextMuted.withOpacity(0.3), size: 40),
        const SizedBox(height: 12),
        Text(msg, style: const TextStyle(color: _kTextMuted, fontSize: 13)),
      ],
    ),
  );

  IconData _getEmergencyIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains("fire")) return Icons.local_fire_department_rounded;
    if (n.contains("police")) return Icons.shield_rounded;
    if (n.contains("medical")) return Icons.health_and_safety_rounded;
    return Icons.grid_view_rounded;
  }

  IconData _getServiceIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains("water")) return Icons.water_drop_rounded;
    if (n.contains("electric")) return Icons.bolt_rounded;
    if (n.contains("waste")) return Icons.delete_outline_rounded;
    return Icons.hub_outlined;
  }
}

// --- INTEGRATED SERVICE CLASS ---
class ServiceTypeService {
  static const String baseUrl = "http://localhost:5000/api/serviceType";

  static Future<List<ServiceType>> getAllServiceTypes() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List list = (data is List) ? data : (data["serviceTypes"] ?? []);
        return list.map((e) => ServiceType.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("ServiceType Error: $e");
      return [];
    }
  }
}
