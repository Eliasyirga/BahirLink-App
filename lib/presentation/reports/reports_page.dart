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
  List<Map<String, dynamic>> emergencies = [];
  bool loading = true;

  Map<String, String> categoryMap = {};
  Map<String, String> typeMap = {};

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  String? extractId(dynamic field) {
    if (field == null) return null;
    if (field is String) return field;
    if (field is Map) return field['id']?.toString();
    return null;
  }

  Future<void> fetchInitialData() async {
    setState(() => loading = true);
    try {
      final emergenciesResponse = await ReportsService.fetchUserEmergencies(
        widget.userId,
      );
      final categories = await ReportsService.fetchCategories();

      categoryMap = {
        for (var c in categories) c['id'].toString(): c['name'].toString(),
      };
      typeMap = {
        for (var c in categories)
          c['id'].toString():
              c['emergencyType']?['name']?.toString() ?? "Unknown",
      };

      final enriched = emergenciesResponse.map((e) {
        final categoryId =
            extractId(e['categoryId']) ?? extractId(e['category']);
        return {
          ...e,
          'categoryName': categoryId != null
              ? categoryMap[categoryId]
              : "Unknown",
          'typeName': categoryId != null ? typeMap[categoryId] : "Unknown",
          'description': e['description'] ?? "No description",
        };
      }).toList();

      setState(() {
        emergencies = enriched;
        loading = false;
      });
    } catch (e) {
      debugPrint("ERROR fetching emergencies: $e");
      setState(() => loading = false);
    }
  }

  Color get primaryBlue => const Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryBlue,
        title: const Text(
          "My Reports",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : emergencies.isEmpty
          ? const Center(
              child: Text("No reports found", style: TextStyle(fontSize: 16)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: emergencies.length,
              itemBuilder: (_, index) {
                final e = emergencies[index];
                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportDetailsPage(
                          emergency: e,
                          userId: widget.userId,
                        ),
                      ),
                    );
                    if (result == true) fetchInitialData();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryBlue.withOpacity(0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type Badge + Arrow
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                e['typeName'],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          e['categoryName'],
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          e['description'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
