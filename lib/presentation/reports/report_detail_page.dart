import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/reports_service.dart';

class ReportDetailsPage extends StatefulWidget {
  final Map<String, dynamic> emergency;
  final String userId;

  const ReportDetailsPage({
    super.key,
    required this.emergency,
    required this.userId,
  });

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  static const Color primaryColor = Color(0xFF0D47A1);

  File? _mediaFile;
  Uint8List? _webBytes;

  String safe(dynamic v) => v?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    final e = widget.emergency;

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Slightly off-white for better contrast
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Emergency Details",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card("Type", safe(e['typeName'])),
            _card("Category", safe(e['categoryName'])),
            _card("Description", safe(e['description'])),
            _addressCard(
              safe(e['kebele']),
              safe(e['subdivision']),
              safe(e['street']),
            ),
            _card("Status", safe(e['status'])),
            _card("Reported Time", safe(e['time'])),
            const SizedBox(height: 16),
            _mediaCard(e['mediaUrl']),
            const SizedBox(height: 24),
            _buttons(safe(e['id'])),
          ],
        ),
      ),
    );
  }

  Widget _card(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _addressCard(String kebele, String sub, String street) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ADDRESS",
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _addressRow("Kebele", kebele),
          _addressRow("Subdivision", sub),
          _addressRow("Street", street),
        ],
      ),
    );
  }

  Widget _addressRow(String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Text("$label: $val", style: const TextStyle(fontSize: 15)),
  );

  Widget _mediaCard(String? mediaUrl) {
    Widget? imageChild;

    if (kIsWeb && _webBytes != null) {
      imageChild = Image.memory(_webBytes!, fit: BoxFit.cover);
    } else if (_mediaFile != null) {
      imageChild = Image.file(_mediaFile!, fit: BoxFit.cover);
    } else if (mediaUrl != null && mediaUrl.isNotEmpty) {
      const baseUrl = "http://localhost:5000";
      final url = mediaUrl.startsWith('http') ? mediaUrl : "$baseUrl$mediaUrl";
      imageChild = Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, prog) => prog == null
            ? child
            : const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, __, ___) =>
            const Center(child: Text("❌ Image Error")),
      );
    }

    if (imageChild == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: _box(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(height: 220, child: imageChild),
      ),
    );
  }

  void _showEditDialog(String id) {
    final controllers = {
      'typeName': TextEditingController(
        text: safe(widget.emergency['typeName']),
      ),
      'categoryName': TextEditingController(
        text: safe(widget.emergency['categoryName']),
      ),
      'description': TextEditingController(
        text: safe(widget.emergency['description']),
      ),
      'kebele': TextEditingController(text: safe(widget.emergency['kebele'])),
      'subdivision': TextEditingController(
        text: safe(widget.emergency['subdivision']),
      ),
      'street': TextEditingController(text: safe(widget.emergency['street'])),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Emergency Report"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...controllers.entries
                  .map((e) => _field(e.key.replaceAll('Name', ''), e.value))
                  .toList(),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _pickMedia,
                icon: const Icon(Icons.image),
                label: Text(
                  _mediaFile != null || _webBytes != null
                      ? "Change Media"
                      : "Update Media",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = controllers.map(
                (key, controller) => MapEntry(key, controller.text),
              );
              await ReportsService.updateEmergency(
                widget.userId,
                id,
                data,
                file: _mediaFile,
                webBytes: _webBytes,
              );
              if (!context.mounted) return;
              Navigator.pop(context); // Close Dialog
              Navigator.pop(
                context,
                true,
              ); // Return to list with refresh trigger
            },
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }

  // Helper UI methods
  Widget _buttons(String id) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _showEditDialog(id),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              "Edit Report",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _confirmDelete(id),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Report?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await ReportsService.deleteEmergency(widget.userId, id);
              if (!context.mounted) return;
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _pickMedia() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        _webBytes = await picked.readAsBytes();
      } else {
        _mediaFile = File(picked.path);
      }
      setState(() {});
    }
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.grey.withOpacity(0.1)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}
