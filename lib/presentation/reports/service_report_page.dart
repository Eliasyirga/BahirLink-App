import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:first_app/l10n/app_localizations.dart';
import '../../services/service_report_service.dart';
import 'service_report_detail_page.dart';

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

class ServiceReportPage extends StatefulWidget {
  final String userId;
  final String token;

  const ServiceReportPage(
      {super.key, required this.userId, required this.token});

  @override
  State<ServiceReportPage> createState() => _ServiceReportPageState();
}

class _ServiceReportPageState extends State<ServiceReportPage>
    with TickerProviderStateMixin {

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  final ServiceReportService _apiService = ServiceReportService();
  List<dynamic> _services = [];
  bool _loading = true;
  String? _error;

  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _apiService.getUserServices(widget.userId);
      if (mounted) {
        setState(() { _services = result; _loading = false; });
        _fadeCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _loading = false; });
      }
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return "N/A";
    try {
      final dt = DateTime.parse(dateStr.toString());
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return "N/A";
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: _loading
            ? _buildSplash()
            : FadeTransition(
                opacity: _fadeAnim,
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  color: _T.primary,
                  displacement: 20,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader()),
                      if (_error != null)
                        SliverToBoxAdapter(child: _buildErrorState())
                      else if (_services.isEmpty)
                        SliverFillRemaining(child: _buildEmptyState())
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => _buildCard(_services[i], i),
                              childCount: _services.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

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
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
      ),
    );
  }

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
        Positioned(top: 14, right: 85,   child: _blob(55,  Colors.white, 0.045)),
        Positioned(bottom: -18, left: -28, child: _blob(105, _T.accent, 0.14)),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.11),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2), width: 1),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _loadData,
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
                const SizedBox(height: 22),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.myPublic,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.62),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 3),
                        Text(l10n.serviceReports,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                height: 1.1)),
                      ],
                    ),
                  ),
                  if (!_loading && _error == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.11),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2), width: 1),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(
                                color: _T.green, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text(
                          l10n.reportsCount(_services.length.toString()),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ]),
                    ),
                ]),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _blob(double size, Color color, double opacity) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: color.withOpacity(opacity)));

  Widget _buildCard(dynamic service, int index) {
    final typeName     = service['serviceType']?['name']     ?? l10n.generalService;
    final categoryName = service['serviceCategory']?['name'] ?? l10n.publicService;
    final rawStatus    = (service['status'] ?? 'Pending').toString().toUpperCase();
    final date         = _formatDate(service['createdAt']);

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (rawStatus == 'COMPLETED') {
      statusColor = _T.green;
      statusIcon  = Icons.check_circle_outline_rounded;
      statusLabel = l10n.statusCompleted;
    } else if (rawStatus == 'REJECTED') {
      statusColor = _T.red;
      statusIcon  = Icons.cancel_outlined;
      statusLabel = l10n.statusRejected;
    } else {
      statusColor = _T.orange;
      statusIcon  = Icons.hourglass_top_rounded;
      statusLabel = l10n.statusPending;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 80),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)), child: child),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceReportDetailPage(
              service: service,
              userId: widget.userId,
              token: widget.token,
            ),
          ),
        ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _categoryBadge(categoryName.toUpperCase()),
                  const Spacer(),
                  _statusChip(statusLabel, statusColor, statusIcon),
                ]),
                const SizedBox(height: 14),
                Text(typeName,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _T.textDark,
                        letterSpacing: -0.2)),
                const SizedBox(height: 14),
                Container(height: 1, color: _T.divider),
                const SizedBox(height: 12),
                Row(children: [
                  Row(children: [
                    const Icon(Icons.access_time_rounded,
                        size: 12, color: _T.textMid),
                    const SizedBox(width: 5),
                    Text(date,
                        style: const TextStyle(
                            color: _T.textMid,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ]),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: _T.accentSoft,
                        borderRadius: BorderRadius.circular(7)),
                    child: Row(children: [
                      const Icon(Icons.open_in_new_rounded,
                          size: 11, color: _T.accent),
                      const SizedBox(width: 5),
                      Text(l10n.viewDetails,
                          style: const TextStyle(
                              color: _T.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: _T.accentSoft, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: const TextStyle(
              color: _T.primary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4)),
    );
  }

  Widget _statusChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3)),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
              color: _T.accentSoft,
              borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.inventory_2_outlined,
              size: 36, color: _T.primary),
        ),
        const SizedBox(height: 18),
        Text(l10n.noReportsYet,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _T.textDark)),
        const SizedBox(height: 6),
        Text(l10n.noReportsSubtitle,
            style: const TextStyle(fontSize: 13, color: _T.textMid)),
      ]),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
              color: _T.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.error_outline_rounded,
              color: _T.red, size: 30),
        ),
        const SizedBox(height: 14),
        Text(l10n.failedToLoad,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: _T.textDark)),
        const SizedBox(height: 8),
        Text(_error ?? "",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: _T.textMid)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _loadData,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_T.primary, _T.primaryMid]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(l10n.tryAgain,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
        ),
      ]),
    );
  }
}