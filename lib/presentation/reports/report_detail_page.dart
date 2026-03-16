import 'package:flutter/material.dart';

class ReportDetailsPage extends StatelessWidget {
  final Map<String, dynamic> emergency;

  const ReportDetailsPage({super.key, required this.emergency});

  @override
  Widget build(BuildContext context) {
    final type = emergency['typeName'] ?? 'Unknown Type';
    final category = emergency['categoryName'] ?? 'Unknown Category';
    final description = emergency['description'] ?? 'No description provided';
    final kebele = emergency['kebele'] ?? '';
    final subdivision = emergency['subdivision'] ?? '';
    final street = emergency['street'] ?? '';
    final address = "$kebele, $subdivision, $street";
    final status = emergency['status'] ?? 'Unknown';
    final time = emergency['time'] ?? 'Unknown';
    final mediaUrl = emergency['mediaUrl'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Details"),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow("Emergency Type:", type),
            _buildDetailRow("Category:", category),
            _buildDetailRow("Description:", description),
            _buildDetailRow("Address:", address),
            _buildDetailRow("Status:", status),
            _buildDetailRow("Reported Time:", time.toString()),
            const SizedBox(height: 16),
            if (mediaUrl != null && mediaUrl.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Media:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  mediaUrl.endsWith(".mp4")
                      ? Container(
                          height: 200,
                          color: Colors.black12,
                          child: const Center(
                            child: Text("Video playback here"),
                          ),
                        )
                      : Image.network(
                          "http://localhost:5000$mediaUrl",
                          fit: BoxFit.cover,
                        ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
