import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:first_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_app/main.dart';
import 'package:first_app/services/case_service.dart';
import 'case_report_page.dart';

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

// ─── CaseDetailPage ───────────────────────────────────────────────────────────
class CaseDetailPage extends StatefulWidget {
  final dynamic caseData;
  final String  initialLang;

  const CaseDetailPage({
    super.key,
    required this.caseData,
    this.initialLang = 'en',
  });

  @override
  State<CaseDetailPage> createState() => _CaseDetailPageState();
}

class _CaseDetailPageState extends State<CaseDetailPage> {

  late dynamic _caseData;
  late String  _currentLang;
  bool         _isSwitchingLang = false;

  @override
  void initState() {
    super.initState();
    _caseData    = widget.caseData;
    _currentLang = widget.initialLang;
  }

  // ── Language switch ────────────────────────────────────────────────────────
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
      final caseId    = widget.caseData['id'];
      final refreshed = await CaseService.getCaseById(
        id: caseId.toString(),
        lang: langCode,
      );
      if (mounted && refreshed != null) {
        setState(() => _caseData = refreshed);
      }
    } finally {
      if (mounted) setState(() => _isSwitchingLang = false);
    }
  }

  // ── Lang toggle widget ─────────────────────────────────────────────────────
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
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: _isSwitchingLang
            ? const SizedBox(
                width: 22,
                height: 14,
                child: Center(
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
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

  // ── Status helpers ─────────────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':     return _T.orange;
      case 'in_progress': return _T.accent;
      default:            return _T.green;
    }
  }

  String _statusLabel(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'pending':     return l10n.caseDetailStatusPending;
      case 'in_progress': return l10n.caseDetailStatusInProgress;
      default:            return status.toUpperCase();
    }
  }

  // ── Kebele name ────────────────────────────────────────────────────────────
  String _kebeleName(AppLocalizations l10n) {
    return CaseService.extractKebele(
      _caseData,
      fallback: l10n.caseDetailLocationNotSet,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n        = AppLocalizations.of(context)!;
    final status      = (_caseData['status'] ?? '').toString();
    final isDangerous = _caseData['isDangerous'] ?? false;

    final String imageUrl = _caseData['mediaUrl'] != null
        ? "http://localhost:5000${_caseData['mediaUrl']}"
        : "https://via.placeholder.com/800x400/1A3BAA/FFFFFF?text=Report";

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            // ── Hero App Bar ────────────────────────────────────────────────
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
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                  child: _buildLangToggle(),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(fit: StackFit.expand, children: [
                  Hero(
                    tag: 'case_${_caseData['id']}',
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
                  // Gradient overlay
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
                  // Glass badges row
                  Positioned(
                    top: kToolbarHeight + 8,
                    left: 16,
                    right: 16,
                    child: Row(children: [
                      _glassBadge(
                        _caseData['caseType']?['name'] ?? l10n.defaultCaseType,
                        Icons.report_rounded,
                      ),
                      const Spacer(),
                      _colorBadge(
                        _statusLabel(context, status),
                        _statusColor(status),
                      ),
                    ]),
                  ),
                  // Danger tag
                  if (isDangerous) _DangerTag(label: l10n.caseDetailDangerAlert),
                  // Bottom overlay
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _caseData['fullName'] ?? l10n.caseDetailUnknownIdentity,
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
                              _caseData['location'] ?? l10n.locationCity,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                                l10n.caseDetailEtb(
                                    (_caseData['reward'] ?? '0').toString()),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800),
                              ),
                            ]),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ]),
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _isSwitchingLang
                  ? _buildShimmer()
                  : _buildBody(context, l10n),
            ),
          ],
        ),

        // ── FAB ─────────────────────────────────────────────────────────────
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
                      builder: (_) => CaseReportPage(caseData: _caseData)),
                ),
                child: Text(
                  l10n.caseDetailProvideTip,
                  style: const TextStyle(
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

  // ── Shimmer ────────────────────────────────────────────────────────────────
  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      child: Column(children: [
        for (int i = 0; i < 4; i++) ...[
          Container(
            height: i == 0 ? 80 : 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  _T.primary.withOpacity(0.08),
                  _T.primary.withOpacity(0.04),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ]),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _sectionLabel(l10n.caseDetailLastKnownLocation, Icons.map_rounded),
        const SizedBox(height: 12),
        _buildLocationCard(l10n),
        const SizedBox(height: 26),
        _sectionLabel(l10n.caseDetailPhysicalIdentifiers, Icons.person_search_rounded),
        const SizedBox(height: 12),
        _buildPhysicalGrid(l10n),
        const SizedBox(height: 26),
        _sectionLabel(l10n.caseDetailDistinctiveMarks, Icons.fingerprint_rounded),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _featureBox(
            _caseData['distinctiveFeatures'] ?? l10n.caseDetailNoMarks,
          ),
        ),
        const SizedBox(height: 26),
        _sectionLabel(l10n.caseDetailCaseDescription, Icons.description_rounded),
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
              _caseData['description'] ?? l10n.caseDetailNoDescription,
              style: TextStyle(
                  fontSize: 14,
                  color: _T.textDark.withOpacity(0.8),
                  height: 1.65),
            ),
          ),
        ),
        const SizedBox(height: 110),
      ],
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _sectionLabel(String title, IconData icon) {
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
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _T.textDark,
                letterSpacing: -0.2)),
      ]),
    );
  }

  // ── Location card ──────────────────────────────────────────────────────────
  Widget _buildLocationCard(AppLocalizations l10n) {
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
                color: _T.accentSoft, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.map_rounded, color: _T.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _kebeleName(l10n),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: _T.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.caseDetailLastSeen(
                      _formatDate(_caseData['lastSeenDate'])),
                  style: const TextStyle(
                      color: _T.textMid,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ── Physical grid ──────────────────────────────────────────────────────────
  Widget _buildPhysicalGrid(AppLocalizations l10n) {
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
          _infoTile(
            l10n.caseDetailAge,
            l10n.caseDetailAgeYrs((_caseData['age'] ?? 'N/A').toString()),
            Icons.cake_rounded,
          ),
          _infoTile(
            l10n.caseDetailGender,
            _caseData['gender'] ?? 'N/A',
            Icons.person_rounded,
          ),
          _infoTile(
            l10n.caseDetailHeight,
            _caseData['height'] ?? 'N/A',
            Icons.straighten_rounded,
          ),
          _infoTile(
            l10n.caseDetailWeight,
            _caseData['weight'] ?? 'N/A',
            Icons.monitor_weight_rounded,
          ),
        ],
      ),
    );
  }

  // ── Info tile ──────────────────────────────────────────────────────────────
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
            ],
          ),
        ),
      ]),
    );
  }

  // ── Feature box ───────────────────────────────────────────────────────────
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

  // ── Glass badge ───────────────────────────────────────────────────────────
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

  // ── Color badge ───────────────────────────────────────────────────────────
  Widget _colorBadge(String txt, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(8)),
        child: Text(txt,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800)),
      );

  // ── Date formatter ────────────────────────────────────────────────────────
  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr.toString();
    }
  }
}

// ─── Danger Tag ───────────────────────────────────────────────────────────────
class _DangerTag extends StatelessWidget {
  final String label;
  const _DangerTag({required this.label});

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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _T.red.withOpacity(0.78),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.white.withOpacity(0.2), width: 0.5),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
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