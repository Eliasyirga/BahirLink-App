import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // -------------------- Load saved preferences --------------------
  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkMode = prefs.getBool("darkMode") ?? false;
      notificationsEnabled = prefs.getBool("notificationsEnabled") ?? true;
    });
  }

  // -------------------- Save dark mode --------------------
  void _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("darkMode", value);
    setState(() => darkMode = value);
  }

  // -------------------- Save notifications --------------------
  void _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("notificationsEnabled", value);
    setState(() => notificationsEnabled = value);
  }

  // -------------------- Dynamic Colors --------------------
  Color get backgroundColor => darkMode ? Colors.black : Colors.white;
  Color get cardColor => darkMode ? Colors.grey[850]! : Colors.white;
  Color get textColor => darkMode ? Colors.white : Colors.black87;
  Color get iconColor =>
      darkMode ? Colors.lightBlueAccent : Colors.blue.shade800;
  Color get switchActiveColor => Colors.blue.shade800;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: darkMode ? Colors.black : Colors.blue.shade800,
        elevation: 3,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 10),
          Text(
            "Preferences",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildSwitchCard(
            icon: Icons.notifications,
            title: "Enable Notifications",
            value: notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          _buildSwitchCard(
            icon: Icons.dark_mode,
            title: "Dark Mode",
            value: darkMode,
            onChanged: _toggleDarkMode,
          ),
          const SizedBox(height: 24),
          Text(
            "Account",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildCardTile(
            icon: Icons.person,
            title: "Profile",
            onTap: () {
              // TODO: Navigate to profile page
            },
          ),
          _buildCardTile(
            icon: Icons.logout,
            title: "Logout",
            onTap: () {
              // TODO: Implement logout
            },
          ),
        ],
      ),
    );
  }

  // -------------------- Switch Card --------------------
  Widget _buildSwitchCard({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      color: cardColor,
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: switchActiveColor,
      ),
    );
  }

  // -------------------- Regular Card --------------------
  Widget _buildCardTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      color: cardColor,
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: textColor),
        onTap: onTap,
      ),
    );
  }
}
