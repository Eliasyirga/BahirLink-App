import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Internal Services
import 'package:first_app/services/user_service.dart';
import 'package:first_app/services/case_service.dart';
import 'package:first_app/services/emergency_type_service.dart';

// Models & Pages
import 'package:first_app/model/emergency_type.dart';
import 'package:first_app/model/service_type.dart';
import 'package:first_app/presentation/categories/user_category_selection_page.dart';
import 'package:first_app/presentation/categories/user_service_category_selection_page.dart';
import 'package:first_app/presentation/cases/case_detail_page.dart'; // Ensure this exists

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
  List<ServiceType> _serviceTypes = [];

  // --- Design System ---
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
      // Parallel execution for high performance
      await Future.wait([
        _fetchUser(),
        _fetchEmergencyTypes(),
        _fetchServiceTypes(),
        _fetchCases(),
      ]);
    } catch (e) {
      debugPrint("Sync Error: $e");
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
    final data = await EmergencyTypeService.fetchEmergencyTypes();
    if (mounted) setState(() => _emergencyTypes = data);
  }

  Future<void> _fetchServiceTypes() async {
    final data = await ServiceTypeService.getAllServiceTypes();
    if (mounted) setState(() => _serviceTypes = data);
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
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
      expandedHeight: 140,
      pinned: true,
      backgroundColor: _kPrimaryBlue,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1D4ED8), _kPrimaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Hello, $_fullName 👋",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _cases.length,
        itemBuilder: (context, index) {
          final c = _cases[index];
          final String imageUrl = c['mediaUrl'] != null
              ? "http://localhost:5000${c['mediaUrl']}"
              : "https://via.placeholder.com/400";

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CaseDetailPage(caseData: c),
                ),
              );
            },
            child: Container(
              width: MediaQuery.of(context).size.width * 0.82,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        c['Kebele']?['name'] ?? "Area Unknown",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBentoGrid(List<dynamic> items, {required bool isEmergency}) {
    if (items.isEmpty) return _buildEmptyState("No data available.");

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final String name = item.name ?? "Unknown";
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
                  builder: (context) => isEmergency
                      ? UserCategorySelectionPage(
                          emergencyTypeId: id,
                          emergencyTypeName: name,
                        )
                      : UserServiceCategorySelectionPage(
                          serviceTypeId: id,
                          serviceTypeName: name,
                        ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: _kIconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEmergency
                          ? _getEmergencyIcon(name)
                          : _getServiceIcon(name),
                      color: _kPrimaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

  // --- Helper Methods ---
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
        child: const Text(
          "View All",
          style: TextStyle(color: _kPrimaryBlue, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );

  Widget _buildBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
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

  Widget _buildEmptyState(String msg) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: _kSurfaceWhite,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        Icon(
          Icons.info_outline_rounded,
          color: _kTextMuted.withOpacity(0.3),
          size: 44,
        ),
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
    return Icons.warning_amber_rounded;
  }

  IconData _getServiceIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains("water")) return Icons.water_drop_rounded;
    if (n.contains("electric")) return Icons.bolt_rounded;
    return Icons.settings_suggest_outlined;
  }
}

class ServiceTypeService {
  static const String baseUrl = "http://localhost:5000/api/serviceType";
  static Future<List<ServiceType>> getAllServiceTypes() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List list = (data is List) ? data : (data["serviceTypes"] ?? []);
        return list.map((e) => ServiceType.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
