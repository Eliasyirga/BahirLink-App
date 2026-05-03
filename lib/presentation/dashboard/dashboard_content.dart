import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:first_app/services/user_service.dart';
import 'package:first_app/services/case_service.dart';
import 'package:first_app/services/emergency_type_service.dart';
import 'package:first_app/model/emergency_type.dart';
import 'package:first_app/model/service_type.dart';
import 'package:first_app/presentation/categories/user_category_selection_page.dart';
import 'package:first_app/presentation/categories/user_service_category_selection_page.dart';
import 'package:first_app/presentation/cases/case_detail_page.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
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
  static const orange     = Color(0xFFF59E0B);
  static const red        = Color(0xFFEF4444);
}

// ─── Widget ───────────────────────────────────────────────────────────────────
class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});
  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent>
    with TickerProviderStateMixin {

  String _fullName = "User";
  bool _isLoading = true;
  List<dynamic> _cases = [];
  List<EmergencyType> _emergencyTypes = [];
  List<ServiceType> _serviceTypes = [];

  final PageController _caseCtrl = PageController(viewportFraction: 0.88);
  Timer? _sliderTimer;
  int _currentIdx = 0;

  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final AnimationController _pulseCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat(reverse: true);
  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  late final Animation<double> _pulseAnim =
      Tween<double>(begin: 0.88, end: 1.0).animate(
          CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _caseCtrl.dispose();
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchUser(),
        _fetchEmergencyTypes(),
        _fetchServiceTypes(),
        _fetchCases(),
      ]);
      _startAutoLoop();
      _fadeCtrl.forward();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUser() async {
    final res = await UserService.getProfile();
    if (res != null && mounted) {
      final u = res['user'] ?? res;
      setState(() =>
          _fullName = "${u["firstName"] ?? ""} ${u["lastName"] ?? ""}".trim());
    }
  }

  Future<void> _fetchEmergencyTypes() async =>
      _emergencyTypes = await EmergencyTypeService.fetchEmergencyTypes();

  Future<void> _fetchCases() async {
    final fetched = await CaseService.getAllCases() ?? [];
    if (mounted) {
      setState(() {
        _cases = fetched.where((c) {
          final s = (c['status'] ?? '').toString().toLowerCase();
          return s != 'rejected' && s != 'resolved';
        }).toList();
      });
    }
  }

  Future<void> _fetchServiceTypes() async {
    final res = await http.get(Uri.parse("http://localhost:5000/api/serviceType"));
    if (res.statusCode == 200 && mounted) {
      final data = jsonDecode(res.body);
      final List list = (data is List) ? data : (data["serviceTypes"] ?? []);
      setState(() =>
          _serviceTypes = list.map((e) => ServiceType.fromJson(e)).toList());
    }
  }

  void _startAutoLoop() {
    _sliderTimer?.cancel();
    if (_cases.isEmpty) return;
    _sliderTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_caseCtrl.hasClients) {
        _currentIdx = (_currentIdx + 1) % _cases.length;
        _caseCtrl.animateToPage(_currentIdx,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubic);
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSplash();
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
              SliverToBoxAdapter(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Splash ───────────────────────────────────────────────────────────────
  Widget _buildSplash() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D2580), _T.primary, _T.primaryMid],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(children: [
          Positioned(top: -90, left: -70, child: _blob(300, Colors.white, 0.04)),
          Positioned(bottom: -110, right: -70, child: _blob(340, Colors.white, 0.05)),
          Positioned(top: 60, right: -40, child: _blob(160, Colors.white, 0.06)),
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ScaleTransition(
                scale: _pulseAnim,
                child: Stack(alignment: Alignment.center, children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.12), width: 2),
                    ),
                  ),
                  Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.07),
                      border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.5),
                    ),
                  ),
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.22),
                          blurRadius: 28, offset: const Offset(0, 10))],
                    ),
                    child: ClipOval(child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Image.asset('assets/images/logo.webp', fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.hub_rounded, color: _T.primary, size: 36)),
                    )),
                  ),
                ]),
              ),
              const SizedBox(height: 30),
              const Text("BahirLink",
                  style: TextStyle(color: Colors.white, fontSize: 28,
                      fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              const SizedBox(height: 5),
              Text("Your city. Connected.",
                  style: TextStyle(color: Colors.white.withOpacity(0.55),
                      fontSize: 13, letterSpacing: 0.4)),
              const SizedBox(height: 52),
              _LoadingDots(),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0D2580), _T.primary, _T.primaryMid],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Stack(children: [
        Positioned(top: -40, right: -25, child: _blob(140, Colors.white, 0.055)),
        Positioned(top: 14, right: 85, child: _blob(55, Colors.white, 0.045)),
        Positioned(bottom: -18, left: -28, child: _blob(105, _T.accent, 0.14)),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                // Logo pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
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
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.3)),
                  ]),
                ),
                const Spacer(),
                // Bell
                Stack(clipBehavior: Clip.none, children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 19),
                  ),
                  Positioned(
                    top: 7, right: 7,
                    child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4B4B), shape: BoxShape.circle,
                        border: Border.all(color: _T.primary, width: 1.5),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(width: 10),
                // Avatar
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.45), width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundImage: AssetImage('assets/images/avatar.jpg'),
                    backgroundColor: Colors.white24,
                  ),
                ),
              ]),
              const SizedBox(height: 22),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Good morning 👋",
                        style: TextStyle(color: Colors.white.withOpacity(0.62),
                            fontSize: 12.5, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Text(_fullName.isNotEmpty ? _fullName : "Welcome back",
                        style: const TextStyle(color: Colors.white, fontSize: 22,
                            fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.1)),
                  ]),
                ),
                // Location pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.11),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
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
      ]),
    );
  }

  Widget _blob(double size, Color color, double opacity) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: color.withOpacity(opacity)));

  // ── Body ─────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        if (_cases.isNotEmpty) ...[
          _sectionLabel("Live Reports", Icons.cell_tower_rounded,
              badge: "${_cases.length} Active", badgeColor: _T.green),
          const SizedBox(height: 12),
          _buildCaseSlider(),
          const SizedBox(height: 10),
          _buildDots(),
        ],
        const SizedBox(height: 26),
        _sectionLabel("Emergency Assist", Icons.crisis_alert_rounded),
        const SizedBox(height: 12),
        _buildGrid(_emergencyTypes, true),
        const SizedBox(height: 26),
        _sectionLabel("Public Services", Icons.account_balance_rounded),
        const SizedBox(height: 12),
        _buildGrid(_serviceTypes, false),
        const SizedBox(height: 100),
      ],
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String title, IconData icon,
      {String? badge, Color? badgeColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
              color: _T.accentSoft, borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: _T.primary, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                color: _T.textDark, letterSpacing: -0.2)),
        const Spacer(),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (badgeColor ?? _T.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6,
                  decoration: BoxDecoration(
                      color: badgeColor ?? _T.primary, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(badge,
                  style: TextStyle(color: badgeColor ?? _T.primary,
                      fontSize: 10, fontWeight: FontWeight.w700)),
            ]),
          )
        else
          Text("See all",
              style: TextStyle(color: _T.accent, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ── Case Slider ───────────────────────────────────────────────────────────
  Widget _buildCaseSlider() {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _caseCtrl,
        itemCount: _cases.length,
        onPageChanged: (i) => setState(() => _currentIdx = i),
        itemBuilder: (context, index) {
          final c = _cases[index];
          final status = (c['status'] ?? '').toString().toLowerCase();
          Color sColor;
          String sLabel;
          if (status == 'pending') {
            sColor = _T.orange; sLabel = 'Pending';
          } else if (status == 'in_progress') {
            sColor = _T.accent; sLabel = 'In Progress';
          } else {
            sColor = _T.green; sLabel = status.toUpperCase();
          }

          return GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => CaseDetailPage(caseData: c))),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(
                    color: _T.primary.withOpacity(0.18),
                    blurRadius: 18, offset: const Offset(0, 6))],
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
                        color: _T.primary,
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.white24, size: 40)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.18),
                          Colors.black.withOpacity(0.78),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        _glassBadge(c['caseType']?['name'] ?? "Report", Icons.report_rounded),
                        const Spacer(),
                        _colorBadge(sLabel, sColor),
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
                          child: Text(c['location'] ?? "Bahir Dar",
                              style: const TextStyle(color: Colors.white60, fontSize: 10),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                              color: _T.green, borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [
                            const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 11),
                            const SizedBox(width: 4),
                            Text("${c['reward'] ?? '0'} ETB",
                                style: const TextStyle(color: Colors.white,
                                    fontSize: 10, fontWeight: FontWeight.w800)),
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

  Widget _buildDots() {
    if (_cases.length <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_cases.length, (i) {
        final active = i == _currentIdx;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 6, height: 6,
          decoration: BoxDecoration(
              color: active ? _T.primary : _T.accentSoft,
              borderRadius: BorderRadius.circular(3)),
        );
      }),
    );
  }

  // ── Grid — ALL cards unified blue gradient ────────────────────────────────
  Widget _buildGrid(List<dynamic> items, bool isEmergency) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.88,
        ),
        itemCount: items.length,
        itemBuilder: (context, idx) {
          final item = items[idx];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => isEmergency
                    ? UserCategorySelectionPage(
                        emergencyTypeId: item.id.toString(),
                        emergencyTypeName: item.name)
                    : UserServiceCategorySelectionPage(
                        serviceTypeId: item.id.toString(),
                        serviceTypeName: item.name),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A3BAA), Color(0xFF2D5BE3)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _T.primary.withOpacity(0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEmergency ? _emergencyIcon(idx) : _serviceIcon(idx),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      item.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _emergencyIcon(int i) => const [
        Icons.local_hospital_rounded,
        Icons.local_fire_department_rounded,
        Icons.local_police_rounded,
        Icons.flood_rounded,
        Icons.electric_bolt_rounded,
        Icons.car_crash_rounded,
      ][i % 6];

  IconData _serviceIcon(int i) => const [
        Icons.account_balance_rounded,
        Icons.school_rounded,
        Icons.water_drop_rounded,
        Icons.electrical_services_rounded,
        Icons.nature_people_rounded,
        Icons.local_post_office_rounded,
      ][i % 6];

  // ── Badges ────────────────────────────────────────────────────────────────
  Widget _glassBadge(String txt, IconData icon) {
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
            Text(txt,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }

  Widget _colorBadge(String txt, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Text(txt,
            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
      );
}

// ─── Animated Loading Dots ────────────────────────────────────────────────────
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with TickerProviderStateMixin {
  final List<AnimationController> _ctls = [];
  final List<Animation<double>> _anims = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final ctrl = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 600))
        ..repeat(reverse: true);
      _ctls.add(ctrl);
      _anims.add(Tween<double>(begin: 0.25, end: 1.0).animate(
          CurvedAnimation(parent: ctrl, curve: Curves.easeInOut)));
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => AnimatedBuilder(
        animation: _anims[i],
        builder: (_, __) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8, height: 8,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(_anims[i].value)),
        ),
      )),
    );
  }
}