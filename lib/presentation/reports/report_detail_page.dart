import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/reports_service.dart';
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

class ReportDetailsPage extends StatefulWidget {
  final Map<String, dynamic> emergency;
  final String userId;
  final String token;

  const ReportDetailsPage({
    super.key,
    required this.emergency,
    required this.userId,
    required this.token,
  });

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage>
    with TickerProviderStateMixin {
  File? _mediaFile;
  Uint8List? _webBytes;

  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  String safe(dynamic v) => v?.toString() ?? 'N/A';

  Color _statusColor(String status) {
    if (status.contains('RESOLVED') || status.contains('COMPLETED'))
      return _T.green;
    if (status.contains('REJECTED')) return _T.red;
    return _T.orange;
  }

  IconData _statusIcon(String status) {
    if (status.contains('RESOLVED') || status.contains('COMPLETED'))
      return Icons.check_circle_outline_rounded;
    if (status.contains('REJECTED')) return Icons.cancel_outlined;
    return Icons.hourglass_top_rounded;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final e = widget.emergency;
    final status = safe(e['status']).toUpperCase();
    final bool isCritical =
        safe(e['typeName']).toLowerCase().contains('critical');
    final sColor = _statusColor(status);
    final sIcon = _statusIcon(status);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(context, e, status, sColor, sIcon, isCritical),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title block
                      Text(safe(e['categoryName']),
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: _T.textDark,
                              letterSpacing: -0.5,
                              height: 1.1)),
                      const SizedBox(height: 5),
                      Text("Reported at ${safe(e['time'])}",
                          style: const TextStyle(
                              color: _T.textMid,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 24),
                      _divider(),
                      const SizedBox(height: 24),

                      // Description
                      _sectionLabel("DESCRIPTION"),
                      const SizedBox(height: 12),
                      Text(safe(e['description']),
                          style: const TextStyle(
                              fontSize: 15, height: 1.65, color: _T.textMid)),
                      const SizedBox(height: 28),

                      // Location card
                      _sectionLabel("LOCATION"),
                      const SizedBox(height: 12),
                      _locationCard(e),
                      const SizedBox(height: 28),

                      // Action buttons
                      _actionRow(safe(e['id'])),
                      const SizedBox(height: 20),

                      // Chat button
                      _chatButton(context, e),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, Map<String, dynamic> e,
      String status, Color sColor, IconData sIcon, bool isCritical) {
    return Stack(children: [
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
            Positioned(top: -40, right: -25,
                child: _blob(140, Colors.white, 0.055)),
            Positioned(bottom: -18, left: -28,
                child: _blob(105, _T.accent, 0.14)),
            _buildHeroImage(e['mediaUrl']),
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
            // Controls
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
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.28), width: 0.5),
                      ),
                      child: Text(safe(e['typeName']).toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8)),
                    ),
                    const SizedBox(height: 8),
                    Text("Emergency Report",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ]),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _blob(double size, Color color, double opacity) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: color.withOpacity(opacity)));

  Widget _buildHeroImage(String? mediaUrl) {
    if (kIsWeb && _webBytes != null)
      return Image.memory(_webBytes!, fit: BoxFit.cover);
    if (_mediaFile != null) return Image.file(_mediaFile!, fit: BoxFit.cover);
    if (mediaUrl != null && mediaUrl.isNotEmpty) {
      final url = mediaUrl.startsWith('http')
          ? mediaUrl
          : "http://localhost:5000$mediaUrl";
      return Image.network(url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink());
    }
    return const SizedBox.shrink();
  }

  // ── Location Card ─────────────────────────────────────────────────────────
  Widget _locationCard(Map<String, dynamic> e) {
    String kebeleName = 'N/A';
    if (e['kebele'] != null) {
      kebeleName = e['kebele'] is Map
          ? (e['kebele']['name'] ?? 'N/A')
          : e['kebele'].toString();
    }
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: _T.accentSoft,
              borderRadius: BorderRadius.circular(13)),
          child: const Icon(Icons.location_on_rounded,
              color: _T.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("BAHIR DAR · KEBELE",
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _T.textMid,
                    letterSpacing: 0.8)),
            const SizedBox(height: 3),
            Text(kebeleName,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _T.textDark)),
          ]),
        ),
      ]),
    );
  }

  // ── Action Row ────────────────────────────────────────────────────────────
  Widget _actionRow(String id) {
    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: () => _showEditDialog(id),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_T.primary, _T.primaryMid],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: _T.primary.withOpacity(0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 5)),
              ],
            ),
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text("Update Details",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ]),
          ),
        ),
      ),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: () => _confirmLocalClear(id),
        child: Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _T.divider, width: 1),
            boxShadow: [
              BoxShadow(
                  color: _T.primary.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: const Icon(Icons.archive_outlined,
              color: _T.accent, size: 20),
        ),
      ),
    ]);
  }

  // ── Chat Button ───────────────────────────────────────────────────────────
  Widget _chatButton(BuildContext context, Map<String, dynamic> e) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            emergencyId: int.tryParse(safe(e['id'])) ?? 0,
            token: widget.token,
            userId: int.tryParse(widget.userId) ?? 0,
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _T.divider, width: 1),
          boxShadow: [
            BoxShadow(
                color: _T.primary.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 3)),
          ],
        ),
        child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  color: _T.primary, size: 18),
              SizedBox(width: 10),
              Text("Open Chat",
                  style: TextStyle(
                      color: _T.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
            ]),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _divider() => Container(height: 1, color: _T.divider);

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

  void _confirmLocalClear(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _T.surface,
        title: const Text("Archive Report?",
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _T.textDark,
                fontSize: 17)),
        content: const Text(
            "This report will be hidden from your current view.",
            style: TextStyle(color: _T.textMid, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Keep",
                style: TextStyle(color: _T.textMid, fontWeight: FontWeight.w600)),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(ctx);
              Navigator.pop(context, id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: _T.accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text("Archive",
                  style: TextStyle(
                      color: _T.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String id) {
    final descC = TextEditingController(
        text: safe(widget.emergency['description']));
    final kObj = widget.emergency['kebele'];
    final kebeleC = TextEditingController(
        text: kObj is Map ? safe(kObj['name']) : safe(kObj));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _T.surface,
        title: const Text("Update Report",
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _T.textDark,
                fontSize: 17)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _field("Kebele", kebeleC),
          _field("Description", descC, maxLines: 4),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Discard",
                style: TextStyle(color: _T.textMid, fontWeight: FontWeight.w600)),
          ),
          GestureDetector(
            onTap: () async {
              final data = {
                'description': descC.text,
                'kebele': kebeleC.text
              };
              await ReportsService.updateEmergency(widget.userId, id, data);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context, true);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_T.primary, _T.primaryMid]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text("Save Changes",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        style: const TextStyle(color: _T.textDark, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _T.textMid, fontSize: 13),
          filled: true,
          fillColor: _T.bg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _T.accent, width: 1.5)),
        ),
      ),
    );
  }
}