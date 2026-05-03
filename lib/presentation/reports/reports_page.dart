import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/reports_service.dart';
import './report_detail_page.dart';

// ─── Design Tokens (mirrored from Dashboard) ──────────────────────────────────
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

class ReportsPage extends StatefulWidget {
  final String userId;
  final String token;

  const ReportsPage({super.key, required this.userId, required this.token});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> emergencies = [];
  bool loading = true;

  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  String? _extractId(dynamic field) {
    if (field == null) return null;
    if (field is String) return field;
    if (field is Map) return field['id']?.toString() ?? field['_id']?.toString();
    return field.toString();
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return "Recently";
    try {
      final dt = DateTime.parse(dateStr.toString());
      return DateFormat('MMM dd, hh:mm a').format(dt);
    } catch (_) {
      return "Recently";
    }
  }

  Future<void> fetchInitialData() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      final emergenciesResponse =
          await ReportsService.fetchUserEmergencies(widget.userId);
      final categories = await ReportsService.fetchCategories();

      final Map<String, String> categoryMap = {
        for (var c in categories) c['id'].toString(): c['name'].toString(),
      };
      final Map<String, String> typeMap = {
        for (var c in categories)
          c['id'].toString():
              c['emergencyType']?['name']?.toString() ?? "General",
      };

      final enriched = emergenciesResponse.map((e) {
        final categoryId =
            _extractId(e['categoryId']) ?? _extractId(e['category']);
        return {
          ...e,
          'id': _extractId(e['id']) ?? _extractId(e['_id']),
          'categoryName': categoryId != null
              ? (categoryMap[categoryId] ?? "Uncategorized")
              : "Uncategorized",
          'typeName': categoryId != null
              ? (typeMap[categoryId] ?? "General")
              : "General",
          'description':
              e['description']?.toString() ?? "No description provided.",
          'createdAt':
              e['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
        };
      }).toList();

      if (mounted) {
        setState(() {
          emergencies = enriched;
          loading = false;
        });
        _fadeCtrl.forward();
      }
    } catch (e) {
      debugPrint("ReportsPage Error: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: loading
            ? _buildSplash()
            : FadeTransition(
                opacity: _fadeAnim,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    if (emergencies.isEmpty)
                      SliverFillRemaining(child: _buildEmptyState())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                _buildCard(emergencies[index], index),
                            childCount: emergencies.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Splash ───────────────────────────────────────────────────────────────
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
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2.5,
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
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
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
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
              Row(children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
                const Spacer(),
                // Refresh button
                GestureDetector(
                  onTap: fetchInitialData,
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ]),
              const SizedBox(height: 22),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("My Emergency",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.62),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    const Text("Reports",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            height: 1.1)),
                  ]),
                ),
                if (!loading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                              color: _T.green, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text("${emergencies.length} Reports",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
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

  // ── Card ──────────────────────────────────────────────────────────────────
  Widget _buildCard(Map<String, dynamic> report, int index) {
    final String typeName = report['typeName'] ?? "General";
    final String categoryName = report['categoryName'] ?? "Uncategorized";
    final String description = report['description'] ?? "";
    final String date = _formatDate(report['createdAt']);

    final bool isCritical = typeName.toLowerCase().contains('critical');
    final Color typeColor = isCritical ? _T.red : _T.accent;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 80),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportDetailsPage(
                emergency: report,
                userId: widget.userId,
                token: widget.token,
              ),
            ),
          );
          if (result is String) {
            setState(() {
              emergencies.removeWhere(
                (item) => (item['id'] ?? item['_id']).toString() == result,
              );
            });
          } else if (result == true) {
            fetchInitialData();
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _T.divider, width: 1),
            boxShadow: [
              BoxShadow(
                  color: _T.primary.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 5)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Top row: type badge + date
              Row(children: [
                _typeBadge(typeName, typeColor),
                const Spacer(),
                Row(children: [
                  Icon(Icons.access_time_rounded, size: 11, color: _T.textMid),
                  const SizedBox(width: 4),
                  Text(date,
                      style: const TextStyle(
                          color: _T.textMid, fontSize: 11, fontWeight: FontWeight.w500)),
                ]),
              ]),
              const SizedBox(height: 14),
              // Category name
              Text(categoryName,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _T.textDark,
                      letterSpacing: -0.2)),
              const SizedBox(height: 5),
              // Description
              Text(description,
                  style: const TextStyle(
                      fontSize: 13, color: _T.textMid, height: 1.45),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 14),
              Container(height: 1, color: _T.divider),
              const SizedBox(height: 12),
              // Footer
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: _T.accentSoft,
                      borderRadius: BorderRadius.circular(7)),
                  child: const Row(children: [
                    Icon(Icons.open_in_new_rounded, size: 11, color: _T.accent),
                    SizedBox(width: 5),
                    Text("View details",
                        style: TextStyle(
                            color: _T.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: _T.textMid.withOpacity(0.5)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _typeBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.w800,
              letterSpacing: 0.4)),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
              color: _T.accentSoft, borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.assignment_late_outlined,
              size: 36, color: _T.primary),
        ),
        const SizedBox(height: 18),
        const Text("No Reports Yet",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _T.textDark)),
        const SizedBox(height: 6),
        const Text("Your submitted reports will appear here.",
            style: TextStyle(fontSize: 13, color: _T.textMid)),
      ]),
    );
  }
}