import 'package:flutter/material.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool showEmergency = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
        backgroundColor: const Color(0xFF1565C0), // Primary blue
        elevation: 2,
      ),
      body: Column(
        children: [
          // Toggle buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => showEmergency = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: showEmergency
                          ? const Color(0xFF1565C0)
                          : Colors.white,
                      foregroundColor: showEmergency
                          ? Colors.white
                          : const Color(0xFF1565C0),
                      elevation: showEmergency ? 4 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: const Color(0xFF1565C0),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Emergency",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => showEmergency = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !showEmergency
                          ? const Color(0xFF1565C0)
                          : Colors.white,
                      foregroundColor: !showEmergency
                          ? Colors.white
                          : const Color(0xFF1565C0),
                      elevation: !showEmergency ? 4 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: const Color(0xFF1565C0),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Services",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: showEmergency ? _buildEmergencyList() : _buildServicesList(),
          ),
        ],
      ),
    );
  }

  // -------------------- Emergency List --------------------
  Widget _buildEmergencyList() {
    final emergencies = [
      {"title": "Fire Downtown", "status": "Pending"},
      {"title": "Flood Riverside", "status": "In Progress"},
      {"title": "Medical Help", "status": "Complete"},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: emergencies.length,
      itemBuilder: (_, index) {
        final e = emergencies[index];
        Color badgeColor;
        Color textColor;

        switch (e['status']) {
          case "Pending":
            badgeColor = const Color(0x331565C0); // Light blue background
            textColor = const Color(0xFF1565C0); // Primary blue
            break;
          case "In Progress":
            badgeColor = const Color(0x331A237E); // Darker blue background
            textColor = const Color(0xFF1A237E);
            break;
          case "Complete":
            badgeColor = const Color(0x332E7D32); // Greenish for complete
            textColor = const Color(0xFF2E7D32);
            break;
          default:
            badgeColor = const Color(0x33000000);
            textColor = Colors.black87;
        }

        return Card(
          elevation: 3,
          shadowColor: const Color(0x141565C0),
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            title: Text(
              e['title']!,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                e['status']!,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------- Services List --------------------
  Widget _buildServicesList() {
    final services = [
      "Health Center Visit",
      "Municipal Complaint",
      "Electricity Issue",
      "Water Supply Issue",
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: services.length,
      itemBuilder: (_, index) {
        return Card(
          elevation: 3,
          shadowColor: const Color(0x141565C0),
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.miscellaneous_services,
              color: Color(0xFF1565C0),
            ),
            title: Text(
              services[index],
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF1565C0),
            ),
          ),
        );
      },
    );
  }
}
