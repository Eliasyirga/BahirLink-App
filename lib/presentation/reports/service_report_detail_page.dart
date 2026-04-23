import 'package:flutter/material.dart';
import '../../services/service_report_service.dart';

class ServiceReportDetailPage extends StatelessWidget {
  final dynamic service;

  const ServiceReportDetailPage({super.key, required this.service});

  // Helper to safely convert dynamic values to String
  String safe(dynamic v) => v?.toString() ?? 'N/A';

  @override
  Widget build(BuildContext context) {
    // Refined Blue & White Palette for high-end engineering brand
    const Color primaryBlue = Color(0xFF1E40AF);
    const Color accentBlue = Color(0xFF3B82F6);
    const Color softBlueBG = Color(0xFFF0F7FF);
    const Color slate900 = Color(0xFF0F172A);

    // ✅ EXTRACT KEBELE DATA (matching your provided example logic)
    String kebeleName = 'N/A';
    final dynamic k = service['kebele'];
    if (k != null) {
      kebeleName = k is Map ? (k['name'] ?? 'N/A') : k.toString();
    }

    final String type = safe(
      service['serviceType']?['name'] ?? "General Service",
    );
    final String category = safe(
      service['serviceCategory']?['name'] ?? "Public Service",
    );
    final String status = safe(service['status'] ?? 'Pending').toUpperCase();
    final String street = safe(service['street']);
    final String dateStr =
        service['createdAt']?.toString().split('T')[0] ?? "N/A";

    // Resolve the full URL
    final String fullImageUrl = ServiceReportService.getFullImageUrl(
      service['mediaUrl'],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "REPORT OVERVIEW",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGE HEADER
            _buildImageHeader(fullImageUrl, softBlueBG),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. STATUS & CATEGORY CHIPS
                  Row(
                    children: [
                      _badge(status, _getStatusColor(status)),
                      const SizedBox(width: 8),
                      _badge(category, primaryBlue),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. PRIMARY KEBELE HEADING
                  Text(
                    kebeleName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: slate900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    type,
                    style: TextStyle(
                      color: accentBlue.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: softBlueBG, thickness: 2),
                  ),

                  // 4. DESCRIPTION
                  _sectionHeader("DESCRIPTION", primaryBlue),
                  const SizedBox(height: 12),
                  Text(
                    safe(service['description']),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 5. LOCATION CARD (Kebele Focus)
                  _sectionHeader("LOCATION DETAILS", primaryBlue),
                  const SizedBox(height: 12),
                  _locationCard(kebeleName, street, primaryBlue, softBlueBG),

                  const SizedBox(height: 24),

                  // 6. DATE INFO
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Submitted on $dateStr",
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationCard(String kebele, String street, Color primary, Color bg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_rounded, color: primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "BAHIR DAR",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.blue.shade300,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  kebele,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                if (street != 'N/A')
                  Text(
                    street,
                    style: TextStyle(
                      color: Colors.blueGrey.shade600,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageHeader(String url, Color bg) {
    return Container(
      width: double.infinity,
      height: 260,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: bg,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: url.isNotEmpty && url.startsWith('http')
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _placeholderIcon(),
              )
            : _placeholderIcon(),
      ),
    );
  }

  Widget _placeholderIcon() {
    return const Center(
      child: Icon(Icons.image_outlined, size: 48, color: Colors.blue),
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
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w900,
        fontSize: 11,
        letterSpacing: 1.5,
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('COMPLETED')) return Colors.teal;
    if (status.contains('REJECTED')) return Colors.red;
    if (status.contains('PENDING')) return Colors.orange;
    return Colors.blueGrey;
  }
}
