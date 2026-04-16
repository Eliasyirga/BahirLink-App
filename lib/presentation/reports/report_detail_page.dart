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
  static const Color primaryBlue = Color(0xFF0D47A1);

  File? _mediaFile;
  Uint8List? _webBytes;

  String safe(dynamic v) => v?.toString() ?? 'N/A';

  @override
  Widget build(BuildContext context) {
    final e = widget.emergency;
    final status = safe(e['status']).toUpperCase();
    final bool isCritical = safe(
      e['typeName'],
    ).toLowerCase().contains('critical');

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          // 1. IMAGE HEADER
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: primaryBlue,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black26,
                child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroImage(e['mediaUrl']),
            ),
          ),

          // 2. DETAILS BODY
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _badge(
                        safe(e['typeName']),
                        isCritical ? Colors.red : primaryBlue,
                      ),
                      _badge(status, _getStatusColor(status)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    safe(e['categoryName']),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        safe(e['time']),
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  const Divider(height: 40),

                  _sectionHeader("DESCRIPTION"),
                  Text(
                    safe(e['description']),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // LOCATION SECTION (Kebele name only - Lat/Long hidden)
                  _locationCard(e),

                  const SizedBox(height: 32),

                  // ACTIONS
                  _actionButtons(safe(e['id'])),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _locationCard(Map<String, dynamic> e) {
    // Extracting name only from the kebele object
    String kebeleName = 'N/A';
    if (e['kebele'] != null) {
      kebeleName = e['kebele'] is Map
          ? (e['kebele']['name'] ?? 'N/A')
          : e['kebele'].toString();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on, color: primaryBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "KEBELE",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  kebeleName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                // Note: Lat/Long data exists in the 'e' map, but we simply don't build widgets for them here.
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons(String id) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () => _showEditDialog(id),
            icon: const Icon(Icons.edit_note, size: 20),
            label: const Text("Edit Details"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // CLEAR LOCALLY BUTTON
        Container(
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => _confirmLocalClear(id),
            icon: const Icon(
              Icons.visibility_off_outlined,
              color: Colors.orange,
            ),
            tooltip: "Hide from phone",
            padding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  // --- LOGIC: HIDE FROM PHONE ---

  void _confirmLocalClear(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hide Report?"),
        content: const Text(
          "This removes the report from your screen locally. It will not be deleted from the server.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(
                context,
                id,
              ); // Close page & pass ID back to list to hide it
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Hide Now"),
          ),
        ],
      ),
    );
  }

  // --- HELPER METHODS ---

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: primaryBlue,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildHeroImage(String? mediaUrl) {
    if (kIsWeb && _webBytes != null)
      return Image.memory(_webBytes!, fit: BoxFit.cover);
    if (_mediaFile != null) return Image.file(_mediaFile!, fit: BoxFit.cover);
    if (mediaUrl != null && mediaUrl.isNotEmpty) {
      final url = mediaUrl.startsWith('http')
          ? mediaUrl
          : "http://localhost:5000$mediaUrl";
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.blueGrey[100],
      child: const Icon(Icons.image, size: 50, color: Colors.white),
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('RESOLVED')) return Colors.green;
    if (status.contains('PENDING')) return Colors.orange;
    return Colors.blueGrey;
  }

  void _showEditDialog(String id) {
    final descC = TextEditingController(
      text: safe(widget.emergency['description']),
    );
    final kObj = widget.emergency['kebele'];
    final kebeleC = TextEditingController(
      text: kObj is Map ? safe(kObj['name']) : safe(kObj),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Report"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field("Kebele", kebeleC),
            _field("Description", descC, maxLines: 3),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = {'description': descC.text, 'kebele': kebeleC.text};
              await ReportsService.updateEmergency(widget.userId, id, data);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context, true);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _pickMedia() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (p != null) {
      if (kIsWeb)
        _webBytes = await p.readAsBytes();
      else
        _mediaFile = File(p.path);
      setState(() {});
    }
  }

  Widget _field(String label, TextEditingController c, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
