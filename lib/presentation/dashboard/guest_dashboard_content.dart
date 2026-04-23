import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:first_app/services/kebele_service.dart';
import 'package:first_app/services/case_service.dart';
import '../categories/category_selection_page.dart';
import '../cases/case_detail_page.dart';
import '../auth/signup_page.dart';

class GuestDashboardContent extends StatefulWidget {
  const GuestDashboardContent({super.key});

  @override
  State<GuestDashboardContent> createState() => _GuestDashboardContentState();
}

class _GuestDashboardContentState extends State<GuestDashboardContent> {
  static const Color _kPrimaryBlue = Color(0xFF1E40AF);
  static const Color _kAccentBlue = Color(0xFF3B82F6);
  static const Color _kBgSoft = Color(0xFFF8FAFC);
  static const Color _kTextDark = Color(0xFF0F172A);

  late Future<Map<String, dynamic>> _dashboardData;
  final PageController _caseController = PageController(viewportFraction: 0.9);

  Timer? _sliderTimer;
  int _currentIdx = 0;
  List<dynamic> _fetchedCases = [];

  @override
  void initState() {
    super.initState();
    _dashboardData = _initDashboard();
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _caseController.dispose();
    super.dispose();
  }

  void _startAutoLoop() {
    _sliderTimer?.cancel();
    if (_fetchedCases.isEmpty) return;

    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_caseController.hasClients) {
        _currentIdx = (_currentIdx + 1) % _fetchedCases.length;
        _caseController.animateToPage(
          _currentIdx,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<Map<String, dynamic>> _initDashboard() async {
    try {
      final kebeleList = await KebeleService().getAllKebeles();
      final Map<String, String> kebeleMap = {};
      for (var k in kebeleList) {
        kebeleMap[k['id'].toString()] = k['name'].toString();
      }

      final typeRes = await http.get(
        Uri.parse("http://localhost:5000/api/emergencyType"),
      );
      final List<dynamic> types =
          jsonDecode(typeRes.body)["emergencyTypes"] ?? [];
      final cases = await CaseService.getAllCases() ?? [];

      _fetchedCases = cases;
      if (_fetchedCases.isNotEmpty) {
        _startAutoLoop();
      }

      return {'kebeles': kebeleMap, 'types': types, 'cases': cases};
    } catch (e) {
      return {'kebeles': <String, String>{}, 'types': [], 'cases': []};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgSoft,
      appBar: _buildSuperAppHeader(),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _kPrimaryBlue,
                strokeWidth: 2,
              ),
            );
          }

          final data =
              snapshot.data ?? {'kebeles': {}, 'types': [], 'cases': []};
          final List<dynamic> cases = data['cases'];
          final List<dynamic> types = data['types'];
          final Map<String, String> kebeleMap = data['kebeles'];

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _sectionLabel("Live Reports"),
                _buildCaseSlider(cases, kebeleMap),
                const SizedBox(height: 16),
                _sectionLabel("Emergency Assist"),
                _buildEmergencyGrid(types),
                const SizedBox(height: 20),
                _buildPremiumSignupCard(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildSuperAppHeader() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 55,
      title: Row(
        children: [
          // Using Logo Image instead of icon
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              'assets/images/logo.webp',
              height: 30, // Optimized height for slim header
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.hub_rounded, color: _kPrimaryBlue),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            "BahirLink",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: _kPrimaryBlue,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Guest Mode",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _kTextDark,
                ),
              ),
              Text(
                "Bahir Dar",
                style: TextStyle(fontSize: 8, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(width: 10),
          const CircleAvatar(
            radius: 15,
            backgroundColor: _kBgSoft,
            child: Icon(Icons.person_outline, size: 18, color: _kPrimaryBlue),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.withOpacity(0.1), height: 1),
      ),
    );
  }

  Widget _buildCaseSlider(List<dynamic> cases, Map<String, String> kebeleMap) {
    if (cases.isEmpty)
      return const SizedBox(
        height: 100,
        child: Center(child: Text("No current alerts")),
      );
    return SizedBox(
      height: 155,
      child: PageView.builder(
        controller: _caseController,
        onPageChanged: (index) => _currentIdx = index,
        itemCount: cases.length,
        itemBuilder: (context, index) {
          final c = cases[index];
          final kebeleName =
              kebeleMap[c['lastSeenLocationId']?.toString()] ??
              "Unknown Location";

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CaseDetailPage(caseData: c)),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(
                    c['mediaUrl'] != null
                        ? "http://localhost:5000${c['mediaUrl']}"
                        : "https://via.placeholder.com/400",
                  ),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _miniBadge(
                          c['CaseType']?['name'] ?? "Alert",
                          _kAccentBlue,
                        ),
                        const SizedBox(width: 6),
                        _miniBadge(
                          "${c['reward'] ?? '0'} ETB",
                          Colors.green.shade600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c['fullName'] ?? "Incident Reported",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                    ),
                    Text(
                      kebeleName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmergencyGrid(List<dynamic> types) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: types.length,
      itemBuilder: (context, index) {
        final type = types[index];
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
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kPrimaryBlue.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _kPrimaryBlue.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(type["name"]),
                    color: _kPrimaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  type["name"],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _kPrimaryBlue,
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPrimaryBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: Colors.orangeAccent, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Unlock Features",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Text(
                  "Sign up to start reporting services",
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _kPrimaryBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text("SIGN UP"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBadge(String txt, Color col) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: col,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      txt,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 8,
        fontWeight: FontWeight.w900,
      ),
    ),
  );

  Widget _sectionLabel(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: _kPrimaryBlue,
      ),
    ),
  );

  IconData _getIcon(String name) {
    name = name.toLowerCase();
    if (name.contains("fire")) return Icons.local_fire_department_rounded;
    if (name.contains("crime")) return Icons.shield_rounded;
    if (name.contains("medical")) return Icons.medical_services_rounded;
    return Icons.warning_rounded;
  }
}
