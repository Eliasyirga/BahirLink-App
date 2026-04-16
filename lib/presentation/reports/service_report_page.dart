import 'package:flutter/material.dart';
import '../../services/service_report_service.dart';
import 'service_report_detail_page.dart';

class ServiceReportPage extends StatefulWidget {
  final String userId;

  const ServiceReportPage({super.key, required this.userId});

  @override
  State<ServiceReportPage> createState() => _ServiceReportPageState();
}

class _ServiceReportPageState extends State<ServiceReportPage> {
  final ServiceReportService _apiService = ServiceReportService();
  late Future<List<dynamic>> _servicesFuture;

  // Colors
  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color bgGrey = const Color(0xFFF8FAFF);

  @override
  void initState() {
    super.initState();
    _servicesFuture = _apiService.getUserServices(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: const Text(
          "Service Reports",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: primaryBlue,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(Icons.refresh, color: primaryBlue, size: 20),
                onPressed: () => setState(() {
                  _servicesFuture = _apiService.getUserServices(widget.userId);
                }),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _servicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryBlue));
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final services = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: services.length,
            itemBuilder: (context, index) => _buildModernCard(services[index]),
          );
        },
      ),
    );
  }

  Widget _buildModernCard(dynamic service) {
    // Handling nested data from your Sequelize include
    String type = service['ServiceType']?['name'] ?? "General Service";
    String category = service['ServiceCategory']?['name'] ?? "Uncategorized";
    String status = (service['status'] ?? 'Pending').toUpperCase();
    String date = service['createdAt']?.toString().substring(0, 10) ?? "N/A";

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceReportDetailPage(service: service),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Bar: Icon and Status
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.analytics_rounded,
                      color: primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      type,
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _statusChip(status),
                ],
              ),
            ),

            // Middle section: Category and Label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: Colors.grey.withOpacity(0.1), thickness: 1),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "CATEGORY",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "DATE",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    if (status == 'COMPLETED')
      color = const Color(0xFF43A047);
    else if (status == 'REJECTED')
      color = const Color(0xFFE53935);
    else
      color = const Color(0xFFFB8C00);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // State Builders (Empty/Error)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.layers_clear_outlined,
            size: 70,
            color: primaryBlue.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            "No active reports",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "Connection error. Check if backend is running.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red[900]),
        ),
      ),
    );
  }
}
