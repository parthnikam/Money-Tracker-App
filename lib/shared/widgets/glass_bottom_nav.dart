import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

class NavItem {
  const NavItem({required this.icon, required this.label, this.activeIcon});

  final IconData icon;
  final IconData? activeIcon;
  final String label;
}

/// Floating capsule nav matching `ui_design/navbar.png`:
/// dark pill, selected tab expands into a white chip with label.
/// Anchored to the **bottom** of the screen (not vertically centered).
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    // heightFactor: 1 keeps this widget only as tall as the pill so Scaffold
    // doesn't give it a huge bottom slot that would center the bar mid-screen.
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(28, 0, 28, 14),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              // Opaque on purpose. A live blur under this pill re-samples
              // every scroll frame. The fill is already a near-solid dark pill.
              color: isLight
                  ? const Color(0xFF121212)
                  : const Color(0xFF0A0A0A),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(items.length, (i) {
                final item = items[i];
                final selected = i == currentIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (i != currentIndex) {
                        HapticFeedback.selectionClick();
                        onTap(i);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      height: 46,
                      padding: EdgeInsets.symmetric(
                        horizontal: selected ? 16 : 14,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected
                                ? (item.activeIcon ?? item.icon)
                                : item.icon,
                            size: 22,
                            color: selected
                                ? AppColors.black
                                : Colors.white.withValues(alpha: 0.72),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            child: selected
                                ? Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      item.label,
                                      style: const TextStyle(
                                        color: AppColors.black,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
