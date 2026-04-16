import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'map_picker_page.dart';
import '../../model/service_report_model.dart';
import '../../services/user_service_service.dart';
import '../../services/kebele_service.dart';
import 'media_picker_bottom_sheet.dart';

class UserServiceReportPage extends StatefulWidget {
  final String serviceTypeId;
  final String categoryId;
  final String categoryName;

  // ✅ FIXED: Constructor name now matches the Class name
  const UserServiceReportPage({
    super.key,
    required this.serviceTypeId,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<UserServiceReportPage> createState() => _UserServiceReportPageState();
}

class _UserServiceReportPageState extends State<UserServiceReportPage> {
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

  // Vibrant Blue Palette
  final Color primaryBlue = const Color(0xFF1D4ED8);
  final Color accentBlue = const Color(0xFF3B82F6);
  final Color lightBlueBg = const Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _fetchUserId();
    _fetchKebeles();
  }

  Future<void> _fetchUserId() async {
    final id = await UserServiceService.getUserId();
    if (!mounted) return;

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
      if (!mounted) return;
      setState(() {
        _kebeles = fetched;
        _isLoadingKebeles = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingKebeles = false);
      _showSnack("Error loading locations", isError: true);
    }
  }

  void _showSnack(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : Colors.green,
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
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
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

    final report = ServiceReportModel(
      serviceTypeId: widget.serviceTypeId,
      serviceCategoryId: widget.categoryId,
      description: _descriptionController.text,
      citizenId: _userId!,
      kebeleId: _selectedKebeleId!,
      subdivision: _subdivisionController.text,
      street: _streetController.text,
      latitude: _latitude,
      longitude: _longitude,
      time: _selectedTime ?? DateTime.now(),
    );

    final success = await UserServiceService.sendUserService(
      userId: _userId!,
      report: report,
      mediaBytes: _selectedMediaBytes,
      mediaFile: _selectedFile,
      mediaName: _selectedFileName,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    _showSnack(
      success ? "Service Request Sent Successfully" : "Failed to Send Request",
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
                color: lightBlueBg,
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
    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [primaryBlue, accentBlue],
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
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Service Request",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                widget.categoryName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
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
          "Describe the required service...",
          maxLines: 4,
          icon: Icons.description_outlined,
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
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isLoadingKebeles
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : DropdownButtonFormField<int>(
                  value: _selectedKebeleId,
                  hint: const Text("Select Kebele"),
                  icon: Icon(Icons.keyboard_arrow_down, color: primaryBlue),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.location_city,
                      size: 20,
                      color: Color(0xFF1D4ED8),
                    ),
                    border: InputBorder.none,
                  ),
                  items: _kebeles
                      .map(
                        (k) => DropdownMenuItem<int>(
                          value: k['id'],
                          child: Text(k['name']),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedKebeleId = val),
                ),
        ),

        const SizedBox(height: 12),
        _buildTextField(
          _subdivisionController,
          "Subdivision / Village",
          icon: Icons.home_work_outlined,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          _streetController,
          "Street (Optional)",
          icon: Icons.signpost_outlined,
        ),
        const SizedBox(height: 24),
        _sectionHeader("Schedule & GPS"),
        const SizedBox(height: 10),
        _buildPickerRow(
          icon: Icons.calendar_today,
          label: "Request Time",
          value: _selectedTime != null
              ? "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}"
              : "Set Time",
          onTap: _pickTime,
        ),
        const SizedBox(height: 12),
        _buildPickerRow(
          icon: Icons.map_outlined,
          label: "Mark Location",
          value: _latitude != null ? "Pinned" : "Open Map",
          onTap: () async {
            final loc = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapPickerPage()),
            );
            if (loc != null)
              setState(() {
                _latitude = loc.latitude;
                _longitude = loc.longitude;
              });
          },
        ),
        const SizedBox(height: 24),
        _sectionHeader("Evidence / Attachment"),
        const SizedBox(height: 10),
        _buildPickerRow(
          icon: Icons.attach_file,
          label: "Media",
          value: _selectedFileName ?? "Upload Image/Video",
          valueColor: _selectedFileName != null ? Colors.green : primaryBlue,
          onTap: _pickMedia,
        ),
        const SizedBox(height: 40),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _sectionHeader(String title) => Text(
    title.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: primaryBlue.withOpacity(0.5),
      letterSpacing: 1.1,
    ),
  );

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    required IconData icon,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: primaryBlue, size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(16),
      ),
    ),
  );

  Widget _buildPickerRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryBlue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryBlue, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    ),
  );

  Widget _buildSubmitButton() => SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 2,
      ),
      onPressed: _isLoading ? null : _submitReport,
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text(
              "SUBMIT REQUEST",
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
            ),
    ),
  );
}
