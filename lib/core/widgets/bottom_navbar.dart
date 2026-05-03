import 'package:flutter/material.dart';

// ─── Design Tokens (same as dashboard) ───────────────────────────────────────
class _T {
  static const primary  = Color(0xFF1A3BAA);
  static const grad1    = Color(0xFF0D2580);
  static const grad2    = Color(0xFF2D5BE3);
  static const accent   = Color(0xFF4B83F0);
  static const accentBg = Color(0xFFD6E4FF);
  static const textMid  = Color(0xFF5569A0);
}

class BahirBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const BahirBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const _items = [
    (icon: Icons.home_rounded,        label: "Home"),
    (icon: Icons.build_circle_rounded, label: "Services"),
    (icon: Icons.person_rounded,       label: "Profile"),
    (icon: Icons.bar_chart_rounded,    label: "Reports"),
    (icon: Icons.settings_rounded,     label: "Settings"),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3BAA).withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          _items.length,
          (i) => _NavItem(
            icon: _items[i].icon,
            label: _items[i].label,
            isSelected: i == selectedIndex,
            onTap: () => onItemSelected(i),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 8,
        ),
        decoration: isSelected
            ? BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_T.grad1, _T.primary, _T.grad2],
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: _T.primary.withOpacity(0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? Colors.white : _T.textMid,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}