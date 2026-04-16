import 'package:flutter/material.dart';
import '../../services/service_report_service.dart';

class ServiceReportDetailPage extends StatelessWidget {
  final dynamic service;

  const ServiceReportDetailPage({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0D47A1);

    // ✅ Resolve the full URL using our helper
    final String fullImageUrl = ServiceReportService.getFullImageUrl(
      service['mediaUrl'],
    );

    final String type = service['ServiceType']?['name'] ?? "General Service";
    final String category = service['ServiceCategory']?['name'] ?? "Standard";
    final String status = (service['status'] ?? 'Pending').toUpperCase();
    final String date = service['createdAt']?.toString().split('T')[0] ?? "N/A";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Report Overview",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🖼️ 1. DYNAMIC IMAGE HEADER
            _buildImageHeader(fullImageUrl),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _statusChip(status),
                      const SizedBox(width: 8),
                      _categoryChip(category),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    service['name'] ?? "Service Request",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  Text(
                    "Ref ID: #SR-${service['id'] ?? '000'}",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Divider(height: 40),

                  const Text(
                    "DESCRIPTION",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service['description'] ?? "No details provided.",
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 📍 LOCATION & DATE CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      children: [
                        _infoTile(
                          Icons.location_on_rounded,
                          "LOCATION",
                          "${service['subdivision'] ?? 'Bahir Dar'}, ${service['street'] ?? ''}",
                        ),
                        const Divider(height: 24),
                        _infoTile(
                          Icons.calendar_today_rounded,
                          "SUBMITTED ON",
                          date,
                        ),
                        const Divider(height: 24),
                        _infoTile(Icons.layers_outlined, "SERVICE TYPE", type),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader(String url) {
    return Container(
      width: double.infinity,
      height: 250,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
                errorBuilder: (context, error, stack) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE1E5EB),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 50,
            color: Colors.grey,
          ),
          Text("No image available", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0D47A1), size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    final Map<String, Color> statusColors = {
      'COMPLETED': Colors.green,
      'REJECTED': Colors.red,
      'PENDING': Colors.orange,
    };
    final Color color = statusColors[status] ?? Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _categoryChip(String cat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        cat,
        style: const TextStyle(
          color: Color(0xFF0D47A1),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
