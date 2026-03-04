import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'map_picker_page.dart';
import '../../model/emergency_report_model.dart';
import '../../services/user_emergency_service.dart';
import 'media_picker_bottom_sheet.dart';

class UserEmergencyReportPage extends StatefulWidget {
  final String emergencyType;

  const UserEmergencyReportPage({super.key, required this.emergencyType});

  @override
  State<UserEmergencyReportPage> createState() =>
      _UserEmergencyReportPageState();
}

class _UserEmergencyReportPageState extends State<UserEmergencyReportPage> {
  final TextEditingController _descriptionController = TextEditingController();
  double? _latitude;
  double? _longitude;

  Uint8List? _selectedMediaBytes; // Web
  File? _selectedFile; // Mobile
  String? _selectedFileName;

  bool _isLoading = false;
  int? _userId; // fetched from backend

  @override
  void initState() {
    super.initState();
    _fetchUserId();
  }

  Future<void> _fetchUserId() async {
    final id = await UserEmergencyService.getUserId(); // fetch only the ID
    if (id != null) {
      setState(() => _userId = id);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to fetch user ID")));
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE3F2FD),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                children: [
                  _descriptionCard(),
                  const SizedBox(height: 20),
                  _locationCard(),
                  const SizedBox(height: 20),
                  _mediaCard(),
                  const SizedBox(height: 30),
                  _submitButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Container(
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
            "${widget.emergencyType} Report",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _descriptionCard() => _card(
    child: TextField(
      controller: _descriptionController,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: "Describe the emergency...",
        hintStyle: const TextStyle(color: Color(0xff1976D2)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    ),
  );

  Widget _locationCard() => _card(
    child: ListTile(
      leading: const Icon(Icons.location_on, color: Color(0xff1976D2)),
      title: const Text(
        "Share Location",
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff0D47A1)),
      ),
      subtitle: Text(
        _latitude != null && _longitude != null
            ? "Lat: $_latitude, Lng: $_longitude"
            : "Select exact location",
        style: const TextStyle(color: Color(0xff1976D2)),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color(0xff1976D2),
      ),
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
  );

  Widget _mediaCard() => _card(
    child: ListTile(
      leading: const Icon(Icons.camera_alt, color: Color(0xff1976D2)),
      title: const Text(
        "Attach Photo / Video",
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff0D47A1)),
      ),
      subtitle: _selectedFileName != null
          ? Text(
              _selectedFileName!,
              style: const TextStyle(color: Colors.green),
            )
          : const Text(
              "Tap to attach media",
              style: TextStyle(color: Color(0xff1976D2)),
            ),
      trailing: const Icon(Icons.attach_file, color: Color(0xff1976D2)),
      onTap: () {
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
      },
    ),
  );

  Widget _submitButton() => SizedBox(
    height: 55,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff0D47A1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 5,
      ),
      onPressed: _isLoading ? null : _submitReport,
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              "Send Emergency Report",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
    ),
  );

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
      ],
    ),
    child: child,
  );

  Future<void> _submitReport() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter description")));
      return;
    }

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fetching user ID. Please wait...")),
      );
      return;
    }

    final report = EmergencyReportModel(
      type: widget.emergencyType,
      description: _descriptionController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      userId: _userId!,
    );

    setState(() => _isLoading = true);

    final success = await UserEmergencyService.sendUserEmergency(
      userId: _userId!,
      report: report,
      mediaBytes: _selectedMediaBytes,
      mediaFile: _selectedFile,
      mediaName: _selectedFileName,
    );

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? "Report Sent Successfully" : "Failed to Send Report",
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) Navigator.pop(context);
  }
}
