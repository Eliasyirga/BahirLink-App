import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_app/l10n/app_localizations.dart';
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

String _imageUrl(dynamic path) =>
    ServiceReportService.getFullImageUrl(path?.toString());

// ─── Page ────────────────────────────────────────────────────────────────────
class ServiceReportDetailPage extends StatefulWidget {
  final Map<String, dynamic> service;
  final String userId;
  final String token;

  const ServiceReportDetailPage({
    super.key,
    required this.service,
    required this.userId,
    required this.token,
  });

  @override
  State<ServiceReportDetailPage> createState() =>
      _ServiceReportDetailPageState();
}

class _ServiceReportDetailPageState extends State<ServiceReportDetailPage> {
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  String _currentLang = 'en';

  @override
  void initState() {
    super.initState();
    _loadLang();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language_code') ?? 'en';
    if (mounted) setState(() => _currentLang = saved);
  }

  // ── Lang-aware text extractor ──────────────────────────────────────────────
  // Handles: plain String, {en, am} map, nested {name: {en, am}} map,
  // and JSON-encoded strings (already decoded by ServiceReportService._normalizeItem)
  String _loc(dynamic field, {String fallback = 'N/A'}) {
    if (field == null) return fallback;

    if (field is String) {
      return field.trim().isEmpty ? fallback : field.trim();
    }

    if (field is Map) {
      // Case 1: nested object with 'name' key e.g. serviceType: {name: {en, am}}
      final nameField = field['name'];
      if (nameField != null) {
        return _loc(nameField, fallback: fallback);
      }

      // Case 2: direct localisation map e.g. {en: "Fire", am: "እሳት"}
      final preferred = field[_currentLang];
      if (preferred != null && preferred.toString().trim().isNotEmpty) {
        return preferred.toString().trim();
      }
      final fallbackEn = field['en'];
      if (fallbackEn != null && fallbackEn.toString().trim().isNotEmpty) {
        return fallbackEn.toString().trim();
      }

      // Case 3: other string keys e.g. {title: "...", label: "..."}
      for (final key in ['title', 'label']) {
        final v = field[key];
        if (v != null && v.toString().trim().isNotEmpty) {
          return v.toString().trim();
        }
      }

      // Last resort: first non-null value
      for (final v in field.values) {
        if (v != null && v.toString().trim().isNotEmpty) {
          return v.toString().trim();
        }
      }
    }

    return fallback;
  }

  // ── Plain string — never a localised map (status, date) ───────────────────
  String _plain(dynamic field, {String fallback = 'N/A'}) {
    if (field == null) return fallback;
    if (field is String) return field.trim().isEmpty ? fallback : field.trim();
    return field.toString();
  }

  // ── Kebele resolution ──────────────────────────────────────────────────────
  Future<String> _resolveKebeleName() async {
    final nested = widget.service['Kebele'] ?? widget.service['kebele'];
    if (nested is Map) {
      final name = _loc(nested['name'], fallback: '');
      if (name.isNotEmpty) return name;
    }

    final lastSeen = widget.service['lastSeenLocation'];
    if (lastSeen is Map) {
      final name = _loc(lastSeen['name'], fallback: '');
      if (name.isNotEmpty) return name;
    }

    final targetId = widget.service['kebeleId']?.toString() ??
        widget.service['kebele']?.toString();
    if (targetId == null) return l10n.caseDetailLocationNotSet;

    try {
      final kebeles = await KebeleService().getAllKebeles();
      final match = kebeles.firstWhere(
        (k) =>
            k['id'].toString()  == targetId ||
            k['_id'].toString() == targetId,
        orElse: () => {},
      );
      return _plain(match['name'], fallback: l10n.caseDetailLocationNotSet);
    } catch (_) {
      return l10n.caseDetailLocationNotSet;
    }
  }

  // ── Status helpers ─────────────────────────────────────────────────────────
  Color _statusColor(String status) => switch (status) {
        'COMPLETED' => _T.green,
        'REJECTED'  => _T.red,
        _           => _T.orange,
      };

  IconData _statusIcon(String status) => switch (status) {
        'COMPLETED' => Icons.check_circle_outline_rounded,
        'REJECTED'  => Icons.cancel_outlined,
        _           => Icons.hourglass_top_rounded,
      };

  String _statusLabel(String status) => switch (status) {
        'COMPLETED' => l10n.statusCompleted,
        'REJECTED'  => l10n.statusRejected,
        'PENDING'   => l10n.statusPending,
        _           => status,
      };

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final s = widget.service;

    // Localised fields
    final String type     = _loc(s['serviceType'],     fallback: l10n.generalService);
    final String category = _loc(s['serviceCategory'], fallback: l10n.publicService);
    final String desc     = _loc(s['description'],     fallback: '—');
    final String street   = _loc(s['street'],          fallback: '—');

    // Plain fields
    final String status   = _plain(s['status'], fallback: 'PENDING').toUpperCase();
    final String imageUrl = _imageUrl(s['mediaUrl']);
    final String dateStr  = s['createdAt']?.toString().split('T')[0] ?? 'N/A';

    final sColor = _statusColor(status);
    final sIcon  = _statusIcon(status);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                imageUrl:    imageUrl,
                type:        type,
                category:    category,
                status:      status,
                sColor:      sColor,
                sIcon:       sIcon,
                statusLabel: _statusLabel(status),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kebele title
                    FutureBuilder<String>(
                      future: _resolveKebeleName(),
                      builder: (ctx, snap) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            snap.data ?? '…',
                            style: const TextStyle(
                              fontSize:      26,
                              fontWeight:    FontWeight.w800,
                              color:         _T.textDark,
                              letterSpacing: -0.5,
                              height:        1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type.toUpperCase(),
                            style: const TextStyle(
                              color:         _T.accent,
                              fontWeight:    FontWeight.w700,
                              fontSize:      11,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    _Divider(),
                    const SizedBox(height: 24),

                    // Description
                    _SectionLabel(l10n.caseDetailCaseDescription),
                    const SizedBox(height: 12),
                    Text(
                      desc,
                      style: const TextStyle(
                          fontSize: 15, height: 1.65, color: _T.textMid),
                    ),
                    const SizedBox(height: 28),

                    // Details card
                    _SectionLabel(l10n.serviceReportDetails),
                    const SizedBox(height: 12),
                    _InfoCard(rows: [
                      _InfoRowData(
                        icon:  Icons.location_on_rounded,
                        label: l10n.serviceStreetLabel,
                        value: street,
                      ),
                      _InfoRowData(
                        icon:  Icons.calendar_today_rounded,
                        label: l10n.serviceDateReported,
                        value: dateStr,
                      ),
                      _InfoRowData(
                        icon:  Icons.verified_user_outlined,
                        label: l10n.serviceSystemStatus,
                        value: l10n.serviceOfficialReport,
                      ),
                    ]),
                    const SizedBox(height: 28),

                    // Chat button
                    _ChatButton(
                      service: s,
                      userId:  widget.userId,
                      token:   widget.token,
                      label:   l10n.openChat,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero Header ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String   imageUrl;
  final String   type;
  final String   category;
  final String   status;
  final Color    sColor;
  final IconData sIcon;
  final String   statusLabel;

  const _Header({
    required this.imageUrl,
    required this.type,
    required this.category,
    required this.status,
    required this.sColor,
    required this.sIcon,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
              bottomLeft:  Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft:  Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: -40, right: -25,
                  child: _Blob(size: 140, color: Colors.white, opacity: 0.055),
                ),
                Positioned(
                  bottom: -18, left: -28,
                  child: _Blob(size: 105, color: _T.accent, opacity: 0.14),
                ),
                if (imageUrl.isNotEmpty)
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
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
                                    color: sColor.withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(sIcon, color: sColor, size: 12),
                                    const SizedBox(width: 5),
                                    Text(
                                      statusLabel,
                                      style: TextStyle(
                                        color:      sColor,
                                        fontSize:   10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.28),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: const TextStyle(
                            color:         Colors.white,
                            fontSize:      9,
                            fontWeight:    FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        type,
                        style: TextStyle(
                          color:      Colors.white.withOpacity(0.55),
                          fontSize:   12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────
class _InfoRowData {
  final IconData icon;
  final String   label;
  final String   value;
  const _InfoRowData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRowData> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color:        _T.surface,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: _T.divider),
        boxShadow: [
          BoxShadow(
            color:      _T.primary.withOpacity(0.06),
            blurRadius: 14,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _InfoRow(data: rows[i]),
            if (i < rows.length - 1)
              Container(height: 1, color: _T.divider),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final _InfoRowData data;
  const _InfoRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color:        _T.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: _T.primary, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: const TextStyle(
                    fontSize:      9,
                    fontWeight:    FontWeight.w700,
                    color:         _T.textMid,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  style: const TextStyle(
                    fontSize:   14,
                    fontWeight: FontWeight.w700,
                    color:      _T.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3, height: 14,
          decoration: BoxDecoration(
            color:        _T.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color:         _T.textMid,
            fontWeight:    FontWeight.w800,
            fontSize:      10,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: _T.divider);
}

// ─── Blob ─────────────────────────────────────────────────────────────────────
class _Blob extends StatelessWidget {
  final double size;
  final Color  color;
  final double opacity;
  const _Blob({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }
}

// ─── Chat Button ─────────────────────────────────────────────────────────────
class _ChatButton extends StatelessWidget {
  final Map<String, dynamic> service;
  final String userId;
  final String token;
  final String label;

  const _ChatButton({
    required this.service,
    required this.userId,
    required this.token,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            emergencyId: int.tryParse(service['_id'].toString()) ?? 0,
            token:       token,
            userId:      int.tryParse(userId) ?? 0,
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_T.primary, _T.primaryMid],
            begin:  Alignment.centerLeft,
            end:    Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color:      _T.primary.withOpacity(0.32),
              blurRadius: 16,
              offset:     const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color:         Colors.white,
                fontWeight:    FontWeight.w800,
                fontSize:      15,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}