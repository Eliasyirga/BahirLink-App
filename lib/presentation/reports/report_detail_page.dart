import 'dart:io';
import 'dart:typed_data'; // ← add this
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 2,
        centerTitle: true,
        title: const Text(
          "Emergency Details",
          style: TextStyle(fontWeight: FontWeight.bold),
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
            if ((e['mediaUrl'] ?? '').isNotEmpty || _mediaFile != null)
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
            label,
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
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
          Text(
            "Address",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text("Kebele: $kebele"),
          Text("Subdivision: $sub"),
          Text("Street: $street"),
        ],
      ),
    );
  }

  Widget _mediaCard(String? mediaUrl) {
    if (_mediaFile != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: _box(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(_mediaFile!, fit: BoxFit.cover, height: 200),
        ),
      );
    }

    if (mediaUrl == null || mediaUrl.isEmpty) return const SizedBox.shrink();

    const baseUrl = "http://localhost:5000";
    final url = mediaUrl.startsWith('http') ? mediaUrl : "$baseUrl$mediaUrl";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _box(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 200,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const Center(child: CircularProgressIndicator()),
            errorBuilder: (context, error, stackTrace) => Center(
              child: Text(
                "❌ Failed to load image",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buttons(String id) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _showEditDialog(id),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Edit"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _confirmDelete(id),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Delete"),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this emergency?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ReportsService.deleteEmergency(widget.userId, id);
              if (!mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String id) {
    final type = TextEditingController(
      text: safe(widget.emergency['typeName']),
    );
    final category = TextEditingController(
      text: safe(widget.emergency['categoryName']),
    );
    final desc = TextEditingController(
      text: safe(widget.emergency['description']),
    );
    final kebele = TextEditingController(
      text: safe(widget.emergency['kebele']),
    );
    final sub = TextEditingController(
      text: safe(widget.emergency['subdivision']),
    );
    final street = TextEditingController(
      text: safe(widget.emergency['street']),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Emergency"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _field("Type", type),
              _field("Category", category),
              _field("Description", desc),
              _field("Kebele", kebele),
              _field("Subdivision", sub),
              _field("Street", street),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickMedia,
                child: const Text("Pick Media"),
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
              await ReportsService.updateEmergency(
                widget.userId,
                id,
                {
                  "typeName": type.text,
                  "categoryName": category.text,
                  "description": desc.text,
                  "kebele": kebele.text,
                  "subdivision": sub.text,
                  "street": street.text,
                },
                file: _mediaFile,
                webBytes: _webBytes,
              );
              if (!mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _pickMedia() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null && mounted) {
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
