import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:first_app/services/user_service.dart';
import 'package:first_app/l10n/app_localizations.dart';
import '../auth/verify_screen.dart';
import 'edit_profile_page.dart';
import '../auth/login_page.dart';

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

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

  late final AnimationController _pulseCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
        ..repeat(reverse: true);
  late final Animation<double> _pulseAnim =
      Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    final profile = await UserService.getProfile();
    if (mounted) {
      setState(() {
        _userData = profile;
        _isLoading = false;
      });
      _fadeCtrl.forward();
    }
  }

  void _updateProfile(Map<String, dynamic> updatedData) =>
      setState(() => _userData = updatedData);

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return "—";
    try {
      return DateTime.parse(date).toIso8601String().substring(0, 10);
    } catch (_) {
      return "—";
    }
  }

  String formatGender(String? gender) {
    if (gender == null || gender.isEmpty) return "—";
    return gender[0].toUpperCase() + gender.substring(1);
  }

  String get _fullName =>
      "${_userData?["firstName"] ?? ""} ${_userData?["lastName"] ?? ""}".trim();

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _T.surface,
        title: Text(l10n.logoutConfirmTitle,
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: _T.textDark, fontSize: 17)),
        content: Text(l10n.logoutConfirmMessage,
            style: const TextStyle(color: _T.textMid, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel,
                style: const TextStyle(
                    color: _T.textMid, fontWeight: FontWeight.w600)),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: _T.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(l10n.logout,
                  style: const TextStyle(
                      color: _T.red,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await UserService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: _isLoading
            ? _buildSplash()
            : _userData == null
                ? _buildErrorState()
                : FadeTransition(
                    opacity: _fadeAnim,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader()),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            child: Column(children: [
                              const SizedBox(height: 24),
                              _buildActionButtons(),
                              const SizedBox(height: 24),
                              _buildSection(l10n.personalInfo, Icons.person_rounded, [
                                _infoRow(Icons.person_rounded, l10n.firstName,
                                    _userData!["firstName"] ?? "—"),
                                _infoRow(Icons.person_outline_rounded, l10n.lastName,
                                    _userData!["lastName"] ?? "—"),
                                _infoRow(Icons.cake_rounded, l10n.dateOfBirth,
                                    formatDate(_userData!["dateOfBirth"]?.toString())),
                                _infoRow(Icons.wc_rounded, l10n.gender,
                                    formatGender(_userData!["gender"])),
                              ]),
                              const SizedBox(height: 16),
                              _buildSection(l10n.contactInfo, Icons.contact_mail_rounded, [
                                _infoRow(Icons.email_rounded, l10n.email,
                                    _userData!["email"] ?? "—"),
                                _infoRow(Icons.phone_rounded, l10n.phone,
                                    _userData!["phone"] ?? "—"),
                                _infoRow(Icons.location_city_rounded, l10n.city,
                                    _userData!["city"] ?? "—"),
                                _infoRow(Icons.flag_rounded, l10n.country,
                                    _userData!["country"] ?? "—"),
                                _infoRow(Icons.home_rounded, l10n.address,
                                    _userData!["address"] ?? "—"),
                              ]),
                              const SizedBox(height: 16),
                              _buildSection(l10n.accountInfo, Icons.shield_rounded, [
                                _infoRow(Icons.badge_rounded, l10n.accountType,
                                    _userData!["role"] ?? "User"),
                                _infoRow(Icons.calendar_month_rounded, l10n.memberSince,
                                    formatDate(_userData!["createdAt"]?.toString())),
                                _infoRow(Icons.verified_rounded, l10n.statusActive, l10n.statusActive,
                                    valueColor: _T.green),
                              ]),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  // ── Splash ─────────────────────────────────────────────────────────────────
  Widget _buildSplash() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2580), _T.primary, _T.primaryMid],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 34),
            ),
          ),
          const SizedBox(height: 20),
          const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
        ]),
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
              color: _T.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(22)),
          child: const Icon(Icons.error_outline_rounded, color: _T.red, size: 32),
        ),
        const SizedBox(height: 16),
        Text(l10n.failedToLoadProfile,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _T.textDark)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _fetchProfile,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_T.primary, _T.primaryMid]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(l10n.retry,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
        ),
      ]),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
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
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(children: [
        Positioned(top: -50, right: -30, child: _blob(160, Colors.white, 0.05)),
        Positioned(top: 20, right: 100, child: _blob(60, Colors.white, 0.04)),
        Positioned(bottom: -20, left: -30, child: _blob(120, _T.accent, 0.13)),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
            child: Column(children: [
              Row(children: [
                Text(l10n.profile,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2)),
                const Spacer(),
                GestureDetector(
                  onTap: _fetchProfile,
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ]),
              const SizedBox(height: 28),
              Stack(alignment: Alignment.bottomRight, children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.5), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 52,
                    backgroundImage: AssetImage("assets/images/avatar.jpg"),
                    backgroundColor: Colors.white24,
                  ),
                ),
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: _T.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: _T.primary, width: 2),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 13),
                ),
              ]),
              const SizedBox(height: 16),
              Text(
                _fullName.isNotEmpty ? _fullName : "User",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3),
              ),
              const SizedBox(height: 5),
              Text(
                _userData!["email"] ?? "email@domain.com",
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _statPill(Icons.badge_rounded,
                      _userData!["role"] ?? "User"),
                  const SizedBox(width: 10),
                  _statPill(Icons.location_on_rounded,
                      _userData!["city"] ?? "Bahir Dar"),
                  const SizedBox(width: 10),
                  _statPill(Icons.verified_rounded, l10n.statusActive,
                      color: _T.green),
                ],
              ),
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

  Widget _statPill(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.11),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color ?? Colors.white.withOpacity(0.85), size: 12),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: color ?? Colors.white.withOpacity(0.85),
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }

  // ── Action Buttons ─────────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    return Column(children: [
      Row(children: [
        Expanded(
          child: _actionButton(
            icon: Icons.edit_rounded,
            label: l10n.editProfile,
            gradient: const LinearGradient(
                colors: [_T.primary, _T.primaryMid],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight),
            shadowColor: _T.primary.withOpacity(0.3),
            onTap: () async {
              final updatedData = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => EditProfilePage(userData: _userData!)),
              );
              if (updatedData != null) _updateProfile(updatedData);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            icon: Icons.logout_rounded,
            label: l10n.logout,
            gradient: LinearGradient(
                colors: [_T.red, _T.red.withOpacity(0.8)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight),
            shadowColor: _T.red.withOpacity(0.25),
            onTap: _logout,
          ),
        ),
      ]),
      const SizedBox(height: 12),
      _actionButton(
        icon: Icons.verified_user_rounded,
        label: l10n.verifyAccount,
        gradient: LinearGradient(
            colors: [_T.green, _T.green.withOpacity(0.8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight),
        shadowColor: _T.green.withOpacity(0.25),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VerifyScreen()),
        ),
      ),
    ]);
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: shadowColor,
                blurRadius: 14,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ]),
      ),
    );
  }

  // ── Info Section ───────────────────────────────────────────────────────────
  Widget _buildSection(String title, IconData icon, List<Widget> rows) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
              offset: Offset(0, 12 * (1 - value)), child: child)),
      child: Container(
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _T.divider, width: 1),
          boxShadow: [
            BoxShadow(
                color: _T.primary.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: _T.accentSoft,
                    borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, color: _T.primary, size: 15),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _T.textDark,
                      letterSpacing: -0.1)),
            ]),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: _T.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
            child: Column(children: rows),
          ),
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: _T.bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _T.accent, size: 16),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _T.textMid)),
        ),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? _T.textDark)),
      ]),
    );
  }
}