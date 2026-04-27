import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_page.dart';
import '../dashboard/dashboard_page.dart';
import '../dashboard/guest_dashboard_page.dart';
import '../../services/auth_service.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final result = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      if (result["success"] == true && result["accessToken"] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("accessToken", result["accessToken"].toString());
        await prefs.setString("userId", result["user"]["id"].toString());
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardPage(
              userId: result["user"]["id"].toString(),
              token: result["accessToken"].toString(),
            ),
          ),
        );
      } else {
        _showError(result["error"] ?? "Authentication failed");
      }
    } catch (e) {
      _showError("An error occurred. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildWaveHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    const Text(
                      "Welcome back !",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF444444),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildTextField(
                      controller: _emailController,
                      hint: "Username",
                      icon: Icons.person_outline,
                      validator: (value) =>
                          value!.isEmpty ? "Enter username" : null,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _passwordController,
                      hint: "Password",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: !_isPasswordVisible,
                      onSuffixPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                      validator: (value) =>
                          value!.length < 6 ? "Password too short" : null,
                    ),
                    const SizedBox(height: 10),
                    _buildForgotPasswordOnly(),
                    const SizedBox(height: 30),
                    _buildLoginButton(),
                    const SizedBox(height: 15),
                    _buildGuestButton(),
                    const SizedBox(height: 25),
                    _buildSignUpLink(),
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

  Widget _buildWaveHeader() {
    return Stack(
      children: [
        ClipPath(
          clipper: CustomWaveClipper(),
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Image.asset(
                'assets/images/logo.webp',
                height: 70,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.link, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                "BAHIR LINK",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF4A90E2), size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                    size: 18),
                onPressed: onSuffixPressed,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF1F7FF),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildForgotPasswordOnly() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
        child: const Text(
          "Forget password?",
          style: TextStyle(
              color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF4A90E2)))
            : const Text("Login",
                style: TextStyle(
                    color: Color(0xFF4A90E2),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
      ),
    );
  }

  Widget _buildGuestButton() {
    return TextButton(
      onPressed: () => Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const GuestDashboardPage())),
      child: const Text("Continue as Guest",
          style:
              TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("New user? ", style: TextStyle(color: Colors.grey)),
        GestureDetector(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const SignUpPage())),
          child: const Text("Sign Up",
              style: TextStyle(
                  color: Color(0xFF4A90E2), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class CustomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 60);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint =
        Offset(size.width - (size.width / 3.25), size.height - 65);
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
