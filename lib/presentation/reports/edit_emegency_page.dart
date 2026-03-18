import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/reports_service.dart';

class EditEmergencyPage extends StatefulWidget {
  final Map<String, dynamic> emergency;
  final String userId;

  const EditEmergencyPage({
    super.key,
    required this.emergency,
    required this.userId,
  });

  @override
  State<EditEmergencyPage> createState() => _EditEmergencyPageState();
}

class _EditEmergencyPageState extends State<EditEmergencyPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _typeController;
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;
  late TextEditingController _kebeleController;
  late TextEditingController _subdivisionController;
  late TextEditingController _streetController;

  File? _mediaFile;
  Uint8List? _webMediaBytes;

  bool _isSaving = false;

  static const Color primaryBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    final e = widget.emergency;

    _typeController = TextEditingController(text: e['typeName'] ?? '');
    _categoryController = TextEditingController(text: e['categoryName'] ?? '');
    _descriptionController = TextEditingController(
      text: e['description'] ?? '',
    );
    _kebeleController = TextEditingController(text: e['kebele'] ?? '');
    _subdivisionController = TextEditingController(
      text: e['subdivision'] ?? '',
    );
    _streetController = TextEditingController(text: e['street'] ?? '');
  }

  @override
  void dispose() {
    _typeController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _kebeleController.dispose();
    _subdivisionController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  // ---------------- MEDIA ----------------
  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null && mounted) {
      if (kIsWeb) {
        _webMediaBytes = await picked.readAsBytes();
      } else {
        _mediaFile = File(picked.path);
      }
      setState(() {});
    }
  }

  Widget _buildMediaPreview() {
    if (_mediaFile != null) {
      return Image.file(_mediaFile!, fit: BoxFit.cover);
    } else if (_webMediaBytes != null) {
      return Image.memory(_webMediaBytes!, fit: BoxFit.cover);
    } else if (widget.emergency['mediaUrl'] != null &&
        widget.emergency['mediaUrl'].toString().isNotEmpty) {
      return Image.network(widget.emergency['mediaUrl'], fit: BoxFit.cover);
    }
    return const SizedBox.shrink();
  }

  // ---------------- SAVE ----------------
  Future<void> _saveEmergency() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);

    final updatedData = {
      "typeName": _typeController.text.trim(),
      "categoryName": _categoryController.text.trim(),
      "description": _descriptionController.text.trim(),
      "kebele": _kebeleController.text.trim(),
      "subdivision": _subdivisionController.text.trim(),
      "street": _streetController.text.trim(),
    };

    try {
      await ReportsService.updateEmergency(
        widget.userId,
        widget.emergency['id'],
        updatedData,
        file: _mediaFile,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Updated successfully")));

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // 🔵 GRADIENT HEADER
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: const Text(
              "Edit Emergency",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildSectionCard(
                child: Column(
                  children: [
                    _buildField(_typeController, "Emergency Type"),
                    _buildField(_categoryController, "Category"),
                    _buildField(
                      _descriptionController,
                      "Description",
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _buildSectionCard(
                title: "Location",
                child: Column(
                  children: [
                    _buildField(_kebeleController, "Kebele"),
                    _buildField(_subdivisionController, "Subdivision"),
                    _buildField(_streetController, "Street"),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _buildSectionCard(
                title: "Media",
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickMedia,
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: primaryBlue),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            "Tap to Upload Media",
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_mediaFile != null ||
                        _webMediaBytes != null ||
                        widget.emergency['mediaUrl'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: _buildMediaPreview(),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 🚀 SAVE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveEmergency,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Save Changes",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- COMPONENTS ----------------
  Widget _buildSectionCard({String? title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                title,
                style: const TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (value) => (value == null || value.trim().isEmpty)
            ? "$label is required"
            : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
        ),
      ),
    );
  }
}
