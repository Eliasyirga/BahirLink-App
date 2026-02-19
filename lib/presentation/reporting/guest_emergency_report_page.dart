import 'dart:io';
import 'package:flutter/material.dart';
import 'map_picker_page.dart';

import '../../model/emergency_report_model.dart';
import '../../services/emergency_service.dart';
import '../../services/device_service.dart';
import 'media_picker_bottom_sheet.dart';

class GuestEmergencyReportPage extends StatefulWidget {
  final String emergencyType;

  const GuestEmergencyReportPage({super.key, required this.emergencyType});

  @override
  State<GuestEmergencyReportPage> createState() =>
      _GuestEmergencyReportPageState();
}

class _GuestEmergencyReportPageState extends State<GuestEmergencyReportPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _location;
  String? _deviceId;
  File? _selectedMedia;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    String? id = await DeviceService.getDeviceId();
    setState(() {
      _deviceId = id;
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F8FF),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _descriptionCard(),
                  const SizedBox(height: 20),
                  _phoneCard(),
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

  // HEADER
  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff0D47A1), Color(0xff1976D2), Color(0xff42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  "${widget.emergencyType} Report",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Provide clear details to help responders act quickly.",
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  // DESCRIPTION CARD
  Widget _descriptionCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Emergency Description",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xff0D47A1),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Describe what is happening...",
              filled: true,
              fillColor: const Color(0xffE3F2FD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  // PHONE CARD
  Widget _phoneCard() {
    return _card(
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          hintText: "+251912345678",
          prefixIcon: const Icon(Icons.phone, color: Color(0xff1976D2)),
          filled: true,
          fillColor: const Color(0xffE3F2FD),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // LOCATION CARD
  Widget _locationCard() {
    return _card(
      child: ListTile(
        leading: const Icon(Icons.location_on, color: Color(0xff1976D2)),
        title: const Text(
          "Share Location",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _location ?? "Default: Bahir Dar, select exact location",
          style: TextStyle(
            color: _location != null ? Colors.black87 : Colors.grey[600],
            fontWeight: _location != null ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          final pickedLocation = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MapPickerPage()),
          );

          if (pickedLocation != null) {
            setState(() {
              _location =
                  "Lat: ${pickedLocation.latitude}, Lng: ${pickedLocation.longitude}";
            });
          }
        },
      ),
    );
  }

  // MEDIA CARD
  Widget _mediaCard() {
    return _card(
      child: ListTile(
        leading: const Icon(Icons.camera_alt, color: Color(0xff1976D2)),
        title: const Text(
          "Attach Photo / Video",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: _selectedMedia != null
            ? Row(
                children: [
                  if (_selectedMedia!.path.endsWith(".jpg") ||
                      _selectedMedia!.path.endsWith(".png"))
                    Image.file(
                      _selectedMedia!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedMedia!.path.split("/").last,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              )
            : const Text("Tap to attach media"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => MediaPickerBottomSheet(
              onFileSelected: (file) {
                if (file != null) {
                  setState(() {
                    _selectedMedia = file;
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  // SUBMIT BUTTON
  Widget _submitButton() {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff1976D2),
          elevation: 8,
          shadowColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: _submitReport,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Text(
                "Send Emergency Report",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // CARD DECOR
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  // SUBMIT REPORT
  void _submitReport() async {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter description")));
      return;
    }

    final report = EmergencyReportModel(
      type: widget.emergencyType,
      description: _descriptionController.text,
      location: _location,
      deviceId: _deviceId,
      phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      mediaPath: _selectedMedia?.path,
    );

    setState(() => _isLoading = true);
    bool success = await EmergencyService.sendGuestEmergency(report);
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? "Report Sent Successfully" : "Failed to Send Report",
        ),
      ),
    );

    if (success) Navigator.pop(context);
  }
}
