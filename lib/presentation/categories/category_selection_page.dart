import 'package:flutter/material.dart';
import '../../services/category_service.dart';
import '../reporting/guest_emergency_report_page.dart';

// ─── Dashboard Color Tokens ───────────────────────────────────────────────────
class _T {
  static const primary = Color(0xFF1A3BAA);
  static const primaryMid = Color(0xFF2252CC);
  static const accentSoft = Color(0xFFD6E4FF);
  static const bg = Color(0xFFF2F6FF);
  static const textDark = Color(0xFF0C1A45);
  static const textMid = Color(0xFF5569A0);
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
  bool _isLoading = true;
  String _currentLang = 'en';
  List<Map<String, dynamic>> _categories = [];

  // ── Locale-aware fetch ──────────────────────────────────────────────────────
  Future<void> _fetchCategories() async {
    final lang = Localizations.localeOf(context).languageCode;

    if (lang == _currentLang && _categories.isNotEmpty) return;

    setState(() {
      _isLoading = true;
      _currentLang = lang;
    });

    try {
      final raw = await CategoryService.getCategories(
        widget.emergencyTypeId,
        lang: lang,
      );

      if (!mounted) return;

      setState(() {
        _categories = _sortCategories(raw);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Category fetch error: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // ── Sort: push "Other/Others" to the end, rest alphabetically ──────────────
  List<Map<String, dynamic>> _sortCategories(List<Map<String, dynamic>> list) {
    final sorted = List<Map<String, dynamic>>.from(list);
    sorted.sort((a, b) {
      final nameA = (a['displayName'] as String).toLowerCase();
      final nameB = (b['displayName'] as String).toLowerCase();
      final aOther = nameA == 'others' || nameA == 'other';
      final bOther = nameB == 'others' || nameB == 'other';
      if (aOther && !bOther) return 1;
      if (!aOther && bOther) return -1;
      return nameA.compareTo(nameB);
    });
    return sorted;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
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

  // ── Header ──────────────────────────────────────────────────────────────────
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
            widget.emergencyTypeName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            "Select a sub-category to report",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── Grid ────────────────────────────────────────────────────────────────────
  Widget _buildGrid() {
    if (_categories.isEmpty) {
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
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final displayName = cat['displayName'] as String;
        final id = cat['id'].toString();
        return _buildCategoryCard(displayName, id);
      },
    );
  }

  // ── Category card ───────────────────────────────────────────────────────────
  Widget _buildCategoryCard(String displayName, String id) {
    final isOther = displayName.toLowerCase() == 'others' ||
        displayName.toLowerCase() == 'other';

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
                  emergencyTypeId: widget.emergencyTypeId,
                  categoryId: id,
                  emergencyTypeName: widget.emergencyTypeName,
                  categoryName: displayName,
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
                    color: isOther ? const Color(0xFFF1F5F9) : _T.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOther ? Icons.more_horiz : Icons.category_outlined,
                    color: isOther ? _T.textMid : _T.primary,
                    size: 18,
                  ),
                ),
                Text(
                  displayName,
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
