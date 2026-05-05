import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/kebele_service.dart';
import '../../services/case_report_service.dart';

// ─── Design Tokens (mirrored from DashboardContent) ──────────────────────────
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
  static const red        = Color(0xFFEF4444);
}

class CaseReportPage extends StatefulWidget {
  final dynamic caseData;
  const CaseReportPage({super.key, required this.caseData});

  @override
  State<CaseReportPage> createState() => _CaseReportPageState();
}

class _CaseReportPageState extends State<CaseReportPage>
    with TickerProviderStateMixin {

  final _descriptionController = TextEditingController();
  final KebeleService _kebeleService = KebeleService();
  final CaseReportService _reportService = CaseReportService();

  List<Map<String, dynamic>> _kebeles = [];
  bool _isLoadingKebeles = true;
  bool _isSubmitting = false;

  DateTime? _selectedDateTime;
  int? _selectedKebeleId;

  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
        ..forward();
  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _loadKebeles();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────
  Future<void> _loadKebeles() async {
    try {
      final data = await _kebeleService.getAllKebeles();
      if (mounted) setState(() { _kebeles = data; _isLoadingKebeles = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingKebeles = false);
        _notify("Failed to fetch location data", isError: true);
      }
    }
  }

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _T.primary),
        ),
        child: child!,
      ),
    );
    if (date == null) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _T.primary),
        ),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() => _selectedDateTime = DateTime(
        date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _handleSubmission() async {
    if (_selectedKebeleId == null || _selectedDateTime == null) {
      _notify("Please select both location and time");
      return;
    }
    setState(() => _isSubmitting = true);

    final payload = {
      "caseId": widget.caseData['id'],
      "caseTypeId": widget.caseData['caseTypeId'],
      "kebeleId": _selectedKebeleId,
      "spottedAt": _selectedDateTime!.toIso8601String(),
      "description": _descriptionController.text,
      "reporterId": null,
    };

    final bool success = await _reportService.createReport(payload);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        final messenger = ScaffoldMessenger.of(context);
        FocusScope.of(context).unfocus();
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 100), () {
          messenger.showSnackBar(SnackBar(
            content: const Text("Sighting submitted successfully"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _T.green,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ));
        });
      } else {
        _notify("Submission failed. Please check connection.");
      }
    }
  }

  void _notify(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? _T.red : _T.green,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoadingKebeles
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: _T.primary, strokeWidth: 2))
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTargetCard(),
                            const SizedBox(height: 28),
                            _sectionLabel("Geographic Precision",
                                Icons.share_location_rounded),
                            const SizedBox(height: 10),
                            _buildCard(child: DropdownButtonFormField<int>(
                              value: _selectedKebeleId,
                              dropdownColor: _T.surface,
                              style: const TextStyle(
                                  color: _T.textDark, fontSize: 14),
                              items: _kebeles
                                  .map((k) => DropdownMenuItem<int>(
                                        value: k['id'],
                                        child: Text(k['name'] ?? "Unknown",
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: _T.textDark)),
                                      ))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedKebeleId = val),
                              decoration: _inputDeco(
                                  "Select current Kebele",
                                  Icons.location_on_rounded),
                            )),
                            const SizedBox(height: 20),
                            _sectionLabel(
                                "Time of Sighting", Icons.timer_outlined),
                            const SizedBox(height: 10),
                            _buildCard(
                              child: ListTile(
                                onTap: _pickDateTime,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                leading: Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    color: _T.accentSoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.calendar_month_rounded,
                                      color: _T.primary, size: 18),
                                ),
                                title: Text(
                                  _selectedDateTime == null
                                      ? "Select date & time"
                                      : DateFormat('MMMM dd, yyyy • hh:mm a')
                                          .format(_selectedDateTime!),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: _selectedDateTime == null
                                        ? FontWeight.w400
                                        : FontWeight.w700,
                                    color: _selectedDateTime == null
                                        ? _T.textMid
                                        : _T.textDark,
                                  ),
                                ),
                                trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: _T.textMid, size: 20),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _sectionLabel(
                                "Visual Description", Icons.visibility_outlined),
                            const SizedBox(height: 10),
                            _buildCard(
                              child: TextField(
                                controller: _descriptionController,
                                maxLines: 4,
                                style: const TextStyle(
                                    fontSize: 14, color: _T.textDark),
                                decoration: _inputDeco(
                                  "Clothing, companions, vehicle details...",
                                  Icons.edit_note_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),
                            _buildSubmitButton(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Custom Header (matches dashboard header style) ─────────────────────────
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
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(children: [
        Positioned(top: -30, right: -20, child: _blob(120, Colors.white, 0.05)),
        Positioned(bottom: -20, left: -20, child: _blob(90, _T.accent, 0.13)),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 20, 22),
            child: Row(children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
              // Icon + title
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.25), width: 1),
                ),
                child: const Icon(Icons.file_copy_rounded,
                    color: Colors.white, size: 17),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Intel Report",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3)),
                  Text("Submit a sighting",
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Target Card ────────────────────────────────────────────────────────────
  Widget _buildTargetCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2580), _T.primary, _T.primaryMid],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _T.primary.withOpacity(0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(children: [
        Positioned(top: -18, right: -18, child: _blob(90, Colors.white, 0.06)),
        Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.25), width: 1.5),
            ),
            child: const Icon(Icons.person_search_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Reporting Target",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0)),
              const SizedBox(height: 4),
              Text(
                widget.caseData['fullName']?.toString() ?? "Unknown Entity",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3),
              ),
            ]),
          ),
          // Status badge reused from dashboard
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.white.withOpacity(0.25), width: 1),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.circle, color: Color(0xFFFFD700), size: 7),
              SizedBox(width: 5),
              Text("Active",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      ]),
    );
  }

  // ── Submit Button ──────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return Column(children: [
      SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmission,
          style: ElevatedButton.styleFrom(
            backgroundColor: _T.primary,
            disabledBackgroundColor: _T.primary.withOpacity(0.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 10),
                    Text("Submit Report",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 0.3)),
                  ],
                ),
        ),
      ),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.verified_user_outlined,
            size: 13, color: _T.textMid),
        const SizedBox(width: 6),
        Text("Encrypted Service Protocol",
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _T.textMid)),
      ]),
    ]);
  }

  // ── Section Label (matches dashboard _sectionLabel) ───────────────────────
  Widget _sectionLabel(String title, IconData icon) {
    return Row(children: [
      Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
            color: _T.accentSoft,
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: _T.primary, size: 15),
      ),
      const SizedBox(width: 9),
      Text(title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _T.textDark,
              letterSpacing: -0.2)),
    ]);
  }

  // ── Card wrapper ───────────────────────────────────────────────────────────
  Widget _buildCard({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _T.divider),
          boxShadow: [
            BoxShadow(
                color: _T.primary.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: child,
      );

  // ── Input decoration ───────────────────────────────────────────────────────
  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: _T.textMid, fontSize: 13),
        prefixIcon: Icon(icon, color: _T.primary, size: 20),
        border: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      );

  // ── Blob (identical to dashboard) ─────────────────────────────────────────
  Widget _blob(double size, Color color, double opacity) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(opacity)));
}
