import 'package:flutter/material.dart';

class CurvedBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<CurvedNavItem> items;

  const CurvedBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / items.length;

    final circleSize = items.length > 5 ? 48.0 : 56.0;
    final fontSize = items.length > 5 ? 10.5 : 12.0;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Active Indicator Track
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: isRTL ? null : itemWidth * selectedIndex,
            right: isRTL ? itemWidth * selectedIndex : null,
            top: -20,
            width: itemWidth,
            child: Center(
              child: Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: items[selectedIndex].gradientColors ??
                        [colorScheme.primary, colorScheme.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (items[selectedIndex].gradientColors?.first ??
                              colorScheme.primary)
                          .withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  items[selectedIndex].activeIcon ?? items[selectedIndex].icon,
                  color: Colors.white,
                  size: items.length > 5 ? 22 : 24,
                ),
              ),
            ),
          ),

          // Navigation Items
          Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = selectedIndex == index;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onItemSelected(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Invisible icon to keep spacing when selected
                      Opacity(
                        opacity: isSelected ? 0 : 1,
                        child: Icon(
                          item.icon,
                          size: items.length > 5 ? 22 : 24,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? (item.gradientColors?.first ??
                                  colorScheme.primary)
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class CurvedNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final List<Color>? gradientColors;

  CurvedNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.gradientColors,
  });
}
