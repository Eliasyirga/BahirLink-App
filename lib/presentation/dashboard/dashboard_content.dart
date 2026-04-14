import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Required for DateFormat
import 'package:first_app/services/user_service.dart';
import 'package:first_app/services/case_service.dart';
import 'package:first_app/services/service_type_service.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  String fullName = "User";
  bool isLoading = true;
  List<dynamic> cases = [];
  List<dynamic> emergencyTypes = [];
  List<dynamic> serviceTypes = [];

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
      ]);
      await _fetchCases();
    } catch (e) {
      debugPrint("Init Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fetchUser() async {
    final response = await UserService.getProfile();
    if (response != null) {
      final userData = response['user'] ?? response;
      setState(() => fullName = userData["firstName"] ?? "User");
    }
  }

  Future<void> _fetchEmergencyTypes() async {
    final res = await http.get(
      Uri.parse("http://localhost:5000/api/emergencyType"),
    );
    if (res.statusCode == 200) {
      setState(
        () => emergencyTypes = jsonDecode(res.body)["emergencyTypes"] ?? [],
      );
    }
  }

  Future<void> _fetchServiceTypes() async {
    final data = await ServiceTypeService.getAllServiceTypes();
    setState(() => serviceTypes = data ?? []);
  }

  Future<void> _fetchCases() async {
    final data = await CaseService.getAllCases();
    setState(() => cases = data ?? []);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          _buildCompactHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Surveillance", "LIVE INTEL"),
                    const SizedBox(height: 16),
                    _buildCaseIntelSlider(),
                    const SizedBox(height: 32),
                    _buildSectionHeader("Deployment", "EMERGENCY PROTOCOLS"),
                    const SizedBox(height: 16),
                    _buildBentoEmergencyGrid(),
                    const SizedBox(height: 32),
                    _buildSectionHeader("Systems", "SERVICE NETWORK"),
                    const SizedBox(height: 16),
                    _buildServiceStripList(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blueAccent, Colors.blue],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: "BAHIR",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: 0.5,
                      ),
                    ),
                    TextSpan(
                      text: "LINK",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "Officer: $fullName",
                style: TextStyle(
                  color: Colors.blueGrey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          const CircleAvatar(
            backgroundColor: Color(0xFF1E293B),
            child: Icon(
              Icons.notifications_none_rounded,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseIntelSlider() {
    if (cases.isEmpty) return _buildEmptyState();

    return SizedBox(
      height: 195, // Increased height for the new metadata
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cases.length,
        clipBehavior: Clip.none,
        itemBuilder: (context, index) {
          final c = cases[index];
          final String imageUrl = c['mediaUrl'] != null
              ? "http://localhost:5000${c['mediaUrl']}"
              : "https://via.placeholder.com/400x200";

          // Format Date
          String formattedDate = "N/A";
          if (c['createdAt'] != null) {
            try {
              formattedDate = DateFormat(
                'MMM d, yyyy',
              ).format(DateTime.parse(c['createdAt']));
            } catch (_) {}
          }

          return Container(
            width: 300,
            margin: const EdgeInsets.only(right: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(imageUrl, fit: BoxFit.cover),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.9),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Reward Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withAlpha(230),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "REWARD: ${c['reward'] ?? '0'} ETB",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.radar_rounded,
                              color: Colors.blueAccent,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              c['caseType']?['name']?.toUpperCase() ?? "INTEL",
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c['fullName'] ?? "SECURE RECORD",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Last Seen & Kebele
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white70,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "Last seen: Kebele ${c['Kebele']?['name'] ?? 'BDR'}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Date
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: Colors.white54,
                              size: 10,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ],
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

  Widget _buildBentoEmergencyGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: emergencyTypes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (context, index) {
        final type = emergencyTypes[index];
        return InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            '/category-selection',
            arguments: type,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIcon(type['name']),
                    color: Colors.blueAccent,
                    size: 22,
                  ),
                ),
                const Spacer(),
                Text(
                  type['name']?.toUpperCase() ?? "",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceStripList() {
    return Column(
      children: serviceTypes
          .map(
            (s) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIcon(s['name']),
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                title: Text(
                  s['name'] ?? "",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFFCBD5E1),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSectionHeader(String title, String tag) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            tag,
            style: const TextStyle(
              color: Colors.blueAccent,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: Text(
          "NO RECENT INTEL",
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String? n) {
    n = n?.toLowerCase() ?? "";
    if (n.contains("fire")) return Icons.local_fire_department_rounded;
    if (n.contains("crime") || n.contains("police"))
      return Icons.policy_rounded;
    if (n.contains("medical")) return Icons.health_and_safety_rounded;
    if (n.contains("water")) return Icons.water_drop_rounded;
    return Icons.bubble_chart_rounded;
  }
}
