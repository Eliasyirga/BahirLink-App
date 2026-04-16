import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  /// Extracts ID safely (handles both top-level 'id' and MongoDB '_id')
  String? _extractId(dynamic field) {
    if (field == null) return null;
    if (field is String) return field;
    if (field is Map)
      return field['id']?.toString() ?? field['_id']?.toString();
    return field.toString();
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return "Recently";
    try {
      final dt = DateTime.parse(dateStr.toString());
      return DateFormat('MMM dd, hh:mm a').format(dt);
    } catch (_) {
      return "Recently";
    }
  }

  Future<void> fetchInitialData() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      final emergenciesResponse = await ReportsService.fetchUserEmergencies(
        widget.userId,
      );
      final categories = await ReportsService.fetchCategories();

      final Map<String, String> categoryMap = {
        for (var c in categories) c['id'].toString(): c['name'].toString(),
      };
      final Map<String, String> typeMap = {
        for (var c in categories)
          c['id'].toString():
              c['emergencyType']?['name']?.toString() ?? "General",
      };

      final enriched = emergenciesResponse.map((e) {
        final categoryId =
            _extractId(e['categoryId']) ?? _extractId(e['category']);
        return {
          ...e,
          // Ensure a clean ID exists for local removal logic
          'id': _extractId(e['id']) ?? _extractId(e['_id']),
          'categoryName': categoryId != null
              ? (categoryMap[categoryId] ?? "Uncategorized")
              : "Uncategorized",
          'typeName': categoryId != null
              ? (typeMap[categoryId] ?? "General")
              : "General",
          'description':
              e['description']?.toString() ?? "No description provided.",
          'createdAt':
              e['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
        };
      }).toList();

      if (mounted) {
        setState(() {
          emergencies = enriched;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("ReportsPage Error: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0D47A1);
    const Color accentBlue = Color(0xFF1976D2);
    const Color backgroundGray = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: backgroundGray,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            pinned: true,
            backgroundColor: primaryBlue,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                "My Reports",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [primaryBlue, accentBlue]),
                ),
              ),
            ),
          ),
          loading
              ? const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  ),
                )
              : emergencies.isEmpty
              ? _buildEmptyState()
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildReportCard(emergencies[index], accentBlue),
                      childCount: emergencies.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_late_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "No reports found",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, Color accentColor) {
    final String typeName = report['typeName'] ?? "General";
    final bool isCritical = typeName.toLowerCase().contains('critical');
    final Color statusColor = isCritical ? Colors.red.shade700 : accentColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            // UPDATED NAVIGATION LOGIC
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ReportDetailsPage(emergency: report, userId: widget.userId),
              ),
            );

            // 1. Check if the result is a String (The ID returned from 'Clear Locally')
            if (result is String) {
              setState(() {
                // Remove the report from the local phone memory immediately
                emergencies.removeWhere(
                  (item) => (item['id'] ?? item['_id']).toString() == result,
                );
              });
            }
            // 2. Check if the result is 'true' (An edit happened)
            else if (result == true) {
              fetchInitialData();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBadge(typeName, statusColor),
                    Text(
                      _formatDate(report['createdAt']),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  report['categoryName'] ?? "Unknown",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report['description'] ?? "",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.blueAccent,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "Tap to view full details",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueAccent,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
