import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'map_picker_page.dart';
import '../../model/emergency_report_model.dart';
import '../../services/user_emergency_service.dart';
import '../../services/kebele_service.dart';
import 'media_picker_bottom_sheet.dart';

// ─── Dashboard Color Tokens ───────────────────────────────────────────────────
class _T {
  static const primary    = Color(0xFF1A3BAA);
  static const primaryMid = Color(0xFF2252CC);
  static const accent     = Color(0xFF4B83F0);
  static const accentSoft = Color(0xFFD6E4FF);
  static const bg         = Color(0xFFF2F6FF);
  static const textDark   = Color(0xFF0C1A45);
  static const textMid    = Color(0xFF5569A0);
  static const green      = Color(0xFF0DB87A);
}

class UserEmergencyReportPage extends StatefulWidget {
  final String emergencyTypeId;
  final String emergencyTypeName;
  final String categoryId;
  final String categoryName;

  const UserEmergencyReportPage({
    super.key,
    required this.emergencyTypeId,
    required this.emergencyTypeName,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<UserEmergencyReportPage> createState() =>
      _UserEmergencyReportPageState();
}

class _UserEmergencyReportPageState extends State<UserEmergencyReportPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _subdivisionController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final KebeleService _kebeleService = KebeleService();

  List<Map<String, dynamic>> _kebeles = [];
  int? _selectedKebeleId;
  bool _isLoadingKebeles = true;

  double? _latitude;
  double? _longitude;
  DateTime? _selectedTime;

  Uint8List? _selectedMediaBytes;
  File? _selectedFile;
  String? _selectedFileName;

  bool _isLoading = false;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _fetchUserId();
    _fetchKebeles();
  }

  Future<void> _fetchUserId() async {
    final id = await UserEmergencyService.getUserId();
    int? parsedId;
    if (id != null) {
      parsedId = id is int ? id : int.tryParse(id.toString());
    }
    if (parsedId != null) {
      setState(() => _userId = parsedId);
    } else {
      _showSnack("Failed to fetch user ID", isError: true);
    }
  }

  Future<void> _fetchKebeles() async {
    try {
      final fetched = await _kebeleService.getAllKebeles();
      setState(() {
        _kebeles = fetched;
        _isLoadingKebeles = false;
      });
    } catch (e) {
      setState(() => _isLoadingKebeles = false);
      _showSnack("Error loading locations", isError: true);
    }
  }

  void _showSnack(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFEF4444) : _T.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _subdivisionController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = DateTime(
            now.year, now.month, now.day, picked.hour, picked.minute);
      });
    }
  }

  void _pickMedia() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => MediaPickerBottomSheet(
        onFileSelectedWeb: (bytes, name) {
          setState(() {
            _selectedMediaBytes = bytes;
            _selectedFileName = name;
            _selectedFile = null;
          });
        },
        onFileSelectedMobile: (file) {
          setState(() {
            _selectedFile = file;
            _selectedFileName = file.path.split("/").last;
            _selectedMediaBytes = null;
          });
        },
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_descriptionController.text.isEmpty ||
        _selectedKebeleId == null ||
        _subdivisionController.text.isEmpty) {
      _showSnack("Please fill description, select a kebele, and subdivision");
      return;
    }
    if (_userId == null) {
      _showSnack("Fetching user ID. Please wait...");
      return;
    }

    setState(() => _isLoading = true);

    final report = EmergencyReportModel(
      emergencyTypeId: widget.emergencyTypeId,
      categoryId: widget.categoryId,
      description: _descriptionController.text,
      userId: _userId!,
      kebele: _selectedKebeleId.toString(),
      subdivision: _subdivisionController.text,
      street: _streetController.text,
      latitude: _latitude,
      longitude: _longitude,
      time: _selectedTime ?? DateTime.now(),
      mediaUrl: null,
      mediaType: null,
    );

    final success = await UserEmergencyService.sendUserEmergency(
      userId: _userId!,
      report: report,
      mediaBytes: _selectedMediaBytes,
      mediaFile: _selectedFile,
      mediaName: _selectedFileName,
    );

    setState(() => _isLoading = false);

    _showSnack(
      success ? "Report Sent Successfully" : "Failed to Send Report",
      isError: !success,
    );

    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _T.bg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: _buildForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
        width: double.infinity,
        padding: const EdgeInsets.only(
            top: 60, bottom: 30, left: 20, right: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D2580), _T.primary, _T.primaryMid],
            stops: [0.0, 0.5, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.emergencyTypeName,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Text(
                    widget.categoryName,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("Description"),
        const SizedBox(height: 10),
        _buildTextField(
          _descriptionController,
          "Explain what is happening...",
          maxLines: 4,
          icon: Icons.edit_note,
        ),
        const SizedBox(height: 24),
        _sectionHeader("Location Details"),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: _T.primary.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isLoadingKebeles
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _T.primary),
                  ),
                )
              : DropdownButtonFormField<int>(
                  value: _selectedKebeleId,
                  hint: Text(
                    "Select Kebele",
                    style: TextStyle(color: _T.textMid.withOpacity(0.6)),
                  ),
                  icon: const Icon(Icons.arrow_drop_down, color: _T.accent),
                  decoration: const InputDecoration(
                    prefixIcon:
                        Icon(Icons.maps_home_work, color: _T.accent, size: 20),
                    border: InputBorder.none,
                  ),
                  items: _kebeles.map((kebele) {
                    return DropdownMenuItem<int>(
                      value: kebele['id'],
                      child: Text(
                        kebele['name'] ?? "Unknown",
                        style: const TextStyle(color: _T.textDark),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedKebeleId = value),
                ),
        ),
        const SizedBox(height: 12),
        _buildTextField(_subdivisionController, "Subdivision",
            icon: Icons.business),
        const SizedBox(height: 12),
        _buildTextField(_streetController, "Street (Optional)",
            icon: Icons.add_road),
        const SizedBox(height: 24),
        _sectionHeader("Time & GPS"),
        const SizedBox(height: 10),
        _buildPickerRow(
          icon: Icons.access_time_filled,
          label: "Report Time",
          value: _selectedTime != null
              ? "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}"
              : "Select Time",
          onTap: _pickTime,
        ),
        const SizedBox(height: 12),
        _buildPickerRow(
          icon: Icons.my_location,
          label: "Pin Location",
          value: _latitude != null ? "Location Pinned" : "Tap to open map",
          valueColor: _latitude != null ? _T.green : null,
          onTap: () async {
            final pickedLocation = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapPickerPage()),
            );
            if (pickedLocation != null) {
              setState(() {
                _latitude = pickedLocation.latitude;
                _longitude = pickedLocation.longitude;
              });
            }
          },
        ),
        const SizedBox(height: 24),
        _sectionHeader("Evidence"),
        const SizedBox(height: 10),
        _buildPickerRow(
          icon: Icons.cloud_upload,
          label: "Media Attachment",
          value: _selectedFileName ?? "Upload Photo/Video",
          valueColor: _selectedFileName != null ? _T.green : null,
          onTap: _pickMedia,
        ),
        const SizedBox(height: 40),
        _buildSubmitButton(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _sectionHeader(String title) => Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: _T.primary.withOpacity(0.6),
          letterSpacing: 1.5,
        ),
      );

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    required IconData icon,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: _T.primary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: _T.textDark),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.edit_note, color: _T.accent, size: 20),
            hintText: hint,
            hintStyle: TextStyle(color: _T.textMid.withOpacity(0.6)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
          ),
        ),
      );

  Widget _buildPickerRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _T.primary.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: _T.accent),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: _T.textDark),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? _T.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right,
                  color: _T.primary.withOpacity(0.3)),
            ],
          ),
        ),
      );

  Widget _buildSubmitButton() => Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: _T.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _T.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            elevation: 0,
          ),
          onPressed: _isLoading ? null : _submitReport,
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  "SUBMIT REPORT",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2),
                ),
        ),
      );
}