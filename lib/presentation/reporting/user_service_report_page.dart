import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../../services/user_emergency_service.dart';
import '../../model/emergency_report_model.dart';

class UserServiceReportPage extends StatefulWidget {
  final String serviceTypeId;
  final String categoryId;
  final String categoryName;

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
  final _formKey = GlobalKey<FormState>();

  final _descController = TextEditingController();
  final _kebeleController = TextEditingController();
  final _subdivisionController = TextEditingController();
  final _streetController = TextEditingController();

  File? _selectedFile;
  Uint8List? _webImage;
  String? _fileName;
  bool _isSubmitting = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _descController.dispose();
    _kebeleController.dispose();
    _subdivisionController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.deniedForever &&
          permission != LocationPermission.denied) {
        final position = await Geolocator.getCurrentPosition();
        setState(() => _currentPosition = position);
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final XFile? media = await picker.pickImage(source: ImageSource.gallery);
    if (media != null) {
      if (kIsWeb) {
        final bytes = await media.readAsBytes();
        setState(() {
          _webImage = bytes;
          _fileName = media.name;
        });
      } else {
        setState(() {
          _selectedFile = File(media.path);
          _fileName = path.basename(media.path);
        });
      }
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = await UserEmergencyService.getUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User session not found. Please re-login."),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // FIX: Passing String text directly to match model String? requirement
    final report = EmergencyReportModel(
      description: _descController.text,
      kebele: _kebeleController.text,
      subdivision: _subdivisionController.text,
      street: _streetController.text,
      categoryId: widget.categoryId,
      emergencyTypeId: widget.serviceTypeId,
    );

    final success = await UserEmergencyService.sendUserEmergency(
      userId: userId,
      report: report,
      latitude: _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
      mediaFile: _selectedFile,
      mediaBytes: _webImage,
      mediaName: _fileName,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request submitted successfully")),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Submission Failed")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Industrial Dark
      appBar: AppBar(
        title: Text("Request ${widget.categoryName}"),
        elevation: 0,
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel("LOCATION CONTEXT"),
              _buildSectionCard(
                child: Column(
                  children: [
                    _buildInput(
                      _kebeleController,
                      "Kebele ID",
                      Icons.numbers,
                      isNum: true,
                    ),
                    const Divider(color: Colors.white10),
                    _buildInput(
                      _subdivisionController,
                      "Subdivision / Village",
                      Icons.location_city,
                    ),
                    const Divider(color: Colors.white10),
                    _buildInput(
                      _streetController,
                      "Street (Optional)",
                      Icons.add_road,
                      required: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionLabel("SERVICE SPECIFICATIONS"),
              _buildSectionCard(
                child: _buildInput(
                  _descController,
                  "Provide detailed requirements...",
                  Icons.edit_note,
                  maxLines: 4,
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionLabel("ATTACHMENTS"),
              _buildMediaPicker(),
              const SizedBox(height: 40),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _buildInput(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool isNum = false,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        icon: Icon(icon, color: Colors.blueAccent, size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
        border: InputBorder.none,
      ),
      validator: required
          ? (v) => (v == null || v.isEmpty) ? "Required" : null
          : null,
    );
  }

  Widget _buildMediaPicker() {
    return GestureDetector(
      onTap: _pickMedia,
      child: _buildSectionCard(
        child: SizedBox(
          width: double.infinity,
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _fileName != null ? Icons.check_circle : Icons.upload_file,
                color: _fileName != null ? Colors.greenAccent : Colors.white38,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  _fileName ?? "Upload Evidence / Photo",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _fileName != null ? Colors.white : Colors.white38,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          disabledBackgroundColor: Colors.white10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                "INITIALIZE REQUEST",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }
}
