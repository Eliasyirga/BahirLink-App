import 'package:flutter/material.dart';
import '../../services/service_category_service.dart';
import '../reporting/user_service_report_page.dart';

// ─── Dashboard Color Tokens ───────────────────────────────────────────────────
class _T {
  static const primary    = Color(0xFF1A3BAA);
  static const primaryMid = Color(0xFF2252CC);
  static const accent     = Color(0xFF4B83F0);
  static const accentSoft = Color(0xFFD6E4FF);
  static const bg         = Color(0xFFF2F6FF);
  static const textDark   = Color(0xFF0C1A45);
  static const textMid    = Color(0xFF5569A0);
}

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

  List<Map<String, dynamic>> _sortCategories(
      List<Map<String, dynamic>> list) {
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
      final response =
          await ServiceCategoryService.getCategoriesByServiceType(
        widget.serviceTypeId,
      );
      if (!mounted) return;
      setState(() {
        categories =
            _sortCategories(List<Map<String, dynamic>>.from(response));
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Service Category fetch error: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
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
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
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
                size: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.serviceTypeName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            "Select a specific technical category",
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
      return const Center(
        child: Text(
          "No categories available",
          style: TextStyle(color: _T.textMid),
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
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
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
                builder: (_) => UserServiceReportPage(
                  serviceTypeId: widget.serviceTypeId,
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
                        : _T.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOther
                        ? Icons.more_horiz
                        : Icons.settings_suggest_outlined,
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
