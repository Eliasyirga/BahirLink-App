import 'package:flutter/material.dart';
import '../../services/service_report_service.dart';
import '../../services/kebele_service.dart';
import '../chat/chat_page.dart';

class ServiceReportDetailPage extends StatelessWidget {
  final dynamic service;
  final String userId; // 1. Added userId
  final String token; // 2. Added token

  const ServiceReportDetailPage({
    super.key,
    required this.service,
    required this.userId, // Required in constructor
    required this.token, // Required in constructor
  });

  Future<String> _getKebeleName() async {
    try {
      final String? targetId =
          service['kebeleId']?.toString() ?? service['kebele']?.toString();
      if (targetId == null) return "Unknown Kebele";

      final List<Map<String, dynamic>> kebeles =
          await KebeleService().getAllKebeles();

      final match = kebeles.firstWhere(
        (k) =>
            k['id'].toString() == targetId || k['_id'].toString() == targetId,
        orElse: () => {},
      );

      return match['name']?.toString() ?? "Kebele $targetId";
    } catch (e) {
      debugPrint("Lookup Error: $e");
      return "Kebele ${service['kebeleId'] ?? 'N/A'}";
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1E40AF);
    const Color accentBlue = Color(0xFF3B82F6);
    const Color softBlueBG = Color(0xFFF0F7FF);
    const Color slate900 = Color(0xFF0F172A);

    final String type = service['serviceType']?['name'] ?? "General Service";
    final String category =
        service['serviceCategory']?['name'] ?? "Public Utility";
    final String status =
        (service['status'] ?? 'Pending').toString().toUpperCase();
    final String fullImageUrl =
        ServiceReportService.getFullImageUrl(service['mediaUrl']);
    final String dateStr =
        service['createdAt']?.toString().split('T')[0] ?? "N/A";
    final String street = service['street'] ?? "Not provided";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "REPORT SUMMARY",
          style: TextStyle(
              fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // ✅ FIXED: Passing all required named parameters to ChatPage
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                emergencyId:
                    int.tryParse(service['_id'].toString()) ?? 0, // Cast to int
                token: token, // Pass token
                userId: int.tryParse(userId) ?? 0, // Pass userId as int
              ),
            ),
          );
        },
        backgroundColor: accentBlue,
        elevation: 4,
        child:
            const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageHeader(fullImageUrl, softBlueBG),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statusRow(status, category, primaryBlue),
                  const SizedBox(height: 20),
                  FutureBuilder<String>(
                    future: _getKebeleName(),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? "Loading...",
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: slate900,
                            letterSpacing: -0.8),
                      );
                    },
                  ),
                  Text(
                    type.toUpperCase(),
                    style: TextStyle(
                        color: accentBlue.withOpacity(0.8),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1.2),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: softBlueBG, thickness: 2),
                  ),
                  _sectionLabel("ISSUE DESCRIPTION"),
                  const SizedBox(height: 12),
                  Text(
                    service['description'] ??
                        "No additional information provided.",
                    style: const TextStyle(
                        fontSize: 16, height: 1.6, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 32),
                  _sectionLabel("REPORT DETAILS"),
                  const SizedBox(height: 12),
                  _infoCard([
                    _infoTile(Icons.location_on_rounded, "STREET", street,
                        primaryBlue),
                    _infoTile(Icons.calendar_today_rounded, "DATE REPORTED",
                        dateStr, primaryBlue),
                    _infoTile(Icons.verified_user_outlined, "SYSTEM STATUS",
                        "Official Report", primaryBlue),
                  ], softBlueBG),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI Helper methods...
  Widget _infoCard(List<Widget> children, Color bg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade100)),
      child: Column(children: children),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: primary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey)),
                Text(value,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primary.withOpacity(0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String status, String cat, Color primary) {
    return Row(
      children: [
        _chip(status, status == 'COMPLETED' ? Colors.teal : Colors.orange),
        const SizedBox(width: 8),
        _chip(cat, primary),
      ],
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(text.toUpperCase(),
          style: TextStyle(
              color: color, fontWeight: FontWeight.w900, fontSize: 10)),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          color: Colors.blueGrey,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 1.2));

  Widget _buildImageHeader(String url, Color bg) {
    return Container(
      width: double.infinity,
      height: 260,
      margin: const EdgeInsets.all(20),
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(30), color: bg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: url.isNotEmpty && url.startsWith('http')
            ? Image.network(url,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.blue,
                    size: 40))
            : const Icon(Icons.image_outlined, color: Colors.blue, size: 40),
      ),
    );
  }
}
