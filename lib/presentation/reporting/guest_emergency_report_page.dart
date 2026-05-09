import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'map_picker_page.dart';
import '../../services/emergency_service.dart';
import '../../services/kebele_service.dart';
import '../../services/device_service.dart';
import 'media_picker_bottom_sheet.dart';
import '../../l10n/app_localizations.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
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

class GuestEmergencyReportPage extends StatefulWidget {
  final String emergencyTypeId;
  final String categoryId;
  final String emergencyTypeName;
  final String categoryName;

  const GuestEmergencyReportPage({
    super.key,
    required this.emergencyTypeId,
    required this.categoryId,
    required this.emergencyTypeName,
    required this.categoryName,
  });

  @override
  State<GuestEmergencyReportPage> createState() =>
      _GuestEmergencyReportPageState();
}

class _GuestEmergencyReportPageState extends State<GuestEmergencyReportPage> {
  // ── l10n shortcut ──────────────────────────────────────────────────────────
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  // ── Controllers ────────────────────────────────────────────────────────────
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController       = TextEditingController();
  final TextEditingController _subdivisionController = TextEditingController();
  final TextEditingController _streetController      = TextEditingController();
  final KebeleService _kebeleService = KebeleService();

  // ── Kebele state ───────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _kebeles = [];
  String? _selectedKebeleId;
  bool    _isLoadingKebeles = true;

  // ── Location / time / media ────────────────────────────────────────────────
  double?   _latitude;
  double?   _longitude;
  DateTime? _selectedTime;

  Uint8List? _selectedMediaBytes;
  File?      _selectedFile;
  String?    _selectedFileName;

  // ── General state ──────────────────────────────────────────────────────────
  bool   _isLoading   = false;
  String _currentLang = 'en';

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadLang();
    _fetchKebeles();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _phoneController.dispose();
    _subdivisionController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  // ── Read persisted language ────────────────────────────────────────────────
  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language_code') ?? 'en';
    if (mounted) setState(() => _currentLang = saved);
  }

  // ── Kebele fetch ───────────────────────────────────────────────────────────
  Future<void> _fetchKebeles() async {
    try {
      final fetched = await _kebeleService.getAllKebeles();
      if (mounted) {
        setState(() {
          _kebeles          = fetched ?? [];
          _isLoadingKebeles = false;
        });
      }
    } catch (e) {
      debugPrint("Kebele Fetch Error: $e");
      if (mounted) {
        setState(() => _isLoadingKebeles = false);
        _showSnack(l10n.reportErrorLoadingLocations, isError: true);
      }
    }
  }

  // ── Snack helper ───────────────────────────────────────────────────────────
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

  // ── Time picker ────────────────────────────────────────────────────────────
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

  // ── Media picker ───────────────────────────────────────────────────────────
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
            _selectedFileName   = name;
            _selectedFile       = null;
          });
        },
        onFileSelectedMobile: (file) {
          setState(() {
            _selectedFile       = file;
            _selectedFileName   = file.path.split("/").last;
            _selectedMediaBytes = null;
          });
        },
      ),
    );
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submitReport() async {
    if (_descriptionController.text.isEmpty ||
        _selectedKebeleId == null ||
        _subdivisionController.text.isEmpty) {
      _showSnack(l10n.reportValidationError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final deviceId = await DeviceService.getDeviceId();

      final res = await EmergencyService.createGuestEmergency(
        contactNo:       _phoneController.text,
        kebele:          _selectedKebeleId!,
        subdivision:     _subdivisionController.text,
        street:          _streetController.text,
        description:     _descriptionController.text,
        emergencyTypeId: widget.emergencyTypeId,
        categoryId:      widget.categoryId,
        latitude:        _latitude,
        longitude:       _longitude,
        time:            _selectedTime?.toIso8601String(),
        mediaBytes:      _selectedMediaBytes,
        mediaFile:       _selectedFile,
        mediaName:       _selectedFileName,
        deviceId:        deviceId,
        lang:            _currentLang,
      );

      if (mounted) {
        _showSnack(
          res['success'] == true ? l10n.reportSentSuccess : l10n.reportSentFailed,
          isError: res['success'] != true,
        );
        if (res['success'] == true) Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
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
                  topLeft:  Radius.circular(30),
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

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D2580), _T.primary, _T.primaryMid],
            stops:  [0.0, 0.5, 1.0],
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
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

  // ── Form ───────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Description ──────────────────────────────────────────────────────
        _sectionHeader(l10n.reportSectionDescription),
        const SizedBox(height: 10),
        _buildTextField(
          _descriptionController,
          l10n.reportDescriptionHint,
          maxLines: 4,
          icon: Icons.edit_note,
        ),
        const SizedBox(height: 24),

        // ── Contact ──────────────────────────────────────────────────────────
        _sectionHeader(l10n.guestContactSection),
        const SizedBox(height: 10),
        _buildTextField(
          _phoneController,
          l10n.guestContactPhone,
          icon: Icons.phone_android,
          keyboard: TextInputType.phone,
        ),
        const SizedBox(height: 24),

        // ── Location ─────────────────────────────────────────────────────────
        _sectionHeader(l10n.reportSectionLocation),
        const SizedBox(height: 10),
        _buildKebeleDropdown(),
        const SizedBox(height: 12),
        _buildTextField(
          _subdivisionController,
          l10n.reportSubdivisionHint,
          icon: Icons.business,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          _streetController,
          l10n.reportStreetHint,
          icon: Icons.add_road,
        ),
        const SizedBox(height: 24),

        // ── Time & GPS ───────────────────────────────────────────────────────
        _sectionHeader(l10n.reportSectionTimeGps),
        const SizedBox(height: 10),
        _buildPickerRow(
          icon:  Icons.access_time_filled,
          label: l10n.reportTimeLabel,
          value: _selectedTime != null
              ? "${_selectedTime!.hour.toString().padLeft(2, '0')}:"
                "${_selectedTime!.minute.toString().padLeft(2, '0')}"
              : l10n.reportSelectTime,
          onTap: _pickTime,
        ),
        const SizedBox(height: 12),
        _buildPickerRow(
          icon:       Icons.my_location,
          label:      l10n.reportPinLocation,
          value:      _latitude != null
              ? l10n.reportLocationPinned
              : l10n.reportTapToOpenMap,
          valueColor: _latitude != null ? _T.green : null,
          onTap: () async {
            final picked = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapPickerPage()),
            );
            if (picked != null) {
              setState(() {
                _latitude  = picked.latitude;
                _longitude = picked.longitude;
              });
            }
          },
        ),
        const SizedBox(height: 24),

        // ── Evidence ─────────────────────────────────────────────────────────
        _sectionHeader(l10n.reportSectionEvidence),
        const SizedBox(height: 10),
        _buildPickerRow(
          icon:       Icons.cloud_upload,
          label:      l10n.reportMediaAttachment,
          value:      _selectedFileName ?? l10n.reportUploadPhotoVideo,
          valueColor: _selectedFileName != null ? _T.green : null,
          onTap:      _pickMedia,
        ),
        const SizedBox(height: 40),

        _buildSubmitButton(),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Kebele dropdown ────────────────────────────────────────────────────────
  Widget _buildKebeleDropdown() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color:     _T.primary.withOpacity(0.05),
              blurRadius: 10,
              offset:    const Offset(0, 4),
            ),
          ],
        ),
        child: _isLoadingKebeles
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _T.primary),
                ),
              )
            : DropdownButtonFormField<String>(
                value: _selectedKebeleId,
                hint: Text(
                  l10n.reportSelectKebele,
                  style: TextStyle(color: _T.textMid.withOpacity(0.6)),
                ),
                icon: const Icon(Icons.arrow_drop_down, color: _T.accent),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.maps_home_work,
                      color: _T.accent, size: 20),
                  border: InputBorder.none,
                ),
                items: _kebeles.map((k) {
                  return DropdownMenuItem<String>(
                    value: k['id']?.toString(),
                    child: Text(
                      k['name'] ?? "Unknown",
                      style: const TextStyle(color: _T.textDark),
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedKebeleId = val),
              ),
      );

  // ── Reusable widgets ───────────────────────────────────────────────────────
  Widget _sectionHeader(String title) => Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize:      12,
          fontWeight:    FontWeight.w800,
          color:         _T.primary.withOpacity(0.6),
          letterSpacing: 1.5,
        ),
      );

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int       maxLines = 1,
    required  IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color:     _T.primary.withOpacity(0.05),
              blurRadius: 10,
              offset:    const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller:   controller,
          maxLines:     maxLines,
          keyboardType: keyboard,
          style: const TextStyle(color: _T.textDark),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: _T.accent, size: 20),
            hintText:   hint,
            hintStyle:  TextStyle(color: _T.textMid.withOpacity(0.6)),
            filled:     true,
            fillColor:  Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide:   BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
          ),
        ),
      );

  Widget _buildPickerRow({
    required IconData     icon,
    required String       label,
    required String       value,
    Color?                valueColor,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(15),
            border:       Border.all(color: _T.primary.withOpacity(0.1)),
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
                  color:      valueColor ?? _T.accent,
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
        width:  double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color:     _T.primary.withOpacity(0.3),
              blurRadius: 12,
              offset:    const Offset(0, 6),
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
                  width:  24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  l10n.reportSubmitButton,
                  style: const TextStyle(
                      fontSize:      16,
                      fontWeight:    FontWeight.bold,
                      letterSpacing: 1.2),
                ),
        ),
      );
}