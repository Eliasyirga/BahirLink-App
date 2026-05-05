import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_app/l10n/app_localizations.dart';
import '../../main.dart'; // Ensure this points to your main.dart file

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  void _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString("language_code") ?? 'en';
    });
  }

  void _changeLanguage(String? langCode) async {
    if (langCode == null) return;
    
    // 1. Save to local storage for persistence
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("language_code", langCode);
    
    setState(() {
      _selectedLanguage = langCode;
    });

    // 2. Trigger global rebuild of the app with the new Locale
    // This talks to the method we added in main.dart
    if (mounted) {
      MyApp.of(context)?.setLocale(Locale(langCode));
    }
  }

  // --- Theme Colors ---
  Color get backgroundColor => const Color(0xFFF2F6FF);
  Color get cardColor => Colors.white;
  Color get textColor => const Color(0xFF0C1A45);
  Color get iconColor => const Color(0xFF1A3BAA);

  @override
  Widget build(BuildContext context) {
    // This allows us to use l10n.key instead of manual ternary strings
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: iconColor,
        foregroundColor: Colors.white,
        elevation: 0,
        // Using the localization key if available, otherwise fallback
        title: Text(
          _selectedLanguage == 'en' ? "Settings" : "መቼቶች",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 10),
          Text(
            _selectedLanguage == 'en' ? "Language Preference" : "የቋንቋ ምርጫ",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: iconColor.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildLanguageOption(
                  title: "English",
                  subtitle: "Default Language",
                  value: 'en',
                  icon: Icons.language,
                ),
                Divider(height: 1, color: iconColor.withOpacity(0.1)),
                _buildLanguageOption(
                  title: "አማርኛ",
                  subtitle: "Amharic",
                  value: 'am',
                  icon: Icons.translate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    return RadioListTile<String>(
      activeColor: iconColor,
      value: value,
      groupValue: _selectedLanguage,
      onChanged: _changeLanguage,
      secondary: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: textColor.withOpacity(0.6), 
          fontSize: 12,
        ),
      ),
    );
  }
}
