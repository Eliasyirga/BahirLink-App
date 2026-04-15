import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
// Assuming CaseReportPage is in the same folder
import 'case_report_page.dart';

// Constants moved outside for global access
const Color _kPrimaryBlue = Color(0xFF2B7CFF);
const Color _kAccentRed = Color(0xFFEF4444);
const Color _kTextDark = Color(0xFF0F172A);
const Color _kBgLight = Color(0xFFF8FAFC);
const Color _kWhite = Colors.white;

class CaseDetailPage extends StatelessWidget {
  final dynamic caseData;
  const CaseDetailPage({super.key, required this.caseData});

  @override
  Widget build(BuildContext context) {
    final String imageUrl = caseData['mediaUrl'] != null
        ? "http://localhost:5000${caseData['mediaUrl']}"
        : "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=800";

    final bool isDangerous = caseData['isDangerous'] ?? false;

    return Scaffold(
      backgroundColor: _kBgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, imageUrl, isDangerous),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: _kBgLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 32),
                    const _SectionLabel(label: "PHYSICAL IDENTIFIERS"),
                    const SizedBox(height: 16),
                    _buildPhysicalGrid(),
                    const SizedBox(height: 24),
                    _buildFeatureBox(
                      "Distinctive Features",
                      caseData['distinctiveFeatures'] ?? "None reported.",
                    ),
                    const SizedBox(height: 32),
                    const _SectionLabel(label: "LAST KNOWN INTEL"),
                    const SizedBox(height: 16),
                    _buildIntelCard(),
                    const SizedBox(height: 32),
                    const _SectionLabel(label: "DESCRIPTION"),
                    const SizedBox(height: 12),
                    Text(
                      caseData['description'] ?? "No description provided.",
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: _kTextDark.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildSubmitButton(context),
    );
  }

  Widget _buildAppBar(BuildContext context, String imageUrl, bool isDangerous) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      stretch: true,
      backgroundColor: _kBgLight,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withOpacity(0.2),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _kWhite,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'case_${caseData['id']}',
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    _kBgLight,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
            if (isDangerous) const PositionImageDangerousTag(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusBadge(caseData['status']),
              const SizedBox(height: 12),
              Text(
                caseData['fullName']?.toUpperCase() ?? "UNKNOWN",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _kTextDark,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        _buildRewardBadge(caseData['reward']),
      ],
    );
  }

  Widget _buildStatusBadge(String? status) {
    final bool isResolved = status == 'resolved';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isResolved
            ? Colors.green.withOpacity(0.1)
            : _kPrimaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 3,
            backgroundColor: isResolved ? Colors.green : _kPrimaryBlue,
          ),
          const SizedBox(width: 6),
          Text(
            status?.toUpperCase() ?? "ACTIVE",
            style: TextStyle(
              color: isResolved ? Colors.green : _kPrimaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardBadge(dynamic reward) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kTextDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kTextDark.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "REWARD",
            style: TextStyle(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "${reward ?? '0'} ETB",
            style: const TextStyle(
              color: _kWhite,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = (constraints.maxWidth / 2) - 8;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _infoCard(
              "Age",
              "${caseData['age'] ?? 'N/A'} yrs",
              Icons.cake_rounded,
              cardWidth,
            ),
            _infoCard(
              "Gender",
              caseData['gender'] ?? "N/A",
              Icons.person_rounded,
              cardWidth,
            ),
            _infoCard(
              "Height",
              caseData['height'] ?? "N/A",
              Icons.straighten_rounded,
              cardWidth,
            ),
            _infoCard(
              "Weight",
              caseData['weight'] ?? "N/A",
              Icons.monitor_weight_rounded,
              cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _infoCard(String label, String value, IconData icon, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _kPrimaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _kTextDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntelCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _intelRow(
            Icons.location_on_rounded,
            "Last Location",
            caseData['Kebele']?['name'] ?? "Unknown",
          ),
          const Divider(height: 30, thickness: 0.5),
          _intelRow(
            Icons.calendar_month_rounded,
            "Date Reported",
            _formatDate(caseData['lastSeenDate']),
          ),
        ],
      ),
    );
  }

  Widget _intelRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _kBgLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: _kTextDark),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _kTextDark,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureBox(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimaryBlue.withOpacity(0.05), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPrimaryBlue.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: _kPrimaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: _kTextDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _kPrimaryBlue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimaryBlue,
            foregroundColor: _kWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          onPressed: () {
            // Navigate to CaseReportPage and pass the data
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CaseReportPage(caseData: caseData),
              ),
            );
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security_rounded),
              SizedBox(width: 12),
              Text(
                "SEND ANONYMOUS TIP",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return "Unknown";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr.toString();
    }
  }
}

class PositionImageDangerousTag extends StatelessWidget {
  const PositionImageDangerousTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.red.withOpacity(0.7),
            child: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  "HIGH DANGER LEVEL",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: _kTextDark.withOpacity(0.4),
        letterSpacing: 1.5,
      ),
    );
  }
}
