import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/reports_service.dart';
// Ensure this import path is correct for your project structure
import '../chat/chat_page.dart';

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
  // Refined Blue & White Palette
  static const Color primaryBlue = Color(0xFF1E40AF); // Deep Tactical Blue
  static const Color accentBlue = Color(0xFF3B82F6); // Bright Action Blue
  static const Color softBlueBG = Color(0xFFF0F7FF); // Clean Background Blue
  static const Color slate900 = Color(0xFF0F172A);

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
      backgroundColor: Colors.white,
      // Floating Chat Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(emergencyId: safe(e['id'])),
            ),
          );
        },
        backgroundColor: accentBlue,
        elevation: 4,
        child: const Icon(
          Icons.chat_bubble_outline_rounded,
          color: Colors.white,
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. DYNAMIC HEADER (Image Area)
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: primaryBlue,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildHeroImage(e['mediaUrl']),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black26,
                          Colors.transparent,
                          Colors.black54,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. INFORMATION BODY
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badges
                    Row(
                      children: [
                        _badge(
                          safe(e['typeName']),
                          isCritical ? Colors.red.shade700 : primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        _badge(status, _getStatusColor(status)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      safe(e['categoryName']),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: slate900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Incident reported at ${safe(e['time'])}",
                      style: TextStyle(
                        color: Colors.blueGrey.shade400,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(color: softBlueBG, thickness: 2),
                    ),

                    _sectionHeader("DESCRIPTION"),
                    const SizedBox(height: 12),
                    Text(
                      safe(e['description']),
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 32),

                    _sectionHeader("LOCATION"),
                    const SizedBox(height: 12),
                    _locationCard(e),

                    const SizedBox(height: 40),

                    // Actions
                    _actionButtons(safe(e['id'])),
                    const SizedBox(height: 60), // Extra space for FAB
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI WIDGETS ---

  Widget _locationCard(Map<String, dynamic> e) {
    String kebeleName = 'N/A';
    if (e['kebele'] != null) {
      kebeleName = e['kebele'] is Map
          ? (e['kebele']['name'] ?? 'N/A')
          : e['kebele'].toString();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: softBlueBG,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: primaryBlue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "BAHIR DAR, KEBELE",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.blue.shade300,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  kebeleName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
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
          child: ElevatedButton.icon(
            onPressed: () => _showEditDialog(id),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text("UPDATE DETAILS"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: () => _confirmLocalClear(id),
          icon: const Icon(Icons.archive_outlined),
          style: IconButton.styleFrom(
            backgroundColor: Colors.blue.shade50,
            foregroundColor: accentBlue,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: primaryBlue,
        fontWeight: FontWeight.w900,
        fontSize: 11,
        letterSpacing: 1.5,
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
      color: softBlueBG,
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 50,
        color: Colors.blue,
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('RESOLVED')) return Colors.teal;
    if (status.contains('PENDING')) return Colors.orange;
    return Colors.blueGrey;
  }

  void _confirmLocalClear(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Archive Report?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Hide this report from your current tactical view?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Keep"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade50,
              foregroundColor: primaryBlue,
            ),
            child: const Text("Archive"),
          ),
        ],
      ),
    );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Update Information",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field("Operational Kebele", kebeleC),
            _field("Description Update", descC, maxLines: 4),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Discard"),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text("Confirm Changes"),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: softBlueBG,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
