import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'map_picker_page.dart';
import '../../model/emergency_report_model.dart';
import '../../services/user_emergency_service.dart';
import '../../services/kebele_service.dart';
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
  static const orange     = Color(0xFFF59E0B);
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
  // ── l10n shortcut ──────────────────────────────────────────────────────────
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  // ── Controllers ────────────────────────────────────────────────────────────
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _subdivisionController = TextEditingController();
  final TextEditingController _streetController      = TextEditingController();
  final KebeleService _kebeleService = KebeleService();

  // ── Kebele state ───────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _kebeles = [];
  int?  _selectedKebeleId;
  bool  _isLoadingKebeles = true;

  // ── Location / time / media ────────────────────────────────────────────────
  // These hold the raw values picked from MapPickerPage.
  // They are passed DIRECTLY to UserEmergencyService as named parameters
  // and are intentionally NOT passed into EmergencyReportModel, so there
  // is only one code-path that writes latitude/longitude into the request.
  double?   _latitude;
  double?   _longitude;
  DateTime? _selectedTime;

  Uint8List? _selectedMediaBytes;
  File?      _selectedFile;
  String?    _selectedFileName;

  // ── General state ──────────────────────────────────────────────────────────
  bool _isLoading = false;
  int? _userId;

  /// Synced with the global language switcher via SharedPreferences.
  String _currentLang = 'en';

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initLangThenLoad();
    _fetchUserId();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _subdivisionController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  // ── Load lang first, then fetch Kebeles with the correct lang ──────────────
  Future<void> _initLangThenLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language_code') ?? 'en';
    if (mounted) setState(() => _currentLang = saved);
    await _fetchKebeles(lang: saved);
  }

  // ── Fetch helpers ──────────────────────────────────────────────────────────
  Future<void> _fetchUserId() async {
    final id = await UserEmergencyService.getUserId();
    int? parsedId;
    if (id != null) {
      parsedId = id is int ? id : int.tryParse(id.toString());
    }
    if (mounted) {
      if (parsedId != null) {
        setState(() => _userId = parsedId);
      } else {
        _showSnack(l10n.reportFailedUserId, isError: true);
      }
    }
  }

  Future<void> _fetchKebeles({String? lang}) async {
    final useLang = lang ?? _currentLang;
    try {
      final fetched = await _kebeleService.getAllKebeles();
      if (!mounted) return;
      setState(() {
        _kebeles = fetched.map((k) {
          final rawName = k['name'];
          String displayName;
          if (rawName is Map) {
            displayName = rawName[useLang]?.toString() ??
                rawName['en']?.toString() ??
                rawName.values.first?.toString() ??
                'Unknown';
          } else {
            displayName = rawName?.toString() ?? 'Unknown';
          }
          return {...k, 'displayName': displayName};
        }).toList();
        _isLoadingKebeles = false;
      });
    } catch (_) {
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

  // ── Time / media pickers ───────────────────────────────────────────────────
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
    if (_userId == null) {
      _showSnack(l10n.reportFetchingUserId);
      return;
    }

    setState(() => _isLoading = true);

    // ── Build model WITHOUT lat/lng ────────────────────────────────────────
    // Coordinates are intentionally omitted from the model so they don't
    // end up in toJsonForUser() and conflict with the named params below.
    // The service is the single place that writes latitude/longitude into
    // the multipart request.
    final report = EmergencyReportModel(
      emergencyTypeId: widget.emergencyTypeId,
      categoryId:      widget.categoryId,
      description:     _descriptionController.text, // backend auto-translates
      userId:          _userId!,
      kebele:          _selectedKebeleId.toString(),
      subdivision:     _subdivisionController.text,  // backend auto-translates
      street:          _streetController.text,
      latitude:        null,   // ← always null here; sent via named param
      longitude:       null,   // ← always null here; sent via named param
      time:            _selectedTime ?? DateTime.now(),
      mediaUrl:        null,
      mediaType:       null,
    );

    // ── Send — coordinates flow through named params only ──────────────────
    final success = await UserEmergencyService.sendUserEmergency(
      userId:     _userId!,
      report:     report,
      latitude:   _latitude,    // from MapPickerPage result
      longitude:  _longitude,   // from MapPickerPage result
      mediaBytes: _selectedMediaBytes,
      mediaFile:  _selectedFile,
      mediaName:  _selectedFileName,
      lang:       _currentLang,
    );

    if (mounted) setState(() => _isLoading = false);

    if (mounted) {
      _showSnack(
        success ? l10n.reportSentSuccess : l10n.reportSentFailed,
        isError: !success,
      );
      if (success) Navigator.pop(context);
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
        padding: const EdgeInsets.only(
            top: 60, bottom: 30, left: 20, right: 20),
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
                        fontSize:   24,
                        fontWeight: FontWeight.bold,
                        color:      Colors.white),
                  ),
                  Text(
                    widget.categoryName,
                    style: TextStyle(
                        fontSize:      14,
                        color:         Colors.white.withOpacity(0.8),
                        letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
            // ── Language indicator chip ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.translate_rounded,
                    color: Colors.white, size: 12),
                const SizedBox(width: 5),
                Text(
                  _currentLang == 'am' ? 'አማርኛ' : 'English',
                  style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   10,
                      fontWeight: FontWeight.w700),
                ),
              ]),
            ),
          ],
        ),
      );

  // ── Form ───────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    final isAm = _currentLang == 'am';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLangBanner(isAm),
        const SizedBox(height: 20),

        // ── Description ────────────────────────────────────────────────────
        _sectionHeader(l10n.reportSectionDescription),
        const SizedBox(height: 10),
        _buildTextField(
          _descriptionController,
          isAm
              ? 'ምን እየተፈጠረ እንደሆነ ያስረዱ...'
              : l10n.reportDescriptionHint,
          maxLines: 4,
          icon: Icons.edit_note,
        ),
        const SizedBox(height: 24),

        // ── Location Details ───────────────────────────────────────────────
        _sectionHeader(l10n.reportSectionLocation),
        const SizedBox(height: 10),
        _buildKebeleDropdown(),
        const SizedBox(height: 12),
        _buildTextField(
          _subdivisionController,
          isAm ? 'ክፍለ ከተማ' : l10n.reportSubdivisionHint,
          icon: Icons.business,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          _streetController,
          isAm ? 'መንገድ (አማራጭ)' : l10n.reportStreetHint,
          icon: Icons.add_road,
        ),
        const SizedBox(height: 24),

        // ── Time & GPS ─────────────────────────────────────────────────────
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

        // ── GPS pin row ────────────────────────────────────────────────────
        // Shows green "Location pinned" with coordinates when set,
        // otherwise prompts the user to tap and open the map.
        _buildPickerRow(
          icon:  Icons.my_location,
          label: l10n.reportPinLocation,
          value: _latitude != null && _longitude != null
              ? "${l10n.reportLocationPinned} "
                "(${_latitude!.toStringAsFixed(4)}, "
                "${_longitude!.toStringAsFixed(4)})"
              : l10n.reportTapToOpenMap,
          valueColor: _latitude != null ? _T.green : null,
          onTap: () async {
            final pickedLocation = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapPickerPage()),
            );
            // MapPickerPage must return an object with .latitude / .longitude.
            // We store both in state; they travel to the service as named params.
            if (pickedLocation != null) {
              setState(() {
                _latitude  = pickedLocation.latitude;
                _longitude = pickedLocation.longitude;
              });
              debugPrint(
                "📍 Location picked: lat=${pickedLocation.latitude}, "
                "lng=${pickedLocation.longitude}",
              );
            }
          },
        ),
        const SizedBox(height: 24),

        // ── Evidence ───────────────────────────────────────────────────────
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

  // ── Language notice banner ─────────────────────────────────────────────────
  Widget _buildLangBanner(bool isAm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        _T.accentSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.accent.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.translate_rounded, color: _T.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAm
                  ? 'በአማርኛ ወይም በእንግሊዘኛ መጻፍ ይችላሉ — ሁለቱም ቋንቋዎች ራስ-ሰር ይተረጎማሉ።'
                  : 'You can write in English or Amharic — both are auto-translated.',
              style: const TextStyle(
                  fontSize:   12,
                  color:      _T.primary,
                  fontWeight: FontWeight.w600,
                  height:     1.4),
            ),
          ),
        ],
      ),
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
              color:      _T.primary.withOpacity(0.05),
              blurRadius: 10,
              offset:     const Offset(0, 4),
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
                  l10n.reportSelectKebele,
                  style: TextStyle(color: _T.textMid.withOpacity(0.6)),
                ),
                icon: const Icon(Icons.arrow_drop_down, color: _T.accent),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.maps_home_work,
                      color: _T.accent, size: 20),
                  border: InputBorder.none,
                ),
                items: _kebeles.map((kebele) {
                  return DropdownMenuItem<int>(
                    value: kebele['id'] as int?,
                    child: Text(
                      kebele['displayName']?.toString() ?? 'Unknown',
                      style: const TextStyle(color: _T.textDark),
                    ),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedKebeleId = value),
              ),
      );

  // ── Widgets ────────────────────────────────────────────────────────────────
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
  }) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color:      _T.primary.withOpacity(0.05),
              blurRadius: 10,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          maxLines:   maxLines,
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
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color:        Colors.white,
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
                      fontWeight: FontWeight.w600,
                      color:      _T.textDark),
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  overflow:   TextOverflow.ellipsis,
                  textAlign:  TextAlign.end,
                  style: TextStyle(
                    color:      valueColor ?? _T.accent,
                    fontWeight: FontWeight.bold,
                    fontSize:   12,
                  ),
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
              color:      _T.primary.withOpacity(0.3),
              blurRadius: 12,
              offset:     const Offset(0, 6),
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
                  height: 24, width: 24,
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