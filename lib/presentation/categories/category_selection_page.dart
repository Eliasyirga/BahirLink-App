import 'package:flutter/material.dart';
import '../../services/category_service.dart';
import '../reporting/guest_emergency_report_page.dart';

// ─── Dashboard Color Tokens ───────────────────────────────────────────────────
class _T {
  static const primary    = Color(0xFF1A3BAA);
  static const primaryMid = Color(0xFF2252CC);
  static const accentSoft = Color(0xFFD6E4FF);
  static const bg         = Color(0xFFF2F6FF);
  static const textDark   = Color(0xFF0C1A45);
  static const textMid    = Color(0xFF5569A0);
}

class CategorySelectionPage extends StatefulWidget {
  final String emergencyTypeId;
  final String emergencyTypeName;

  const CategorySelectionPage({
    super.key,
    required this.emergencyTypeId,
    required this.emergencyTypeName,
  });

  @override
  State<CategorySelectionPage> createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> filteredCategories = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  void _filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCategories = categories;
      } else {
        filteredCategories = categories
            .where((category) => category["name"]
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  List<Map<String, dynamic>> _sortCategories(List<Map<String, dynamic>> list) {
    List<Map<String, dynamic>> sorted = List.from(list);
    sorted.sort((a, b) {
      String nameA = (a["name"] ?? "").toString().toLowerCase();
      String nameB = (b["name"] ?? "").toString().toLowerCase();
      bool isAOther = nameA.contains("other");
      bool isBOther = nameB.contains("other");
      if (isAOther && !isBOther) return 1;
      if (!isAOther && isBOther) return -1;
      return nameA.compareTo(nameB);
    });
    return sorted;
  }

  Future<void> _fetchCategories() async {
    try {
      final data = await CategoryService.getCategories(widget.emergencyTypeId);
      final List<Map<String, dynamic>> parsedData =
          (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
      if (mounted) {
        setState(() {
          categories = _sortCategories(parsedData);
          filteredCategories = categories;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: _T.primary,
                      strokeWidth: 2,
                    ),
                  )
                : _buildGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2580), _T.primary, _T.primaryMid],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.emergencyTypeName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Select a sub-category to report",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCategories,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search items...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white70,
                  size: 18,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    if (filteredCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: _T.textMid.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text("No matches found",
                style: TextStyle(color: _T.textMid)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: filteredCategories.length,
      itemBuilder: (context, index) {
        final cat = filteredCategories[index];
        return _buildCategoryCard(
            cat["name"].toString(), cat["id"].toString());
      },
    );
  }

  Widget _buildCategoryCard(String name, String id) {
    bool isOther = name.toLowerCase().contains("other");

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _T.primary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GuestEmergencyReportPage(
                  emergencyTypeId: widget.emergencyTypeId.toString(),
                  categoryId: id,
                  emergencyTypeName: widget.emergencyTypeName,
                  categoryName: name,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isOther
                        ? const Color(0xFFF1F5F9)
                        : _T.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOther ? Icons.more_horiz : Icons.category_outlined,
                    color: isOther ? _T.textMid : _T.primary,
                    size: 18,
                  ),
                ),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _T.textDark,
                    height: 1.1,
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