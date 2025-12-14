import 'package:flutter/material.dart';
import 'package:first_app/services/user_service.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  String fullName = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final user = await UserService.getProfile();
      if (user != null) {
        setState(() {
          fullName = user['name'] ?? "";
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching user: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Top Gradient Header
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black26.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
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
                // Welcome Text
                isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Welcome, $fullName!",
                        style: const TextStyle(
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

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: Report Emergencies
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
                  _buildGridSection([
                    _buildBoxItem(
                      Icons.local_fire_department,
                      "Fire",
                      Colors.redAccent,
                    ),
                    _buildBoxItem(Icons.security, "Crime", Colors.deepPurple),
                    _buildBoxItem(
                      Icons.medical_services,
                      "Medical",
                      Colors.pinkAccent,
                    ),
                    _buildBoxItem(
                      Icons.water_damage,
                      "Flood",
                      Colors.blueAccent,
                    ),
                  ]),

                  const SizedBox(height: 25),

                  // Section: Access Services
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      "Access Services",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _buildGridSection([
                    _buildBoxItem(
                      Icons.local_hospital,
                      "Health Centers",
                      Colors.green,
                    ),
                    _buildBoxItem(
                      Icons.apartment_rounded,
                      "Municipal",
                      Colors.teal,
                    ),
                    _buildBoxItem(
                      Icons.lightbulb_outline,
                      "Electric Utilities",
                      Colors.orange,
                    ),
                    _buildBoxItem(
                      Icons.water_drop,
                      "Water Resources",
                      Colors.blue,
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildGridSection(List<Widget> items) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: items,
    );
  }

  static Widget _buildBoxItem(IconData icon, String title, Color color) {
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
    );
  }
}
