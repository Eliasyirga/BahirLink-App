import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/kebele_service.dart';
import '../../services/case_report_service.dart';

class CaseReportPage extends StatefulWidget {
  final dynamic caseData;
  const CaseReportPage({super.key, required this.caseData});

  @override
  State<CaseReportPage> createState() => _CaseReportPageState();
}

class _CaseReportPageState extends State<CaseReportPage> {
  // Static constants fix the "withOpacity on undefined" JS error
  static const Color _primaryBlue = Color(0xFF2B7CFF);
  static const Color _darkSlate = Color(0xFF0F172A);
  static const Color _bgSlate = Color(0xFFF8FAFC);
  static const Color _borderGray = Color(0xFFE2E8F0);

  final _descriptionController = TextEditingController();
  final KebeleService _kebeleService = KebeleService();
  final CaseReportService _reportService = CaseReportService();

  List<Map<String, dynamic>> _kebeles = [];
  bool _isLoadingKebeles = true;
  bool _isSubmitting = false;

  DateTime? _selectedDateTime;
  int? _selectedKebeleId;

  @override
  void initState() {
    super.initState();
    _loadKebeles();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadKebeles() async {
    try {
      final data = await _kebeleService.getAllKebeles();
      if (mounted) {
        setState(() {
          _kebeles = data;
          _isLoadingKebeles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingKebeles = false);
        _triggerNotification("Failed to fetch location data", isError: true);
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
        data: Theme.of(
          context,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _primaryBlue)),
        child: child!,
      ),
    );
    if (date == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _handleSubmission() async {
    if (_selectedKebeleId == null || _selectedDateTime == null) {
      _triggerNotification("Please select both location and time");
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = {
      "caseId": widget.caseData['id'],
      "caseTypeId": widget.caseData['caseTypeId'],
      "kebeleId": _selectedKebeleId,
      "spottedAt": _selectedDateTime!.toIso8601String(),
      "description": _descriptionController.text,
      "reporterId": null, // Anonymous or profile-linked
    };

    final bool success = await _reportService.createReport(payload);

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (success) {
        // 1. Capture the messenger state before the widget is disposed by pop()
        final messenger = ScaffoldMessenger.of(context);

        // 2. Unfocus keyboard to prevent layout flicker
        FocusScope.of(context).unfocus();

        // 3. Pop the current page
        Navigator.pop(context);

        // 4. Delay the notification slightly so the animation runs on the NEW stable tree
        Future.delayed(const Duration(milliseconds: 100), () {
          messenger.showSnackBar(
            SnackBar(
              content: const Text("Sighting submitted successfully"),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green.shade800,
              margin: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        });
      } else {
        _triggerNotification("Submission failed. Please check connection.");
      }
    }
  }

  void _triggerNotification(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : _primaryBlue,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgSlate,
      appBar: AppBar(
        title: const Text(
          "INTEL REPORT",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _darkSlate,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingKebeles
          ? const Center(
              child: CircularProgressIndicator(
                color: _primaryBlue,
                strokeWidth: 2,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),

                  _label("GEOGRAPHIC PRECISION"),
                  const SizedBox(height: 10),
                  _cardWrapper(
                    child: DropdownButtonFormField<int>(
                      value: _selectedKebeleId,
                      items: _kebeles
                          .map(
                            (k) => DropdownMenuItem<int>(
                              value: k['id'],
                              child: Text(
                                k['name'] ?? "Unknown Kebele",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedKebeleId = val),
                      decoration: _inputStyle(
                        "Select current Kebele",
                        Icons.share_location_rounded,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _label("TIMESTAMPS"),
                  const SizedBox(height: 10),
                  _cardWrapper(
                    child: ListTile(
                      onTap: _pickDateTime,
                      leading: const Icon(
                        Icons.timer_outlined,
                        color: _primaryBlue,
                      ),
                      title: Text(
                        _selectedDateTime == null
                            ? "Select time of sighting"
                            : DateFormat(
                                'MMMM dd, yyyy • hh:mm a',
                              ).format(_selectedDateTime!),
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedDateTime == null
                              ? Colors.grey
                              : _darkSlate,
                          fontWeight: _selectedDateTime == null
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.calendar_month,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _label("VISUAL DESCRIPTION / CLUES"),
                  const SizedBox(height: 10),
                  _cardWrapper(
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 14),
                      decoration: _inputStyle(
                        "Clothing, companions, or vehicle details...",
                        Icons.visibility_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                  _buildSubmitButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _darkSlate,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _darkSlate.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "REPORTING TARGET",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.caseData['fullName']?.toString().toUpperCase() ??
                "UNKNOWN ENTITY",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSubmission,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "SECURE TRANSMISSION",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        const Opacity(
          opacity: 0.5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_outlined, size: 14),
              SizedBox(width: 8),
              Text(
                "Encrypted Service Protocol",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w900,
      color: Colors.grey,
      letterSpacing: 1.2,
    ),
  );

  Widget _cardWrapper({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _borderGray),
    ),
    child: child,
  );

  InputDecoration _inputStyle(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: _primaryBlue, size: 20),
    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
    border: InputBorder.none,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  );
}
