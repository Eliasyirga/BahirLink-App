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
import 'package:first_app/presentation/cases/case_detail_page.dart';

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
    } catch (_) {
      return [];
    }
  }
}

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});
  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  String _fullName = "User";
  bool _isLoading = true;
  List<dynamic> _cases = [];
  List<EmergencyType> _emergencyTypes = [];
  List<ServiceType> _serviceTypes = [];

  // FIX: Properly initialized PageController to prevent Null TypeError
  final PageController _pageController = PageController();

  // Design Tokens
  static const Color _kPrimary = Color(0xFF0F172A);
  static const Color _kElectricBlue = Color(0xFF2563EB);
  static const Color _kAccent = Color(0xFFEF4444);
  static const Color _kBg = Color(0xFFF8FAFC);
  static const Color _kText = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // FIX: Added dispose to clean up controller memory
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _kElectricBlue,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAstonishingHeader(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Active Reports"),
                    const SizedBox(height: 12),
                    _buildCaseSlider(),
                    const SizedBox(height: 24),
                    _buildLabel("Emergency Protocols"),
                    const SizedBox(height: 12),
                    _buildActionGrid(_emergencyTypes, isEmergency: true),
                    const SizedBox(height: 24),
                    _buildLabel("Service Network"),
                    const SizedBox(height: 12),
                    _buildActionGrid(_serviceTypes, isEmergency: false),
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

  Widget _buildAstonishingHeader() {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1E40AF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -10,
                child: Icon(
                  Icons.blur_on_rounded,
                  size: 180,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 48,
                            width: 48,
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo.webp',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.hub_rounded,
                                    color: Color(0xFF2563EB),
                                    size: 28,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "BahirLink",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 24,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                Text(
                                  "CONNECTING THE COMMUNITY",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/avatar.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Colors.white,
                                      alignment: Alignment.center,
                                      child: Text(
                                        _fullName.isNotEmpty
                                            ? _fullName[0].toUpperCase()
                                            : "U",
                                        style: const TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(
                          color: Colors.white.withOpacity(0.15),
                          thickness: 1,
                        ),
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          Flexible(
                            child: RichText(
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: const TextStyle(fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: "Welcome back, ",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _fullName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaseSlider() {
    if (_cases.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text("All quiet for now.")),
      );
    }
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _cases.length,
        itemBuilder: (context, index) {
          final c = _cases[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CaseDetailPage(caseData: c),
              ),
            ),
            child: Container(
              width: 260,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                image: DecorationImage(
                  image: NetworkImage(
                    c['mediaUrl'] != null
                        ? "http://localhost:5000${c['mediaUrl']}"
                        : "https://via.placeholder.com/150",
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildMiniChip(
                              "${c['reward'] ?? '0'} ETB",
                              _kElectricBlue,
                            ),
                            const SizedBox(width: 5),
                            _buildMiniChip(
                              (c['caseType']?['name'] ?? "Alert")
                                  .toString()
                                  .toUpperCase(),
                              _kAccent,
                            ),
                          ],
                        ),
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
                          c['Kebele']?['name'] ?? "Unknown Area",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionGrid(List<dynamic> items, {required bool isEmergency}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => isEmergency
                  ? UserCategorySelectionPage(
                      emergencyTypeId: item.id.toString(),
                      emergencyTypeName: item.name,
                    )
                  : UserServiceCategorySelectionPage(
                      serviceTypeId: item.id.toString(),
                      serviceTypeName: item.name,
                    ),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kElectricBlue.withOpacity(0.05)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        (isEmergency
                                ? const Color.fromARGB(255, 48, 86, 255)
                                : _kElectricBlue)
                            .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEmergency
                        ? _getEmergencyIcon(item.name)
                        : _getServiceIcon(item.name),
                    color: isEmergency
                        ? const Color.fromARGB(255, 48, 84, 245)
                        : _kElectricBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _kText,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w900,
      color: _kText,
      letterSpacing: -0.2,
    ),
  );

  Widget _buildMiniChip(String label, Color color) => Container(
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

  IconData _getEmergencyIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains("fire")) return Icons.local_fire_department_rounded;
    if (n.contains("police")) return Icons.shield_rounded;
    return Icons.warning_amber_rounded;
  }

  IconData _getServiceIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains("water")) return Icons.water_drop_rounded;
    if (n.contains("electric")) return Icons.bolt_rounded;
    return Icons.grid_view_rounded;
  }
}
