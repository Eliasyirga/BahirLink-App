import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/service_report_service.dart';
import '../../services/kebele_service.dart';
import '../chat/chat_page.dart';

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

class ServiceReportDetailPage extends StatelessWidget {
  final dynamic service;
  final String userId;
  final String token;

  const ServiceReportDetailPage({
    super.key,
    required this.service,
    required this.userId,
    required this.token,
  });

  Future<String> _getKebeleName() async {
    try {
      final String? targetId =
          service['kebeleId']?.toString() ?? service['kebele']?.toString();
      if (targetId == null) return "Unknown Kebele";
      final List<Map<String, dynamic>> kebeles =
          await KebeleService().getAllKebeles();
      final match = kebeles.firstWhere(
        (k) =>
            k['id'].toString() == targetId || k['_id'].toString() == targetId,
        orElse: () => {},
      );
      return match['name']?.toString() ?? "Kebele $targetId";
    } catch (e) {
      return "Kebele ${service['kebeleId'] ?? 'N/A'}";
    }
  }

  String _safe(dynamic v) => v?.toString() ?? 'N/A';

  Color _statusColor(String status) {
    if (status == 'COMPLETED') return _T.green;
    if (status == 'REJECTED') return _T.red;
    return _T.orange;
  }

  IconData _statusIcon(String status) {
    if (status == 'COMPLETED') return Icons.check_circle_outline_rounded;
    if (status == 'REJECTED') return Icons.cancel_outlined;
    return Icons.hourglass_top_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final String type = _safe(service['serviceType']?['name']);
    final String category = _safe(service['serviceCategory']?['name']);
    final String status = _safe(service['status']).toUpperCase();
    final String fullImageUrl =
        ServiceReportService.getFullImageUrl(service['mediaUrl']);
    final String dateStr =
        service['createdAt']?.toString().split('T')[0] ?? "N/A";
    final String street = _safe(service['street']);
    final sColor = _statusColor(status);
    final sIcon = _statusIcon(status);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero Header ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildHeader(context, fullImageUrl, type, category,
                  status, sColor, sIcon),
            ),
            // ── Body ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kebele title
                    FutureBuilder<String>(
                      future: _getKebeleName(),
                      builder: (context, snapshot) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              snapshot.data ?? "Loading…",
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: _T.textDark,
                                  letterSpacing: -0.5,
                                  height: 1.1),
                            ),
                            const SizedBox(height: 4),
                            Text(type.toUpperCase(),
                                style: const TextStyle(
                                    color: _T.accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    letterSpacing: 1.2)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _divider(),
                    const SizedBox(height: 24),

                    // Description
                    _sectionLabel("ISSUE DESCRIPTION"),
                    const SizedBox(height: 12),
                    Text(
                      _safe(service['description']),
                      style: const TextStyle(
                          fontSize: 15,
                          height: 1.65,
                          color: _T.textMid),
                    ),
                    const SizedBox(height: 28),

                    // Details card
                    _sectionLabel("REPORT DETAILS"),
                    const SizedBox(height: 12),
                    _infoCard([
                      _infoRow(Icons.location_on_rounded, "STREET", street),
                      _dividerThin(),
                      _infoRow(Icons.calendar_today_rounded, "DATE REPORTED", dateStr),
                      _dividerThin(),
                      _infoRow(Icons.verified_user_outlined, "SYSTEM STATUS", "Official Report"),
                    ]),
                    const SizedBox(height: 28),

                    // Chat button
                    _chatButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header with image + gradient overlay ──────────────────────────────────
  Widget _buildHeader(BuildContext context, String imageUrl, String type,
      String category, String status, Color sColor, IconData sIcon) {
    return Stack(
      children: [
        // Image container
        Container(
          height: 320,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D2580), _T.primary, _T.primaryMid],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            child: Stack(fit: StackFit.expand, children: [
              // Blobs behind image
              Positioned(top: -40, right: -25,
                  child: _blob(140, Colors.white, 0.055)),
              Positioned(bottom: -18, left: -28,
                  child: _blob(105, _T.accent, 0.14)),
              // Network image
              if (imageUrl.isNotEmpty && imageUrl.startsWith('http'))
                Image.network(imageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.12),
                      Colors.black.withOpacity(0.72),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
              // Overlay content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(children: [
                          // Back
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                    width: 1),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                          const Spacer(),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              color: sColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: sColor.withOpacity(0.4), width: 1),
                            ),
                            child: Row(children: [
                              Icon(sIcon, color: sColor, size: 12),
                              const SizedBox(width: 5),
                              Text(status,
                                  style: TextStyle(
                                      color: sColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800)),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                    const Spacer(),
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.28), width: 0.5),
                      ),
                      child: Text(category.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8)),
                    ),
                    const SizedBox(height: 8),
                    Text("Service Report",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _blob(double size, Color color, double opacity) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: color.withOpacity(opacity)));

  // ── Info Card ─────────────────────────────────────────────────────────────
  Widget _infoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.divider, width: 1),
        boxShadow: [
          BoxShadow(
              color: _T.primary.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: _T.accentSoft, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _T.primary, size: 16),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _T.textMid,
                    letterSpacing: 0.8)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _T.textDark)),
          ]),
        ),
      ]),
    );
  }

  Widget _divider() =>
      Container(height: 1, color: _T.divider);

  Widget _dividerThin() =>
      Container(height: 1, color: _T.divider, margin: EdgeInsets.zero);

  Widget _sectionLabel(String text) {
    return Row(children: [
      Container(
        width: 3, height: 14,
        decoration: BoxDecoration(
            color: _T.primary, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 8),
      Text(text,
          style: const TextStyle(
              color: _T.textMid,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 1.2)),
    ]);
  }

  // ── Chat Button ───────────────────────────────────────────────────────────
  Widget _chatButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            emergencyId: int.tryParse(service['_id'].toString()) ?? 0,
            token: token,
            userId: int.tryParse(userId) ?? 0,
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_T.primary, _T.primaryMid],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: _T.primary.withOpacity(0.32),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text("Open Chat",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.2)),
          ],
        ),
      ),
    );
  }
}