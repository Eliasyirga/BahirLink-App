import 'dart:async';
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

  final PageController _caseController = PageController(viewportFraction: 0.9);
  Timer? _sliderTimer;
  int _currentIdx = 0;

  // Premium Super App Palette
  static const Color _kPrimaryBlue = Color(0xFF1E40AF);
  static const Color _kAccentBlue = Color(0xFF3B82F6);
  static const Color _kBgSoft = Color(0xFFF8FAFC);
  static const Color _kTextDark = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _caseController.dispose();
    super.dispose();
  }

  void _startAutoLoop() {
    _sliderTimer?.cancel();
    if (_cases.isEmpty) return;
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_caseController.hasClients) {
        _currentIdx = (_currentIdx + 1) % _cases.length;
        _caseController.animateToPage(
          _currentIdx,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchUser(),
        _fetchEmergencyTypes(),
        _fetchServiceTypes(),
        _fetchCases(),
      ]);
      _startAutoLoop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUser() async {
    final res = await UserService.getProfile();
    if (res != null) {
      final u = res['user'] ?? res;
      setState(
        () =>
            _fullName = "${u["firstName"] ?? ""} ${u["lastName"] ?? ""}".trim(),
      );
    }
  }

  Future<void> _fetchEmergencyTypes() async =>
      _emergencyTypes = await EmergencyTypeService.fetchEmergencyTypes();
  Future<void> _fetchCases() async =>
      _cases = await CaseService.getAllCases() ?? [];
  Future<void> _fetchServiceTypes() async {
    final response = await http.get(
      Uri.parse("http://localhost:5000/api/serviceType"),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List list = (data is List) ? data : (data["serviceTypes"] ?? []);
      setState(
        () => _serviceTypes = list.map((e) => ServiceType.fromJson(e)).toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: _kPrimaryBlue,
            strokeWidth: 2,
          ),
        ),
      );

    return Scaffold(
      backgroundColor:
          _kBgSoft, // Use a very soft gray background to make the white cards pop
      appBar: _buildSuperAppHeader(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _sectionLabel("Live Reports"),
            _buildCaseSlider(),
            const SizedBox(height: 16),
            _sectionLabel("Emergency Assist"),
            _buildGrid(_emergencyTypes, true),
            const SizedBox(height: 16),
            _sectionLabel("Public Services"),
            _buildGrid(_serviceTypes, false),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSuperAppHeader() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 50,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/logo.webp',
              height: 26,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.hub_rounded, color: _kPrimaryBlue),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            "BahirLink",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: _kPrimaryBlue,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _fullName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _kTextDark,
                ),
              ),
              const Text(
                "Bahir Dar",
                style: TextStyle(fontSize: 8, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(width: 10),
          const CircleAvatar(
            radius: 14,
            backgroundImage: AssetImage('assets/images/avatar.jpg'),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.withOpacity(0.1), height: 1),
      ),
    );
  }

  Widget _buildCaseSlider() {
    if (_cases.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 155,
      child: PageView.builder(
        controller: _caseController,
        itemCount: _cases.length,
        itemBuilder: (context, index) {
          final c = _cases[index];
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
                          c['caseType']?['name'] ?? "Report",
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(List<dynamic> items, bool isEmergency) {
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
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => isEmergency
                    ? UserCategorySelectionPage(
                        emergencyTypeId: item.id.toString(),
                        emergencyTypeName: item.name,
                      )
                    : UserServiceCategorySelectionPage(
                        serviceTypeId: item.id.toString(),
                        serviceTypeName: item.name,
                      ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, // White background for the box
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _kPrimaryBlue.withOpacity(0.08),
              ), // Subtle blue border
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
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
                    color: _kPrimaryBlue.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEmergency
                        ? Icons.emergency_rounded
                        : Icons.account_balance_rounded,
                    color: _kPrimaryBlue, // Blue icon
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    item.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _kPrimaryBlue,
                    ), // Blue text
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
}
