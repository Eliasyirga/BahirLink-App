import 'package:flutter/material.dart';
import '../reporting/user_emergency_report_page.dart';
import '../../services/category_service.dart';

class UserCategorySelectionPage extends StatefulWidget {
  final String emergencyTypeId;
  final String emergencyTypeName;

  const UserCategorySelectionPage({
    super.key,
    required this.emergencyTypeId,
    required this.emergencyTypeName,
  });

  @override
  State<UserCategorySelectionPage> createState() =>
      _UserCategorySelectionPageState();
}

class _UserCategorySelectionPageState extends State<UserCategorySelectionPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  // Helper to sort categories alphabetically but keep "Others" at the end
  List<Map<String, dynamic>> _sortCategories(List<Map<String, dynamic>> list) {
    List<Map<String, dynamic>> sorted = List.from(list);
    sorted.sort((a, b) {
      String nameA = a["name"].toString().toLowerCase();
      String nameB = b["name"].toString().toLowerCase();

      bool isAOther = nameA == "others" || nameA == "other";
      bool isBOther = nameB == "others" || nameB == "other";

      if (isAOther && !isBOther) return 1;
      if (!isAOther && isBOther) return -1;
      return nameA.compareTo(nameB);
    });
    return sorted;
  }

  Future<void> fetchCategories() async {
    try {
      final response = await CategoryService.getCategories(
        widget.emergencyTypeId,
      );

      // CRITICAL FIX: Check if the widget is still in the tree
      if (!mounted) return;

      setState(() {
        categories = _sortCategories(List<Map<String, dynamic>>.from(response));
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Category fetch error: $e");

      // Check mounted here as well
      if (!mounted) return;

      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2563EB),
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
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
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
                size: 12,
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
          Text(
            "Select a specific category",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    if (categories.isEmpty) {
      return const Center(child: Text("No categories available"));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        // Convert ID to string to ensure compatibility with Widget parameters
        return _buildCategoryCard(cat["name"].toString(), cat["id"].toString());
      },
    );
  }

  Widget _buildCategoryCard(String name, String id) {
    bool isOther =
        name.toLowerCase() == "others" || name.toLowerCase() == "other";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.06),
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
                builder: (_) => UserEmergencyReportPage(
                  emergencyTypeId: widget.emergencyTypeId,
                  emergencyTypeName: widget.emergencyTypeName,
                  categoryId: id,
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
                        : const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOther ? Icons.more_horiz : Icons.category_outlined,
                    color: isOther ? Colors.blueGrey : const Color(0xFF3B82F6),
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
                    color: Color(0xFF1E293B),
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
