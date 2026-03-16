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
  String fullName = "";
  bool isLoading = true;

  List<dynamic> emergencyTypes = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([_fetchUser(), _fetchEmergencyTypes()]);

    setState(() {
      isLoading = false;
    });
  }

  // ================= FETCH USER =================

  Future<void> _fetchUser() async {
    try {
      final user = await UserService.getProfile();

      if (user != null) {
        fullName = user["name"] ?? "";
      }
    } catch (e) {
      debugPrint("User fetch error: $e");
    }
  }

  // ================= FETCH EMERGENCY TYPES =================

  Future<void> _fetchEmergencyTypes() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:5000/api/emergencyType"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          emergencyTypes = data["emergencyTypes"];
        });
      }
    } catch (e) {
      debugPrint("Emergency type error: $e");
    }
  }

  // ================= ICON MAPPER =================

  IconData _getIcon(String name) {
    switch (name.toLowerCase()) {
      case "fire":
        return Icons.local_fire_department;

      case "crime":
        return Icons.security;

      case "medical":
        return Icons.medical_services;

      case "flood":
        return Icons.water_damage;

      default:
        return Icons.warning;
    }
  }

  // ================= COLOR MAPPER =================

  Color _getColor(String name) {
    switch (name.toLowerCase()) {
      case "fire":
        return Colors.redAccent;

      case "crime":
        return Colors.deepPurple;

      case "medical":
        return Colors.pinkAccent;

      case "flood":
        return Colors.blueAccent;

      default:
        return Colors.orange;
    }
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Report Emergencies",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  _buildEmergencyGrid(),

                  const SizedBox(height: 25),

                  const Text(
                    "Access Services",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  _buildServiceGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade400],
        ),

        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset("assets/images/logo.webp", height: 40),

              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),

                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.blue,
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            "Welcome, $fullName!",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            "Choose a service to get started",
            style: TextStyle(fontSize: 15, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // ================= EMERGENCY GRID =================

  Widget _buildEmergencyGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),

      itemCount: emergencyTypes.length,

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),

      itemBuilder: (context, index) {
        final type = emergencyTypes[index];

        final name = type["name"];
        final id = type["id"];

        return _buildEmergencyCard(name, id);
      },
    );
  }

  // ================= EMERGENCY CARD =================

  Widget _buildEmergencyCard(String title, String id) {
    final icon = _getIcon(title);
    final color = _getColor(title);

    return InkWell(
      borderRadius: BorderRadius.circular(20),

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserCategorySelectionPage(
              emergencyTypeId: id,
              emergencyTypeName: title,
            ),
          ),
        );
      },

      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),

          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),

            const SizedBox(height: 8),

            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SERVICE GRID =================

  Widget _buildServiceGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),

      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,

      children: [
        _buildServiceCard(Icons.local_hospital, "Health Centers", Colors.green),
        _buildServiceCard(Icons.apartment, "Municipal", Colors.teal),
        _buildServiceCard(Icons.lightbulb, "Electric Utilities", Colors.orange),
        _buildServiceCard(Icons.water_drop, "Water Resources", Colors.blue),
      ],
    );
  }

  // ================= SERVICE CARD =================

  Widget _buildServiceCard(IconData icon, String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),

          const SizedBox(height: 8),

          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
