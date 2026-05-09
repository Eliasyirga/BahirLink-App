import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_app/l10n/app_localizations.dart';
import 'package:first_app/services/kebele_service.dart';
import 'package:first_app/services/emergency_type_service.dart';
import 'package:first_app/model/emergency_type.dart';
import 'package:first_app/services/case_service.dart';
import '../categories/category_selection_page.dart';
import '../cases/case_detail_page.dart';
import 'package:first_app/presentation/auth/signup_page.dart';
import 'package:first_app/main.dart';

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

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading       = true;
  bool _isSwitchingLang = false;

  List<dynamic>       _cases          = [];
  List<EmergencyType> _emergencyTypes = [];
  Map<String, String> _kebeleMap      = {};

  String _currentLang = 'en';

  final PageController _pageCtrl = PageController(viewportFraction: 0.88);
  Timer? _autoScroll;
  int _pageIdx = 0;

  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initLangAndLoad();
  }

  @override
  void dispose() {
    _autoScroll?.cancel();
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Init: read saved language, then load everything ────────────────────────
  Future<void> _initLangAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language_code') ?? 'en';
    if (mounted) setState(() => _currentLang = saved);
    await _loadData(lang: saved);
  }

  // ── Master load ────────────────────────────────────────────────────────────
  Future<void> _loadData({String? lang}) async {
    final useLang = lang ?? _currentLang;
    if (mounted) setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchKebeles(),
        _fetchEmergencyTypes(useLang),
        _fetchCases(useLang),
      ]);
      _startScroll();
      _fadeCtrl.forward();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Fetchers ───────────────────────────────────────────────────────────────
  Future<void> _fetchKebeles() async {
    try {
      final kebeleList = await KebeleService().getAllKebeles();
      if (mounted) {
        setState(() {
          _kebeleMap = {
            for (var k in kebeleList) k['id'].toString(): k['name'].toString()
          };
        });
      }
    } catch (e) {
      debugPrint("Guest kebele fetch error: $e");
    }
  }

  Future<void> _fetchEmergencyTypes(String lang) async {
    try {
      final types = await EmergencyTypeService.fetchEmergencyTypes(lang: lang);
      if (mounted) setState(() => _emergencyTypes = List<EmergencyType>.from(types));
    } catch (e) {
      debugPrint("Guest emergency types fetch error: $e");
      if (mounted) setState(() => _emergencyTypes = []);
    }
  }

  Future<void> _fetchCases(String lang) async {
    try {
      final fetched = await CaseService.getAllCases(lang: lang) ?? [];
      if (mounted) setState(() => _cases = List<dynamic>.from(fetched));
    } catch (e) {
      debugPrint("Guest case fetch error: $e");
      if (mounted) setState(() => _cases = []);
    }
  }

  void _startScroll() {
    _autoScroll?.cancel();
    if (_cases.isEmpty) return;
    _autoScroll = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_pageCtrl.hasClients && _cases.isNotEmpty) {
        _pageIdx = (_pageIdx + 1) % _cases.length;
        _pageCtrl.animateToPage(_pageIdx,
            duration: const Duration(milliseconds: 800), curve: Curves.easeInOutCubic);
      }
    });
  }

  // ── Language switcher — mirrors user dashboard exactly ─────────────────────
  Future<void> _switchLanguage(String langCode) async {
    if (_isSwitchingLang || langCode == _currentLang) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', langCode);

    if (!mounted) return;

    MyApp.of(context)?.setLocale(Locale(langCode));

    setState(() {
      _currentLang     = langCode;
      _isSwitchingLang = true;
    });

    try {
      await Future.wait([
        _fetchEmergencyTypes(langCode),
        _fetchCases(langCode),
      ]);
    } finally {
      if (mounted) setState(() => _isSwitchingLang = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
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

  // ── Header ────────────────────────────────────────────────────────────────
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
                  Text(l10n.appTitle,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                ]),
              ),
              const Spacer(),
              // Language toggle
              _buildLangToggle(),
              const SizedBox(width: 10),
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
                  Text(l10n.guestMode,
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
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l10n.goodMorning,
                      style: const TextStyle(color: Colors.white60, fontSize: 12.5, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(l10n.guestUser,
                      style: const TextStyle(color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.1)),
                ]),
              ),
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
                  Text(l10n.locationCity,
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

  // ── Language toggle — identical to user dashboard ──────────────────────────
  Widget _buildLangToggle() {
    final isAmharic = _currentLang == 'am';
    return GestureDetector(
      onTap: _isSwitchingLang ? null : () => _switchLanguage(isAmharic ? 'en' : 'am'),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  ),
                ),
              )
            : Text(
                isAmharic ? 'EN' : 'አማ',
                style: const TextStyle(
                    color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.w800, letterSpacing: 0.3),
              ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    // Snapshot local references — prevents any mid-build list mutation issues
    final safeCases = List<dynamic>.from(_cases);
    final safeTypes = List<EmergencyType>.from(_emergencyTypes);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      if (safeCases.isNotEmpty) ...[
        _SectionLabel(
          title: l10n.liveReports,
          icon: Icons.cell_tower_rounded,
          badge: l10n.activeBadge(safeCases.length.toString()),
          badgeColor: _C.green,
        ),
        const SizedBox(height: 12),
        _buildCaseSlider(safeCases),
        const SizedBox(height: 10),
        _buildDots(safeCases.length),
      ],
      const SizedBox(height: 26),
      _SectionLabel(title: l10n.emergencyAssist, icon: Icons.crisis_alert_rounded),
      const SizedBox(height: 12),
      _isSwitchingLang
          ? _buildGridShimmer(safeTypes.isNotEmpty ? safeTypes.length : 6)
          : _buildEmergencyGrid(safeTypes),
      const SizedBox(height: 32),
      _buildSignupCard(),
      const SizedBox(height: 100),
    ]);
  }

  // ── Shimmer placeholder during language re-fetch ───────────────────────────
  Widget _buildGridShimmer(int itemCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.88),
        itemCount: itemCount,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [
                _C.primary.withOpacity(0.45),
                _C.grad2.withOpacity(0.35),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  // ── Case Slider ───────────────────────────────────────────────────────────
  Widget _buildCaseSlider(List<dynamic> cases) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _pageCtrl,
        itemCount: cases.length,
        onPageChanged: (i) => setState(() => _pageIdx = i),
        itemBuilder: (context, i) {
          final c = cases[i] as Map<String, dynamic>? ?? {};
          final location = _kebeleMap[c['lastSeenLocationId']?.toString()] ??
              c['location'] as String? ?? l10n.locationCity;
          final status = (c['status'] as String? ?? '').toLowerCase();
          final Color sColor;
          final String sLabel;
          if (status == 'pending') {
            sColor = _C.orange;
            sLabel = l10n.statusPending;
          } else if (status == 'in_progress') {
            sColor = _C.accent;
            sLabel = l10n.statusInProgress;
          } else {
            sColor = _C.green;
            sLabel = status.toUpperCase();
          }

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
                        _GlassBadge(
                            label: (c['CaseType'] as Map?)?['name'] as String? ??
                                   (c['caseType'] as Map?)?['name'] as String? ??
                                   l10n.defaultCaseType,
                            icon: Icons.report_rounded),
                        const Spacer(),
                        _ColorBadge(label: sLabel, color: sColor),
                      ]),
                      const Spacer(),
                      Text(c['fullName'] as String? ?? l10n.incidentReported,
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
                            Text(l10n.rewardLabel(c['reward']?.toString() ?? '0'),
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

  // ── Emergency Grid ─────────────────────────────────────────────────────────
  Widget _buildEmergencyGrid(List<EmergencyType> types) {
    if (types.isEmpty) return const SizedBox.shrink();
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
                emergencyTypeId: type.id.toString(),
                emergencyTypeName: type.name,
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
                  child: Icon(_getIcon(type.name), color: Colors.white, size: 22),
                ),
                const SizedBox(height: 9),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(type.name,
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

  // ── Sign Up Card ───────────────────────────────────────────────────────────
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
            child: Text(l10n.guestFreeToJoin,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 16),
        Text(l10n.guestUnlockTitle,
            style: const TextStyle(color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.w900, letterSpacing: -0.4)),
        const SizedBox(height: 6),
        Text(l10n.guestUnlockSubtitle,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12.5, height: 1.5)),
        const SizedBox(height: 20),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _featurePill(Icons.report_rounded,               l10n.guestFeatureReport),
          _featurePill(Icons.track_changes_rounded,        l10n.guestFeatureTrack),
          _featurePill(Icons.monetization_on_rounded,      l10n.guestFeatureRewards),
          _featurePill(Icons.notifications_active_rounded, l10n.guestFeatureAlerts),
        ]),
        const SizedBox(height: 20),
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
              Text(l10n.guestSignInCta,
                  style: const TextStyle(color: _C.primary, fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: _C.primary, size: 16),
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
    if (n.contains("fire"))     return Icons.local_fire_department_rounded;
    if (n.contains("crime"))    return Icons.local_police_rounded;
    if (n.contains("medical"))  return Icons.local_hospital_rounded;
    if (n.contains("flood"))    return Icons.flood_rounded;
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
          Text(AppLocalizations.of(context)!.seeAll,
              style: const TextStyle(color: _C.accent, fontSize: 12, fontWeight: FontWeight.w600)),
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