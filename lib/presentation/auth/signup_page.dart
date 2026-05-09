import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import 'verify_email_page.dart';
import 'login_page.dart';
import 'package:first_app/l10n/app_localizations.dart';
import 'package:first_app/main.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _T {
  static const primary    = Color(0xFF1A3BAA);
  static const primaryMid = Color(0xFF2252CC);
  static const accent     = Color(0xFF4B83F0);
  static const accentSoft = Color(0xFFD6E4FF);
  static const textMid    = Color(0xFF5569A0);
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController  = TextEditingController();
  final TextEditingController _emailController     = TextEditingController();
  final TextEditingController _passwordController  = TextEditingController();

  bool _isLoading         = false;
  bool _isPasswordVisible = false;

  // ── Language state ──────────────────────────────────────────────────────────
  String _currentLang     = 'en';
  bool   _isSwitchingLang = false;

  // ── Pulse animation (logo rings) ────────────────────────────────────────────
  late final AnimationController _pulseCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat(reverse: true);
  late final Animation<double> _pulseAnim =
      Tween<double>(begin: 0.88, end: 1.0).animate(
          CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _loadSavedLang();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Language helpers ────────────────────────────────────────────────────────
  Future<void> _loadSavedLang() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language_code') ?? 'en';
    if (mounted) setState(() => _currentLang = saved);
  }

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
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _isSwitchingLang = false);
  }

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
              : Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
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
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3),
              ),
      ),
    );
  }

  // ── Sign-up logic ───────────────────────────────────────────────────────────
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final res = await AuthService.register(
        firstName: _firstNameController.text.trim(),
        lastName:  _lastNameController.text.trim(),
        email:     _emailController.text.trim().toLowerCase(),
        password:  _passwordController.text.trim(),
      );
      if (!mounted) return;

      if (res["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res["message"] ?? "Account created!"),
            behavior: SnackBarBehavior.floating,
          ),
        );
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20),
            child: VerifyEmailPage(
              email: _emailController.text.trim().toLowerCase(),
              isPopup: true,
            ),
          ),
        );
      } else {
        _showError(res["error"] ?? "Signup failed");
      }
    } catch (e) {
      _showError("An unexpected error occurred.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(l10n),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      l10n.signupCreateAccount,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0C1A45),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _firstNameController,
                      hint: l10n.signupFirstName,
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v!.isEmpty ? l10n.signupEnterFirstName : null,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _lastNameController,
                      hint: l10n.signupLastName,
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v!.isEmpty ? l10n.signupEnterLastName : null,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _emailController,
                      hint: l10n.signupEmailAddress,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          !v!.contains('@') ? l10n.signupInvalidEmail : null,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _passwordController,
                      hint: l10n.signupPassword,
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: !_isPasswordVisible,
                      onSuffixPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                      validator: (v) =>
                          v!.length < 6 ? l10n.signupPasswordMin : null,
                    ),
                    const SizedBox(height: 30),
                    _buildSignUpButton(l10n),
                    const SizedBox(height: 20),
                    _buildLoginLink(l10n),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header: wave + home-style pulsing logo ──────────────────────────────────
  Widget _buildHeader(AppLocalizations l10n) {
    return Stack(
      children: [
        // Wave background
        ClipPath(
          clipper: _WaveClipper(),
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D2580), _T.primary, _T.primaryMid],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),

        // Back arrow (top-left)
        Positioned(
          top: 44,
          left: 12,
          child: SafeArea(
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              tooltip: 'Back',
            ),
          ),
        ),

        // Lang toggle (top-right)
        Positioned(
          top: 44,
          right: 12,
          child: SafeArea(child: _buildLangToggle()),
        ),

        // Pulsing logo rings (centred)
        Positioned(
          top: 44,
          left: 0,
          right: 0,
          child: Column(
            children: [
              ScaleTransition(
                scale: _pulseAnim,
                child: Stack(alignment: Alignment.center, children: [
                  Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.10), width: 2),
                    ),
                  ),
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.07),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.20), width: 1.5),
                    ),
                  ),
                  Container(
                    width: 66, height: 66,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.22),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(13),
                        child: Image.asset(
                          'assets/images/logo.webp',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                              Icons.hub_rounded,
                              color: _T.primary, size: 32),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              const Text(
                "BAHIR LINK",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onSuffixPressed,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _T.textMid, fontSize: 14),
        prefixIcon: Icon(icon, color: _T.primary, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: _T.textMid,
                    size: 18),
                onPressed: onSuffixPressed,
              )
            : null,
        filled: true,
        fillColor: _T.accentSoft.withOpacity(0.35),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: _T.accent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSignUpButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: _T.primary,
          foregroundColor: Colors.white,
          side: const BorderSide(color: _T.primary, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(
                l10n.signupCreateAccountButton,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
      ),
    );
  }

  Widget _buildLoginLink(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(l10n.signupAlreadyHaveAccount,
            style: const TextStyle(color: _T.textMid)),
        GestureDetector(
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          ),
          child: Text(
            l10n.signupLoginLink,
            style: const TextStyle(
                color: _T.primary, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

// ── Wave clipper ──────────────────────────────────────────────────────────────
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
        size.width / 4, size.height,
        size.width / 2.25, size.height - 30);
    path.quadraticBezierTo(
        size.width - (size.width / 3.25), size.height - 65,
        size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}