import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_app/l10n/app_localizations.dart';
import 'package:first_app/main.dart';

// ─── Design Tokens (identical to dashboard) ───────────────────────────────────
class _T {
  static const primary    = Color(0xFF1A3BAA);
  static const primaryMid = Color(0xFF2252CC);
  static const accent     = Color(0xFF4B83F0);
  static const accentSoft = Color(0xFFD6E4FF);
  static const surface    = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF2F6FF);
  static const textDark   = Color(0xFF0C1A45);
  static const textMid    = Color(0xFF5569A0);
  static const divider    = Color(0xFFE5ECFF);
  static const green      = Color(0xFF0DB87A);
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {

  String _currentLang    = 'en';
  bool   _isSwitchingLang = false;

  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language_code') ?? 'en';
    if (mounted) {
      setState(() => _currentLang = saved);
      _fadeCtrl.forward();
    }
  }

  // ── Language switcher — exact same logic as dashboard ─────────────────────
  Future<void> _switchLanguage(String langCode) async {
    if (_isSwitchingLang || langCode == _currentLang) return;

    // 1. Persist
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', langCode);

    if (!mounted) return;

    // 2. Rebuild app locale
    MyApp.of(context)?.setLocale(Locale(langCode));

    // 3. Update local state
    setState(() {
      _currentLang     = langCode;
      _isSwitchingLang = true;
    });

    // Simulate brief switching state (no extra fetches needed on settings page)
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) setState(() => _isSwitchingLang = false);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('LANGUAGE', Icons.translate_rounded),
                      const SizedBox(height: 14),
                      _languageCard(),
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

  // ── Header — same gradient + blob pattern as dashboard ────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2580), _T.primary, _T.primaryMid],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(children: [
        Positioned(top: -40,  right: -25, child: _blob(140, Colors.white, 0.055)),
        Positioned(top: 14,   right: 85,  child: _blob(55,  Colors.white, 0.045)),
        Positioned(bottom: -18, left: -28, child: _blob(105, _T.accent,   0.14)),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Page title
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.navSettings,
                      style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.locationCity,
                      style: TextStyle(
                          color:      Colors.white.withOpacity(0.55),
                          fontSize:   12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const Spacer(),
                // Lang toggle — identical widget to dashboard
                _buildLangToggle(),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ── Language toggle — copied 1-to-1 from dashboard ────────────────────────
  Widget _buildLangToggle() {
    final isAmharic = _currentLang == 'am';
    return GestureDetector(
      onTap: _isSwitchingLang
          ? null
          : () => _switchLanguage(isAmharic ? 'en' : 'am'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _isSwitchingLang
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: _isSwitchingLang
            ? const SizedBox(
                width: 22, height: 14,
                child: Center(
                  child: SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white)),
                  ),
                ),
              )
            : Text(
                isAmharic ? 'EN' : 'አማ',
                style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3),
              ),
      ),
    );
  }

  // ── Language selection card ────────────────────────────────────────────────
  Widget _languageCard() {
    return Container(
      decoration: BoxDecoration(
        color:        _T.surface,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: _T.divider, width: 1),
        boxShadow: [
          BoxShadow(
              color:      _T.primary.withOpacity(0.06),
              blurRadius: 14,
              offset:     const Offset(0, 4)),
        ],
      ),
      child: Column(children: [
        _languageOption(
          title:    'English',
          subtitle: 'Default Language',
          value:    'en',
          icon:     Icons.language_rounded,
          flag:     '🇬🇧',
        ),
        Divider(height: 1, color: _T.divider),
        _languageOption(
          title:    'አማርኛ',
          subtitle: 'Amharic',
          value:    'am',
          icon:     Icons.translate_rounded,
          flag:     '🇪🇹',
        ),
      ]),
    );
  }

  Widget _languageOption({
    required String   title,
    required String   subtitle,
    required String   value,
    required IconData icon,
    required String   flag,
  }) {
    final selected = _currentLang == value;
    return GestureDetector(
      onTap: () => _switchLanguage(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? _T.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          // Flag + icon container
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color:        selected ? _T.primary : _T.bg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(flag, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize:   15,
                        fontWeight: FontWeight.w700,
                        color:      selected ? _T.primary : _T.textDark)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: _T.textMid)),
              ],
            ),
          ),
          // Check indicator
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: selected
                ? Container(
                    key: const ValueKey('check'),
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                        color:  _T.primary,
                        shape:  BoxShape.circle),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14),
                  )
                : Container(
                    key:   const ValueKey('empty'),
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _T.divider, width: 2),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }

  // ── Section label — same style as dashboard ───────────────────────────────
  Widget _sectionLabel(String title, IconData icon) {
    return Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
            color: _T.accentSoft, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: _T.primary, size: 16),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: const TextStyle(
              fontSize:   15,
              fontWeight: FontWeight.w800,
              color:      _T.textDark,
              letterSpacing: -0.2)),
    ]);
  }

  // ── Blob decorator — same as dashboard ────────────────────────────────────
  Widget _blob(double size, Color color, double opacity) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(opacity)));
}