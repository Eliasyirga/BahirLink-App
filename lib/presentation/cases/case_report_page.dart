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

  Future<void> _loadKebeles() async {
    try {
      final data = await _kebeleService.getAllKebeles();
      setState(() {
        _kebeles = data;
        _isLoadingKebeles = false;
      });
    } catch (e) {
      setState(() => _isLoadingKebeles = false);
      _showSnackBar("Failed to load locations");
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2B7CFF)),
        ),
        child: child!,
      ),
    );
    if (date == null) return;

    final time = await showTimePicker(
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

  Future<void> _submitReport() async {
    if (_selectedKebeleId == null || _selectedDateTime == null) {
      _showSnackBar("Please fill in the location and time.");
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

    final success = await _reportService.createReport(payload);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        _showSnackBar("Report submitted successfully!", isError: false);
        Navigator.pop(context);
      } else {
        _showSnackBar("Failed to submit report.");
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Submit Sighting",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: _isLoadingKebeles
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2B7CFF)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCaseSummary(),
                  const SizedBox(height: 32),

                  _sectionHeader("WHERE WERE THEY SEEN?"),
                  const SizedBox(height: 12),
                  _buildCardWrapper(
                    child: DropdownButtonFormField<int>(
                      value: _selectedKebeleId,
                      icon: const Icon(Icons.expand_more_rounded),
                      items: _kebeles
                          .map(
                            (k) => DropdownMenuItem<int>(
                              value: k['id'],
                              child: Text(
                                k['name'],
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedKebeleId = val),
                      decoration: _inputDecoration(
                        "Select Location (Kebele)",
                        Icons.location_on_rounded,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _sectionHeader("WHEN DID THIS HAPPEN?"),
                  const SizedBox(height: 12),
                  _buildCardWrapper(
                    child: InkWell(
                      onTap: _pickDateTime,
                      borderRadius: BorderRadius.circular(15),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: Color(0xFF2B7CFF),
                              size: 20,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              _selectedDateTime == null
                                  ? "Choose date and time"
                                  : DateFormat(
                                      'MMM dd, yyyy • hh:mm a',
                                    ).format(_selectedDateTime!),
                              style: TextStyle(
                                fontSize: 15,
                                color: _selectedDateTime == null
                                    ? Colors.grey.shade500
                                    : Color(0xFF1E293B),
                                fontWeight: _selectedDateTime == null
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _sectionHeader("ADDITIONAL OBSERVATIONS"),
                  const SizedBox(height: 12),
                  _buildCardWrapper(
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 15),
                      decoration: _inputDecoration(
                        "Describe clothing, direction of travel, etc...",
                        Icons.notes_rounded,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  _buildSubmitButton(),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      "This report is encrypted and anonymous.",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCaseSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B7CFF), Color(0xFF0056D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B7CFF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_search_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "REPORTING FOR",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.caseData['title'] ?? "Active Case",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        onPressed: _isSubmitting ? null : _submitReport,
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "SUBMIT ANONYMOUS TIP",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Color(0xFF64748B),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
      hintStyle: TextStyle(color: Colors.grey.shade400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: InputBorder.none,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF2B7CFF), width: 1.5),
      ),
    );
  }
}
