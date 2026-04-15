import 'package:flutter/material.dart';
import '../../services/service_category_service.dart';
import '../reporting/user_service_report_page.dart'; // Ensure this matches your file path

class UserServiceCategorySelectionPage extends StatefulWidget {
  final String serviceTypeId;
  final String serviceTypeName;

  const UserServiceCategorySelectionPage({
    super.key,
    required this.serviceTypeId,
    required this.serviceTypeName,
  });

  @override
  State<UserServiceCategorySelectionPage> createState() =>
      _UserServiceCategorySelectionPageState();
}

class _UserServiceCategorySelectionPageState
    extends State<UserServiceCategorySelectionPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  /// Sorts categories alphabetically but keeps "Others" at the very end
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
      final response = await ServiceCategoryService.getCategoriesByServiceType(
        widget.serviceTypeId,
      );
      if (mounted) {
        setState(() {
          categories = _sortCategories(
            List<Map<String, dynamic>>.from(response),
          );
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Service Category fetch error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Industrial Black
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                "SELECT CATEGORY",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          isLoading
              ? const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  ),
                )
              : _buildSliverGrid(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1A1A1A),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: Colors.white,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.serviceTypeName.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              "Industrial Service Infrastructure",
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Dark gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F0F0F), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverGrid() {
    if (categories.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            "No categories found",
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final cat = categories[index];
          return _buildIndustrialCard(cat["name"], cat["id"]);
        }, childCount: categories.length),
      ),
    );
  }

  Widget _buildIndustrialCard(String name, String id) {
    bool isOther = name.toLowerCase().contains("other");

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserServiceReportPage(
              serviceTypeId: widget.serviceTypeId,
              categoryId: id,
              categoryName: name,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isOther
                ? Colors.white10
                : Colors.blueAccent.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              isOther ? Icons.more_horiz : Icons.terminal_outlined,
              color: isOther ? Colors.white38 : Colors.blueAccent,
              size: 24,
            ),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
