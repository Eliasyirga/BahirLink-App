import 'package:flutter/material.dart';
import '../../services/reports_service.dart';
import './report_detail_page.dart';

class ReportsPage extends StatefulWidget {
  final String userId;

  const ReportsPage({super.key, required this.userId});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool showEmergency = true;
  List<Map<String, dynamic>> emergencies = [];
  bool loading = true;

  Map<String, String> emergencyTypeMap = {};
  Map<String, String> categoryMap = {};

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    // Show loading
    if (!mounted) return;
    setState(() => loading = true);

    try {
      // Fetch emergencies
      final emergenciesResponse = await ReportsService.fetchUserEmergencies(
        widget.userId,
      );

      // Fetch types
      final typesResponse = await ReportsService.fetchEmergencyTypes();
      final typesList = (typesResponse is List) ? typesResponse : [];

      // Fetch categories
      final categoriesResponse = await ReportsService.fetchCategories();
      final categoriesList = (categoriesResponse is List)
          ? categoriesResponse
          : [];

      // Build ID -> Name maps
      emergencyTypeMap = {
        for (var t in typesList)
          if (t is Map && t['id'] != null && t['name'] != null)
            t['id'].toString(): t['name'].toString(),
      };

      categoryMap = {
        for (var c in categoriesList)
          if (c is Map && c['id'] != null && c['name'] != null)
            c['id'].toString(): c['name'].toString(),
      };

      // Enrich emergencies with typeName, categoryName, description
      final enrichedEmergencies = (emergenciesResponse as List<dynamic>)
          .map<Map<String, dynamic>>((e) {
            final eMap = e as Map<String, dynamic>;
            final typeId = eMap['emergencyTypeId'];
            final categoryId = eMap['categoryId'];

            return {
              ...eMap,
              'typeName': typeId != null
                  ? emergencyTypeMap[typeId.toString()] ?? 'Unknown Type'
                  : 'Unknown Type',
              'categoryName': categoryId != null
                  ? categoryMap[categoryId.toString()] ?? 'Unknown Category'
                  : 'Unknown Category',
              'description': eMap['description'] ?? 'No description provided',
            };
          })
          .toList();

      // Update state only if still mounted
      if (!mounted) return;
      setState(() {
        emergencies = enrichedEmergencies;
        loading = false;
      });
    } catch (e) {
      debugPrint("Error fetching data: $e");
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: Column(
        children: [
          // Toggle buttons
          Padding(
            padding: const EdgeInsets.all(16),
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
                    ),
                    child: const Text("Emergency"),
                  ),
                ),
                const SizedBox(width: 10),
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
                    ),
                    child: const Text("Services"),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: showEmergency ? _buildEmergencyList() : _buildServicesList(),
          ),
        ],
      ),
    );
  }

  /// ---------------- Emergency List ----------------
  Widget _buildEmergencyList() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (emergencies.isEmpty)
      return const Center(child: Text("No emergencies reported"));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: emergencies.length,
      itemBuilder: (_, index) {
        final e = emergencies[index];

        final typeName = e['typeName'] ?? 'Unknown Type';
        final categoryName = e['categoryName'] ?? 'Unknown Category';
        final description = e['description'] ?? 'No description provided';
        final address =
            "${e['kebele'] ?? ''}, ${e['subdivision'] ?? ''}, ${e['street'] ?? ''}";
        final status = e['status']?.toString() ?? 'reported';

        // Badge color
        Color badgeColor;
        Color textColor;
        switch (status) {
          case "reported":
            badgeColor = const Color(0x331565C0);
            textColor = const Color(0xFF1565C0);
            break;
          case "in_progress":
            badgeColor = const Color(0x331A237E);
            textColor = const Color(0xFF1A237E);
            break;
          case "completed":
            badgeColor = const Color(0x332E7D32);
            textColor = const Color(0xFF2E7D32);
            break;
          default:
            badgeColor = const Color(0x33000000);
            textColor = Colors.black87;
        }

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            title: Text(
              typeName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Category: $categoryName"),
                Text("Description: $description"),
                const SizedBox(height: 4),
                Text("Address: $address"),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportDetailsPage(emergency: e),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// ---------------- Services List ----------------
  Widget _buildServicesList() {
    final services = [
      "Health Center Visit",
      "Municipal Complaint",
      "Electricity Issue",
      "Water Supply Issue",
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      itemBuilder: (_, index) {
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const Icon(
              Icons.miscellaneous_services,
              color: Color(0xFF1565C0),
            ),
            title: Text(services[index]),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        );
      },
    );
  }
}
