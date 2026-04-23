import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'case_report_page.dart';

// Brand Identity Constants
const Color _kPrimaryBlue = Color(0xFF1E40AF);
const Color _kTextDark = Color(0xFF0F172A);
const Color _kBgLight = Color(0xFFF8FAFC);
const Color _kWhite = Colors.white;

class CaseDetailPage extends StatelessWidget {
  final dynamic caseData;
  const CaseDetailPage({super.key, required this.caseData});

  @override
  Widget build(BuildContext context) {
    // Resolve Image URL
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
              margin: const EdgeInsets.only(top: 20),
              decoration: const BoxDecoration(
                color: _kBgLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 24),

                    const _SectionLabel(label: "LAST KNOWN LOCATION"),
                    const SizedBox(height: 12),
                    // This method now handles the Kebele Name fetching
                    _buildLocationCard(),

                    const SizedBox(height: 24),
                    const _SectionLabel(label: "PHYSICAL IDENTIFIERS"),
                    const SizedBox(height: 12),
                    _buildPhysicalGrid(),

                    const SizedBox(height: 24),
                    _buildFeatureBox(
                      "DISTINCTIVE MARKS",
                      caseData['distinctiveFeatures'] ??
                          "No distinctive marks reported.",
                      Icons.fingerprint_rounded,
                    ),

                    const SizedBox(height: 24),
                    const _SectionLabel(label: "CASE DESCRIPTION"),
                    const SizedBox(height: 12),
                    _buildDescriptionContainer(),

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
      backgroundColor: _kPrimaryBlue,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.3),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'case_${caseData['id']}',
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black45, Colors.transparent, _kBgLight],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
            if (isDangerous) PositionImageDangerousTag(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusBadge(caseData['status']),
              const SizedBox(height: 10),
              Text(
                caseData['fullName']?.toUpperCase() ?? "UNKNOWN IDENTITY",
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

  Widget _buildLocationCard() {
    /// LOGIC TO FETCH KEBELE NAME:
    /// In Sequelize, when you use include: [Kebele], the data looks like:
    /// { "lastSeenLocationId": 5, "Kebele": { "name": "Kebele 01" } }
    String kebeleName = "Location Not Set";

    if (caseData['Kebele'] != null && caseData['Kebele']['name'] != null) {
      // Accessing the name from the joined Kebele model
      kebeleName = caseData['Kebele']['name'];
    } else if (caseData['kebele_name'] != null) {
      // Fallback to a flat field if your API flattens it
      kebeleName = caseData['kebele_name'];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kPrimaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.map_rounded,
              color: _kPrimaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kebeleName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: _kTextDark,
                  ),
                ),
                Text(
                  "Last Seen: ${_formatDate(caseData['lastSeenDate'])}",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalGrid() {
    return GridView.count(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _infoTile("AGE", "${caseData['age'] ?? 'N/A'} YRS", Icons.cake_rounded),
        _infoTile("GENDER", caseData['gender'] ?? "N/A", Icons.person_rounded),
        _infoTile(
          "HEIGHT",
          caseData['height'] ?? "N/A",
          Icons.straighten_rounded,
        ),
        _infoTile(
          "WEIGHT",
          caseData['weight'] ?? "N/A",
          Icons.monitor_weight_rounded,
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _kPrimaryBlue.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
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

  Widget _buildFeatureBox(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPrimaryBlue.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _kPrimaryBlue),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: _kPrimaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: _kTextDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionContainer() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        caseData['description'] ?? "No additional description provided.",
        style: TextStyle(
          fontSize: 15,
          color: _kTextDark.withOpacity(0.8),
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _kPrimaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status?.toUpperCase() ?? "ACTIVE",
        style: const TextStyle(
          color: _kPrimaryBlue,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildRewardBadge(dynamic reward) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: _kTextDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _kTextDark.withOpacity(0.2), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "REWARD",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 9,
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

  Widget _buildSubmitButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _kPrimaryBlue.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CaseReportPage(caseData: caseData),
            ),
          ),
          child: const Text(
            "PROVIDE ANONYMOUS TIP",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return "N/A";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
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
      left: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: Colors.red.withOpacity(0.75),
            child: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  "DANGER ALERT",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
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
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }
}
