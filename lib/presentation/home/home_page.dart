import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_app/l10n/app_localizations.dart';
import 'package:first_app/main.dart';
import '../auth/login_page.dart';

// ─── Design Tokens (mirrored from DashboardContent) ──────────────────────────
class _T {
  static const primary    = Color(0xFF1A3BAA);
  static const primaryMid = Color(0xFF2252CC);
  static const accent     = Color(0xFF4B83F0);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {

  String _currentLang     = 'en';
  bool   _isSwitchingLang = false;

  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..forward();
  late final AnimationController _pulseCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat(reverse: true);
  late final AnimationController _slideCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
        ..forward();

  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  late final Animation<double> _pulseAnim =
      Tween<double>(begin: 0.88, end: 1.0).animate(
          CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  late final Animation<Offset> _slideAnim =
      Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _loadSavedLang();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ── Load persisted language on startup ─────────────────────────────────────
  Future<void> _loadSavedLang() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language_code') ?? 'en';
    if (mounted) setState(() => _currentLang = saved);
  }

  // ── Language switcher — identical logic to DashboardContent ───────────────
  Future<void> _switchLanguage(String langCode) async {
    if (_isSwitchingLang || langCode == _currentLang) return;

    // 1. Persist
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', langCode);

    if (!mounted) return;

    // 2. Update app locale (rebuilds l10n strings across all pages)
    MyApp.of(context)?.setLocale(Locale(langCode));

    // 3. Update local state + show spinner
    setState(() {
      _currentLang     = langCode;
      _isSwitchingLang = true;
    });

    // 4. Brief delay so spinner is visible, then clear
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _isSwitchingLang = false);
  }

  // ── Language toggle widget — identical look to DashboardContent ────────────
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
                isAmharic ? 'EN' : 'አማ', // shows what you WILL switch TO
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [

            // ── Layer 1: Background image ──────────────────────────────────
            Image.asset(
              "assets/images/bg.jpg",
              fit: BoxFit.cover,
            ),

            // ── Layer 2: Blue-tinted gradient overlay ──────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0D2580).withOpacity(0.72),
                    _T.primary.withOpacity(0.68),
                    _T.primaryMid.withOpacity(0.60),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // ── Layer 3: Bottom dark scrim ─────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.55),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),

            // ── Layer 4: Decorative blobs ──────────────────────────────────
            Positioned(top: -90,    left: -70,  child: _blob(300, Colors.white, 0.04)),
            Positioned(bottom: -110, right: -70, child: _blob(340, Colors.white, 0.05)),
            Positioned(top: 60,    right: -40,  child: _blob(160, Colors.white, 0.05)),
            Positioned(top: 180,   left: -30,   child: _blob(120, _T.accent,    0.10)),

            // ── Layer 5: Content ───────────────────────────────────────────
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        // ── Top bar: lang toggle flush to top-right ────────
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _buildLangToggle(),
                          ),
                        ),

                        const Spacer(flex: 2),

                        // ── Pulsing logo rings ─────────────────────────────
                        ScaleTransition(
                          scale: _pulseAnim,
                          child: Stack(alignment: Alignment.center, children: [
                            Container(
                              width: 130, height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.10),
                                    width: 2),
                              ),
                            ),
                            Container(
                              width: 105, height: 105,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.07),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.20),
                                    width: 1.5),
                              ),
                            ),
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 28,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Image.asset(
                                    'assets/images/logo.webp',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                        Icons.hub_rounded,
                                        color: _T.primary, size: 38),
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ),

                        const SizedBox(height: 34),

                        // ── App name ──────────────────────────────────────
                        Text(
                          l10n.appTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // ── Tagline pill ──────────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.22), width: 1),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.location_on_rounded,
                                color: Colors.white.withOpacity(0.8), size: 13),
                            const SizedBox(width: 5),
                            Text(
                              l10n.tagline,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.88),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ]),
                        ),

                        const SizedBox(height: 26),

                        // ── Description ───────────────────────────────────
                        Text(
                          l10n.homeDescription,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 14.5,
                            height: 1.65,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const Spacer(flex: 3),

                        // ── Feature pills ─────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _featurePill(Icons.crisis_alert_rounded,
                                l10n.homeFeatureEmergency),
                            const SizedBox(width: 10),
                            _featurePill(Icons.account_balance_rounded,
                                l10n.homeFeatureServices),
                            const SizedBox(width: 10),
                            _featurePill(Icons.cell_tower_rounded,
                                l10n.homeFeatureLiveReports),
                          ],
                        ),

                        const SizedBox(height: 36),

                        // ── Primary CTA ───────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _T.primary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 17),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginPage()),
                            ),
                            child: Text(
                              l10n.homeLetsStart,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Ghost sign-in link ────────────────────────────
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginPage()),
                          ),
                          child: Text(
                            l10n.homeAlreadyHaveAccount,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.60),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Feature pill ──────────────────────────────────────────────────────────
  Widget _featurePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.20), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 13),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }

  // ── Blob ──────────────────────────────────────────────────────────────────
  Widget _blob(double size, Color color, double opacity) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: color.withOpacity(opacity)));
}