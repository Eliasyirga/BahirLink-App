import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../categories/category_selection_page.dart';

class GuestDashboardContent extends StatefulWidget {
  const GuestDashboardContent({super.key});

  @override
  State<GuestDashboardContent> createState() => _GuestDashboardContentState();
}

class _GuestDashboardContentState extends State<GuestDashboardContent> {
  bool isLoading = true;
  List<dynamic> emergencyTypes = [];

  @override
  void initState() {
    super.initState();
    _loadEmergencyTypes();
  }

  Future<void> _loadEmergencyTypes() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:5000/api/emergencyType"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          emergencyTypes =
              data["emergencyTypes"]; // [{"id": "uuid", "name": "Crime"}, ...]
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading emergency types: $e");
      setState(() => isLoading = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return SafeArea(
      child: Column(
        children: [
          // ================= HEADER =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                const Text(
                  "Welcome, Guest!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Choose a service to get started",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),

          // ================= BODY =================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      "Report Emergencies",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _buildGridSection(context),
                  const SizedBox(height: 25),
                  const Center(
                    child: Text(
                      "Limited access. Sign up to access all services.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= GRID SECTION =================
  Widget _buildGridSection(BuildContext context) {
    return GridView.builder(
      itemCount: emergencyTypes.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final service = emergencyTypes[index];
        final title = service["name"];
        final id = service["id"]; // ✅ UUID
        return _buildBoxItem(
          context,
          _getIcon(title),
          title,
          _getColor(title),
          id,
        );
      },
    );
  }

  // ================= BOX ITEM =================
  Widget _buildBoxItem(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    String emergencyTypeId, // UUID
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        // Navigate to CategorySelectionPage with UUID and name
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategorySelectionPage(
              emergencyTypeId: emergencyTypeId, // ✅ UUID
              emergencyTypeName: title, // Display name only
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
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
