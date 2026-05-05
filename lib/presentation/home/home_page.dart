import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

            // ── Layer 2: Blue-tinted gradient overlay (dashboard palette) ──
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

            // ── Layer 3: Bottom dark scrim so content pops ─────────────────
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

            // ── Layer 4: Decorative blobs (same as dashboard) ──────────────
            Positioned(top: -90,  left: -70,  child: _blob(300, Colors.white, 0.04)),
            Positioned(bottom: -110, right: -70, child: _blob(340, Colors.white, 0.05)),
            Positioned(top: 60,  right: -40, child: _blob(160, Colors.white, 0.05)),
            Positioned(top: 180, left: -30,  child: _blob(120, _T.accent,    0.10)),

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
                        const Spacer(flex: 2),

                        // ── Pulsing logo rings (from dashboard splash) ─────
                        ScaleTransition(
                          scale: _pulseAnim,
                          child: Stack(alignment: Alignment.center, children: [
                            Container(
                              width: 130, height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.10), width: 2),
                              ),
                            ),
                            Container(
                              width: 105, height: 105,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.07),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.20), width: 1.5),
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
                        const Text(
                          "BahirLink",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // ── Location pill (from dashboard header) ─────────
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
                              "Your city. Connected.",
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
                          "Your trusted public service & emergency response app —"
                          " connecting Bahir Dar with reliable assistance.",
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
                            _featurePill(Icons.crisis_alert_rounded,    "Emergency"),
                            const SizedBox(width: 10),
                            _featurePill(Icons.account_balance_rounded, "Services"),
                            const SizedBox(width: 10),
                            _featurePill(Icons.cell_tower_rounded,      "Live Reports"),
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
                              padding: const EdgeInsets.symmetric(vertical: 17),
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
                            child: const Text(
                              "Let's Start",
                              style: TextStyle(
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
                            "Already have an account? Sign in",
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

  // ── Feature pill ─────────────────────────────────────────────────────────────
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
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  // ── Blob (identical to dashboard) ────────────────────────────────────────────
  Widget _blob(double size, Color color, double opacity) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: color.withOpacity(opacity)));
}
