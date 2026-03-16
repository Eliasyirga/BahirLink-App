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

  // ================= FETCH CATEGORIES =================

  Future<void> fetchCategories() async {
    try {
      final response = await CategoryService.getCategories(
        widget.emergencyTypeId,
      );

      setState(() {
        categories = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Category fetch error: $e");

      setState(() {
        isLoading = false;
      });
    }
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            buildHeader(),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff1976D2),
                      ),
                    )
                  : buildCategoryList(),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: const BoxDecoration(
        color: Color(0xff1976D2),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Categories for ${widget.emergencyTypeName}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CATEGORY LIST =================

  Widget buildCategoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];

        final String categoryName = category["name"] ?? "";
        final String categoryId = category["id"];

        return buildCategoryTile(categoryName, categoryId);
      },
    );
  }

  // ================= CATEGORY TILE =================

  Widget buildCategoryTile(String name, String id) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xff1976D2),
                size: 26,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
