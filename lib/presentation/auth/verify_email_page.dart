import 'dart:async';
import 'package:flutter/material.dart';
import 'package:first_app/services/auth_service.dart';
import 'login_page.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;
  final bool isPopup;

  const VerifyEmailPage({super.key, required this.email, this.isPopup = false});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  int _secondsRemaining = 600;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _timerText {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 4) {
      _showSnackBar('Enter a 4-digit code', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await AuthService.verifyEmailCode(
        email: widget.email,
        code: code,
      );

      if (!mounted) return;

      if (res["success"] == true) {
        _showSnackBar('Email verified successfully!', Colors.green);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } else {
        _showSnackBar(res["error"] ?? "Verification failed", Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar("An unexpected error occurred.", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Shared content for both Popup and Full Screen
    Widget mainContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.mark_email_unread_rounded,
          size: 60,
          color: Color(0xFF4A90E2),
        ),
        const SizedBox(height: 16),
        const Text(
          "Verify Your Email",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF444444),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "A 4-digit code was sent to\n${widget.email}",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 30),
        _buildCodeField(),
        const SizedBox(height: 20),
        _buildTimerDisplay(),
        const SizedBox(height: 30),
        _buildVerifyButton(),
      ],
    );

    if (widget.isPopup) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Material(
            color: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                mainContent,
                Positioned(
                  top: -10,
                  right: -10,
                  child: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildWaveHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: mainContent,
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
          clipper: _VerifyWaveClipper(),
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

  Widget _buildCodeField() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _codeController,
        keyboardType: TextInputType.number,
        maxLength: 4,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 15,
          color: Color(0xFF4A90E2),
        ),
        decoration: const InputDecoration(
          hintText: "0000",
          hintStyle: TextStyle(color: Colors.black12, letterSpacing: 15),
          counterText: "",
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildTimerDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.access_time_rounded,
            size: 18,
            color: _secondsRemaining < 60 ? Colors.redAccent : Colors.grey),
        const SizedBox(width: 6),
        Text(
          "Code expires in: $_timerText",
          style: TextStyle(
            color: _secondsRemaining < 60 ? Colors.redAccent : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyCode,
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
            : const Text("Verify Account",
                style: TextStyle(
                    color: Color(0xFF4A90E2),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
      ),
    );
  }
}

// Custom Clipper to keep the design language consistent
class _VerifyWaveClipper extends CustomClipper<Path> {
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
