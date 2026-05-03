import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:first_app/services/kebele_service.dart';
import 'package:first_app/services/case_service.dart';
import '../categories/category_selection_page.dart';
import '../cases/case_detail_page.dart';
import 'package:first_app/presentation/auth/signup_page.dart'; // SignUpPage

// ─── Design Tokens (identical to user dashboard) ──────────────────────────────
class _C {
  static const bg       = Color(0xFFF0F4FF);
  static const surface  = Color(0xFFFFFFFF);
  static const primary  = Color(0xFF1A3BAA);
  static const grad1    = Color(0xFF0D2580);
  static const grad2    = Color(0xFF2252CC);
  static const accent   = Color(0xFF4B83F0);
  static const accentBg = Color(0xFFD6E4FF);
  static const textDark = Color(0xFF0C1A45);
  static const textMid  = Color(0xFF5569A0);
  static const divider  = Color(0xFFE8EEFF);
  static const green    = Color(0xFF0DB87A);
  static const orange   = Color(0xFFF59E0B);
  static const red      = Color(0xFFEF4444);
}

// ─── Widget ───────────────────────────────────────────────────────────────────
class GuestDashboardContent extends StatefulWidget {
  const GuestDashboardContent({super.key});

  @override
  State<GuestDashboardContent> createState() => _GuestDashboardContentState();
}

class _GuestDashboardContentState extends State<GuestDashboardContent>
    with TickerProviderStateMixin {

  late Future<Map<String, dynamic>> _dashboardData;
  final PageController _pageCtrl = PageController(viewportFraction: 0.88);
  Timer? _autoScroll;
  int _pageIdx = 0;
  List<dynamic> _cases = [];

  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _dashboardData = _loadData();
  }

  @override
  void dispose() {
    _autoScroll?.cancel();
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _loadData() async {
    try {
      final kebeleList = await KebeleService().getAllKebeles();
      final Map<String, String> kebeleMap = {
        for (var k in kebeleList) k['id'].toString(): k['name'].toString()
      };

      final typeRes = await http.get(Uri.parse("http://localhost:5000/api/emergencyType"));
      final decodedTypes = jsonDecode(typeRes.body);
      final List<dynamic> types = (decodedTypes is Map)
          ? List<dynamic>.from(decodedTypes["data"] ?? [])
          : [];

      final cases = await CaseService.getAllCases() ?? [];
      _cases = cases;
      if (_cases.isNotEmpty) _startScroll();
      _fadeCtrl.forward();

      return {'kebeleMap': kebeleMap, 'types': types, 'cases': cases};
    } catch (e) {
      debugPrint("Guest dashboard error: $e");
      return {'kebeleMap': <String, String>{}, 'types': [], 'cases': []};
    }
  }

  void _startScroll() {
    _autoScroll?.cancel();
    _autoScroll = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_pageCtrl.hasClients) {
        _pageIdx = (_pageIdx + 1) % _cases.length;
        _pageCtrl.animateToPage(_pageIdx,
            duration: const Duration(milliseconds: 800), curve: Curves.easeInOutCubic);
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: FutureBuilder<Map<String, dynamic>>(
          future: _dashboardData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [_C.grad1, _C.primary, _C.grad2],
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              );
            }

            final data = snapshot.data!;
            final cases = data['cases'] as List<dynamic>;
            final types = data['types'] as List<dynamic>;
            final kebeleMap = data['kebeleMap'] as Map<String, String>;

            return FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildBody(cases, types, kebeleMap)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Header (same as user dashboard) ──────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [_C.grad1, _C.primary, _C.grad2],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Top bar
            Row(children: [
              // Logo pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(children: [
                  SizedBox(
                    width: 22, height: 22,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.asset('assets/images/logo.webp', fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.hub_rounded, color: Colors.white, size: 18)),
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Text("BahirLink",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                ]),
              ),
              const Spacer(),
              // Guest badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.lock_outline_rounded, color: Colors.white70, size: 12),
                  const SizedBox(width: 5),
                  Text("Guest Mode",
                      style: TextStyle(color: Colors.white.withOpacity(0.85),
                          fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(width: 10),
              // Guest avatar
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.35), width: 2),
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  child: const Icon(Icons.person_outline, color: Colors.white, size: 18),
                ),
              ),
            ]),

            const SizedBox(height: 22),

            // Greeting row
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Welcome 👋",
                      style: TextStyle(color: Colors.white60, fontSize: 12.5, fontWeight: FontWeight.w500)),
                  SizedBox(height: 3),
                  Text("Guest User",
                      style: TextStyle(color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.1)),
                ]),
              ),
              // Location pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.location_on_rounded, color: Colors.white.withOpacity(0.8), size: 12),
                  const SizedBox(width: 4),
                  Text("Bahir Dar",
                      style: TextStyle(color: Colors.white.withOpacity(0.85),
                          fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody(List<dynamic> cases, List<dynamic> types, Map<String, String> kebeleMap) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      if (cases.isNotEmpty) ...[
        _SectionLabel(title: "Live Reports", icon: Icons.cell_tower_rounded,
            badge: "${cases.length} Active", badgeColor: _C.green),
        const SizedBox(height: 12),
        _buildCaseSlider(cases, kebeleMap),
        const SizedBox(height: 10),
        _buildDots(cases.length),
      ],
      const SizedBox(height: 26),
      _SectionLabel(title: "Emergency Assist", icon: Icons.crisis_alert_rounded),
      const SizedBox(height: 12),
      _buildEmergencyGrid(types),
      const SizedBox(height: 32),
      _buildSignupCard(),
      const SizedBox(height: 100),
    ]);
  }

  // ── Case Slider ───────────────────────────────────────────────────────────
  Widget _buildCaseSlider(List<dynamic> cases, Map<String, String> kebeleMap) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _pageCtrl,
        itemCount: cases.length,
        onPageChanged: (i) => setState(() => _pageIdx = i),
        itemBuilder: (context, i) {
          final c = cases[i];
          final location = kebeleMap[c['lastSeenLocationId']?.toString()] ??
              c['location'] ?? "Bahir Dar";
          final status = (c['status'] ?? '').toLowerCase();
          final (sLabel, sColor) = switch (status) {
            'pending'     => ('Pending', _C.orange),
            'in_progress' => ('In Progress', _C.accent),
            _             => (status.toUpperCase(), _C.green),
          };

          return GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => CaseDetailPage(caseData: c))),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(
                    color: _C.primary.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 6))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(fit: StackFit.expand, children: [
                  Image.network(
                    c['mediaUrl'] != null
                        ? "http://localhost:5000${c['mediaUrl']}"
                        : "https://via.placeholder.com/400x200/1A3BAA/FFFFFF?text=Report",
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: _C.primary,
                        child: const Icon(Icons.image_not_supported, color: Colors.white24, size: 40)),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.18), Colors.black.withOpacity(0.78)],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        _GlassBadge(
                            label: c['CaseType']?['name'] ?? c['caseType']?['name'] ?? "Report",
                            icon: Icons.report_rounded),
                        const Spacer(),
                        _ColorBadge(label: sLabel, color: sColor),
                      ]),
                      const Spacer(),
                      Text(c['fullName'] ?? "Incident Reported",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800,
                              fontSize: 15, letterSpacing: -0.2),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.location_on_rounded, color: Colors.white60, size: 11),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(location,
                              style: const TextStyle(color: Colors.white60, fontSize: 10),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(color: _C.green, borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [
                            const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 11),
                            const SizedBox(width: 4),
                            Text("${c['reward'] ?? '0'} ETB",
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                          ]),
                        ),
                      ]),
                    ]),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDots(int count) {
    if (count <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == _pageIdx;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 6, height: 6,
          decoration: BoxDecoration(
            color: active ? _C.primary : _C.accentBg,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  // ── Emergency Grid (same unified blue style) ──────────────────────────────
  Widget _buildEmergencyGrid(List<dynamic> types) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.88),
        itemCount: types.length,
        itemBuilder: (context, idx) {
          final type = types[idx];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => CategorySelectionPage(
                emergencyTypeId: type["id"].toString(),
                emergencyTypeName: type["name"],
              ),
            )),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF1A3BAA), Color(0xFF2D5BE3)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: _C.primary.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 5))],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                  child: Icon(_getIcon(type["name"] ?? ""), color: Colors.white, size: 22),
                ),
                const SizedBox(height: 9),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(type["name"] ?? "",
                      textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: Colors.white, height: 1.3)),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ── Sign Up Card ──────────────────────────────────────────────────────────
  Widget _buildSignupCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [_C.grad1, _C.primary, _C.grad2],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
            color: _C.primary.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Icon + badge row
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.lock_open_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _C.green.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text("Free to Join",
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 16),
        const Text("Unlock Full Access",
            style: TextStyle(color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.w900, letterSpacing: -0.4)),
        const SizedBox(height: 6),
        Text("Report incidents, track cases, earn rewards and stay connected with your city.",
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12.5, height: 1.5)),
        const SizedBox(height: 20),
        // Feature pills
        Wrap(spacing: 8, runSpacing: 8, children: [
          _featurePill(Icons.report_rounded, "Report Cases"),
          _featurePill(Icons.track_changes_rounded, "Track Status"),
          _featurePill(Icons.monetization_on_rounded, "Earn Rewards"),
          _featurePill(Icons.notifications_active_rounded, "Get Alerts"),
        ]),
        const SizedBox(height: 20),
        // CTA Button — navigates to sign in
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SignUpPage())),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text("Sign In / Create Account",
                  style: TextStyle(color: _C.primary, fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: _C.primary, size: 16),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _featurePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 11),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  IconData _getIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains("fire"))    return Icons.local_fire_department_rounded;
    if (n.contains("crime"))   return Icons.local_police_rounded;
    if (n.contains("medical")) return Icons.local_hospital_rounded;
    if (n.contains("flood"))   return Icons.flood_rounded;
    if (n.contains("electric")) return Icons.electric_bolt_rounded;
    if (n.contains("accident")) return Icons.car_crash_rounded;
    return Icons.crisis_alert_rounded;
  }
}

// ─── Reusable: Section Label ──────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? badge;
  final Color? badgeColor;
  const _SectionLabel({required this.title, required this.icon, this.badge, this.badgeColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: _C.accentBg, borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: _C.primary, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                color: _C.textDark, letterSpacing: -0.2)),
        const Spacer(),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: (badgeColor ?? _C.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6,
                  decoration: BoxDecoration(color: badgeColor ?? _C.primary, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(badge!,
                  style: TextStyle(color: badgeColor ?? _C.primary, fontSize: 10, fontWeight: FontWeight.w700)),
            ]),
          )
        else
          const Text("See all",
              style: TextStyle(color: _C.accent, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─── Reusable: Glass Badge ────────────────────────────────────────────────────
class _GlassBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  const _GlassBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.28), width: 0.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 10),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}

// ─── Reusable: Color Badge ────────────────────────────────────────────────────
class _ColorBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _ColorBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }
}