import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'map_picker_page.dart';
import '../../model/emergency_report_model.dart';
import '../../services/user_emergency_service.dart';
import 'media_picker_bottom_sheet.dart';

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
  final TextEditingController _kebeleController = TextEditingController();
  final TextEditingController _subdivisionController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();

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
  }

  /// Safely fetch user ID from local storage
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

  void _showSnack(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _kebeleController.dispose();
    _subdivisionController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  /// Pick time for emergency report
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

  /// Media picker bottom sheet
  void _pickMedia() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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

  /// Submit emergency report
  Future<void> _submitReport() async {
    if (_descriptionController.text.isEmpty ||
        _kebeleController.text.isEmpty ||
        _subdivisionController.text.isEmpty) {
      _showSnack("Please fill description, kebele, and subdivision");
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
      kebele: _kebeleController.text,
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
      backgroundColor: const Color(0xffFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                child: _buildForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 35),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xff0D47A1), Color(0xff1976D2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(35),
        bottomRight: Radius.circular(35),
      ),
    ),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "${widget.emergencyTypeName} - ${widget.categoryName}",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("Emergency Info"),
        _infoRow("Type", widget.emergencyTypeName),
        _infoRow("Category", widget.categoryName),
        const SizedBox(height: 20),
        _sectionHeader("Details"),
        _buildTextField(
          _descriptionController,
          "Describe the emergency...",
          maxLines: 5,
        ),
        const SizedBox(height: 15),
        _sectionHeader("Address"),
        _buildTextField(_kebeleController, "Kebele"),
        const SizedBox(height: 10),
        _buildTextField(_subdivisionController, "Subdivision"),
        const SizedBox(height: 10),
        _buildTextField(_streetController, "Street"),
        const SizedBox(height: 15),
        _sectionHeader("Time & Location"),
        _buildPickerRow(
          icon: Icons.access_time,
          label: "Select Time",
          value: _selectedTime != null
              ? "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:${_selectedTime!.second.toString().padLeft(2, '0')}"
              : "Tap to select time",
          onTap: _pickTime,
        ),
        const SizedBox(height: 10),
        _buildPickerRow(
          icon: Icons.location_on,
          label: "Select Location",
          value: _latitude != null && _longitude != null
              ? "Lat: $_latitude, Lng: $_longitude"
              : "Tap to select location",
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
        const SizedBox(height: 15),
        _sectionHeader("Media"),
        _buildPickerRow(
          icon: Icons.camera_alt,
          label: "Attach Photo / Video",
          value: _selectedFileName ?? "Tap to attach media",
          valueColor: _selectedFileName != null
              ? Colors.green
              : const Color(0xff1976D2),
          onTap: _pickMedia,
        ),
        const SizedBox(height: 30),
        _buildSubmitButton(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _sectionHeader(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Color(0xff0D47A1),
    ),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(
          "$label: ",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff0D47A1),
          ),
        ),
        Flexible(
          child: Text(value, style: const TextStyle(color: Color(0xff1976D2))),
        ),
      ],
    ),
  );

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) => TextField(
    controller: controller,
    maxLines: maxLines,
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.all(14),
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
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff1976D2)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xff0D47A1),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(color: valueColor ?? const Color(0xff1976D2)),
            ),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    ),
  );

  Widget _buildSubmitButton() => SizedBox(
    height: 50,
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff0D47A1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      onPressed: _isLoading ? null : _submitReport,
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              "Send Emergency Report",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    ),
  );
}
