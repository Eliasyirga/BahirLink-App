import 'package:flutter/material.dart';
import 'package:first_app/services/user_service.dart';
import '../auth/verify_screen.dart';
import 'edit_profile_page.dart';
import '../auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    final profile = await UserService.getProfile();
    if (mounted) {
      setState(() {
        _userData = profile;
        _isLoading = false;
      });
    }
  }

  void _updateProfile(Map<String, dynamic> updatedData) {
    setState(() => _userData = updatedData);
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return "-";
    try {
      return DateTime.parse(date).toIso8601String().substring(0, 10);
    } catch (_) {
      return "-";
    }
  }

  String formatGender(String? gender) {
    if (gender == null || gender.isEmpty) return "-";
    return gender[0].toUpperCase() + gender.substring(1);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await UserService.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : _userData == null
          ? const Center(child: Text("Failed to load profile"))
          : CustomScrollView(
              slivers: [
                // =========================
                // Profile Header
                // =========================
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue, Colors.lightBlueAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundImage: const AssetImage(
                              "assets/images/avatar.jpg",
                            ),
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "${_userData!["firstName"] ?? ""} ${_userData!["lastName"] ?? ""}"
                                .trim(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _userData!["email"] ?? "email@domain.com",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // =========================
                // Body
                // =========================
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Buttons: Edit / Logout
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final updatedData = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditProfilePage(userData: _userData!),
                                    ),
                                  );
                                  if (updatedData != null)
                                    _updateProfile(updatedData);
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text("Edit"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _logout,
                                icon: const Icon(Icons.logout),
                                label: const Text("Logout"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // Verify Account Button
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const VerifyScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.verified_user),
                                label: const Text("Verify Account"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // =========================
                        // Info Sections
                        // =========================
                        _buildInfoSection("Personal Info", [
                          _infoRow(
                            Icons.person,
                            "First Name",
                            _userData!["firstName"] ?? "-",
                          ),
                          _infoRow(
                            Icons.person_outline,
                            "Last Name",
                            _userData!["lastName"] ?? "-",
                          ),
                          _infoRow(
                            Icons.cake,
                            "Date of Birth",
                            formatDate(_userData!["dateOfBirth"]?.toString()),
                          ),
                          _infoRow(
                            Icons.transgender,
                            "Gender",
                            formatGender(_userData!["gender"]),
                          ),
                        ]),
                        _buildInfoSection("Contact Info", [
                          _infoRow(
                            Icons.email,
                            "Email",
                            _userData!["email"] ?? "-",
                          ),
                          _infoRow(
                            Icons.phone,
                            "Phone",
                            _userData!["phone"] ?? "-",
                          ),
                          _infoRow(
                            Icons.location_on,
                            "City",
                            _userData!["city"] ?? "-",
                          ),
                          _infoRow(
                            Icons.flag,
                            "Country",
                            _userData!["country"] ?? "-",
                          ),
                          _infoRow(
                            Icons.home,
                            "Address",
                            _userData!["address"] ?? "-",
                          ),
                        ]),
                        _buildInfoSection("Account Info", [
                          _infoRow(
                            Icons.badge,
                            "Account Type",
                            _userData!["role"] ?? "User",
                          ),
                          _infoRow(
                            Icons.calendar_month,
                            "Member Since",
                            formatDate(_userData!["createdAt"]?.toString()),
                          ),
                          _infoRow(Icons.verified, "Status", "Active"),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const Divider(height: 20, thickness: 1),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(value, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
