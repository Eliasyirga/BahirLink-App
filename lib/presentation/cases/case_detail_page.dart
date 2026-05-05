import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'case_report_page.dart';

// ─── Design Tokens (inherited from Dashboard) ─────────────────────────────────
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

// ─── CaseDetailPage ───────────────────────────────────────────────────────────
class CaseDetailPage extends StatelessWidget {
  final dynamic caseData;
  const CaseDetailPage({super.key, required this.caseData});

  // ── Status helpers (same logic as Dashboard case slider) ──────────────────
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':     return _T.orange;
      case 'in_progress': return _T.accent;
      default:            return _T.green;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':     return 'Pending';
      case 'in_progress': return 'In Progress';
      default:            return status.toUpperCase();
    }
  }

  // ── Kebele resolver ───────────────────────────────────────────────────────
  String get _kebeleName {
    if (caseData['Kebele']?['name'] != null) return caseData['Kebele']['name'];
    if (caseData['kebele_name'] != null)      return caseData['kebele_name'];
    return 'Location Not Set';
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = caseData['mediaUrl'] != null
        ? "http://localhost:5000${caseData['mediaUrl']}"
        : "https://via.placeholder.com/800x400/1A3BAA/FFFFFF?text=Report";

    final status      = (caseData['status'] ?? '').toString();
    final isDangerous = caseData['isDangerous'] ?? false;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero App Bar ──────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 380,
              pinned: true,
              backgroundColor: _T.primary,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.28),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(fit: StackFit.expand, children: [
                  // Case image
                  Hero(
                    tag: 'case_${caseData['id']}',
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _T.primary,
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.white24, size: 60),
                      ),
                    ),
                  ),
                  // Same gradient overlay as dashboard case slider
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.18),
                          Colors.black.withOpacity(0.82),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                  // Glass badges row — same as dashboard _glassBadge
                  Positioned(
                    top: kToolbarHeight + 8,
                    left: 16,
                    right: 16,
                    child: Row(children: [
                      _glassBadge(
                          caseData['caseType']?['name'] ?? 'Report',
                          Icons.report_rounded),
                      const Spacer(),
                      _colorBadge(
                          _statusLabel(status), _statusColor(status)),
                    ]),
                  ),
                  // Danger tag — inherits same BackdropFilter pattern
                  if (isDangerous) const _DangerTag(),
                  // Bottom overlay: name + location + reward
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                        caseData['fullName'] ?? 'Unknown Identity',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            letterSpacing: -0.4,
                            height: 1.1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.location_on_rounded,
                            color: Colors.white60, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            caseData['location'] ?? 'Bahir Dar',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Reward pill — same style as dashboard ETB pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: _T.green,
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(children: [
                            const Icon(Icons.monetization_on_rounded,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 5),
                            Text(
                              "${caseData['reward'] ?? '0'} ETB",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800),
                            ),
                          ]),
                        ),
                      ]),
                    ]),
                  ),
                ]),
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Last known location
                  _sectionLabel("Last Known Location",
                      Icons.map_rounded),
                  const SizedBox(height: 12),
                  _buildLocationCard(),

                  const SizedBox(height: 26),

                  // Physical identifiers grid
                  _sectionLabel("Physical Identifiers",
                      Icons.person_search_rounded),
                  const SizedBox(height: 12),
                  _buildPhysicalGrid(),

                  const SizedBox(height: 26),

                  // Distinctive marks
                  _sectionLabel("Distinctive Marks",
                      Icons.fingerprint_rounded),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _featureBox(
                      caseData['distinctiveFeatures'] ??
                          'No distinctive marks reported.',
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Description
                  _sectionLabel("Case Description",
                      Icons.description_rounded),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _T.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: _T.primary.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Text(
                        caseData['description'] ??
                            'No additional description provided.',
                        style: TextStyle(
                            fontSize: 14,
                            color: _T.textDark.withOpacity(0.8),
                            height: 1.65),
                      ),
                    ),
                  ),

                  const SizedBox(height: 110),
                ],
              ),
            ),
          ],
        ),

        // ── FAB — same blue CTA style as dashboard buttons ────────────────
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: _T.primary.withOpacity(0.32),
                      blurRadius: 18,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CaseReportPage(caseData: caseData)),
                ),
                child: const Text(
                  "PROVIDE ANONYMOUS TIP",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Section label — same pattern as dashboard _sectionLabel ───────────────
  Widget _sectionLabel(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: _T.accentSoft,
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: _T.primary, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _T.textDark,
              letterSpacing: -0.2),
        ),
      ]),
    );
  }

  // ── Location card ─────────────────────────────────────────────────────────
  Widget _buildLocationCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: _T.primary.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: _T.accentSoft,
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.map_rounded, color: _T.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(_kebeleName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: _T.textDark)),
              const SizedBox(height: 2),
              Text(
                "Last seen: ${_formatDate(caseData['lastSeenDate'])}",
                style: TextStyle(
                    color: _T.textMid,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Physical identifiers 2-col grid ──────────────────────────────────────
  Widget _buildPhysicalGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 2.4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        padding: EdgeInsets.zero,
        children: [
          _infoTile("AGE", "${caseData['age'] ?? 'N/A'} yrs",
              Icons.cake_rounded),
          _infoTile(
              "GENDER", caseData['gender'] ?? 'N/A', Icons.person_rounded),
          _infoTile("HEIGHT", caseData['height'] ?? 'N/A',
              Icons.straighten_rounded),
          _infoTile("WEIGHT", caseData['weight'] ?? 'N/A',
              Icons.monitor_weight_rounded),
        ],
      ),
    );
  }

  // ── Info tile — same card language as dashboard grid cards ────────────────
  Widget _infoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.divider, width: 1),
        boxShadow: [
          BoxShadow(
              color: _T.primary.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: _T.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: _T.textMid,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _T.textDark)),
          ]),
        ),
      ]),
    );
  }

  // ── Feature / marks box ───────────────────────────────────────────────────
  Widget _featureBox(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _T.accentSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.accent.withOpacity(0.25), width: 1),
      ),
      child: Text(value,
          style: const TextStyle(
              fontSize: 14, color: _T.textDark, height: 1.55)),
    );
  }

  // ── Glass badge — copied exactly from Dashboard ───────────────────────────
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
            border: Border.all(
                color: Colors.white.withOpacity(0.28), width: 0.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 10),
            const SizedBox(width: 4),
            Text(txt,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }

  // ── Color badge — copied exactly from Dashboard ───────────────────────────
  Widget _colorBadge(String txt, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Text(txt,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800)),
      );

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr.toString();
    }
  }
}

// ─── Danger Tag — same BackdropFilter pattern as Dashboard ───────────────────
class _DangerTag extends StatelessWidget {
  const _DangerTag();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _T.red.withOpacity(0.78),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
            ),
            child: const Row(children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 14),
              SizedBox(width: 6),
              Text("DANGER ALERT",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.5)),
            ]),
          ),
        ),
      ),
    );
  }
}
