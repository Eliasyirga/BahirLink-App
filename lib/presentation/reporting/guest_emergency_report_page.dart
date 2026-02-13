import 'package:flutter/material.dart';
import '../../model/emergency_report_model.dart';
import '../../services/emergency_service.dart';

class GuestEmergencyReportPage extends StatefulWidget {
  final String emergencyType;

  const GuestEmergencyReportPage({super.key, required this.emergencyType});

  @override
  State<GuestEmergencyReportPage> createState() =>
      _GuestEmergencyReportPageState();
}

class _GuestEmergencyReportPageState extends State<GuestEmergencyReportPage> {
  final TextEditingController _descriptionController = TextEditingController();
  String? _location;
  String? _deviceId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _deviceId = "device-123-demo"; // Replace with actual device ID logic
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

  /// ================= HEADER =================
  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff0D47A1), Color(0xff1976D2), Color(0xff42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
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
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "${widget.emergencyType} Report",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            "Provide clear details to help responders act quickly.",
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /// ================= DESCRIPTION =================
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= LOCATION =================
  Widget _locationCard() {
    return _card(
      child: ListTile(
        leading: const Icon(Icons.location_on, color: Color(0xff1976D2)),
        title: const Text(
          "Share Location",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_location ?? "Tap to share your GPS location"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          setState(() {
            _location =
                "Lat: 11.59, Lng: 37.39"; // Replace with GPS integration
          });
        },
      ),
    );
  }

  /// ================= MEDIA =================
  Widget _mediaCard() {
    return _card(
      child: ListTile(
        leading: const Icon(Icons.camera_alt, color: Color(0xff1976D2)),
        title: const Text(
          "Attach Photo / Video",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // TODO: integrate media picker
        },
      ),
    );
  }

  /// ================= SUBMIT BUTTON =================
  Widget _submitButton() {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff1976D2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 6,
        ),
        onPressed: _submitReport,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
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

  /// ================= REUSABLE CARD =================
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  /// ================= SUBMIT FUNCTION =================
  void _submitReport() async {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter emergency description")),
      );
      return;
    }

    final report = EmergencyReportModel(
      type: widget.emergencyType,
      description: _descriptionController.text,
      location: _location,
      deviceId: _deviceId,
    );

    setState(() => _isLoading = true);
    bool success = await EmergencyService.sendGuestEmergency(report);
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? "Emergency report sent successfully!"
              : "Failed to send emergency report",
        ),
      ),
    );

    if (success) Navigator.pop(context);
  }
}
