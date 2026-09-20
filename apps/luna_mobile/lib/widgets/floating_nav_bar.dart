import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// Map page currentIndex (0..3) to 5-slot layout column index:
  /// Slot 0: Home (index 0)
  /// Slot 1: Diary (index 1)
  /// Slot 2: Placeholder for Center FAB
  /// Slot 3: Monitoring / Tren (index 2)
  /// Slot 4: Profile (index 3)
  int _getSlotForIndex(int index) {
    switch (index) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 2:
        return 3;
      case 3:
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSlot = _getSlotForIndex(currentIndex);

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // Main Floating Nav Bar Container
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 25,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slotWidth = constraints.maxWidth / 5.0;
                final pillWidth = slotWidth - 8.0;
                final pillHeight = 52.0;
                final pillTop = (constraints.maxHeight - pillHeight) / 2.0;
                final pillLeft = (activeSlot * slotWidth) + 4.0;

                return Stack(
                  children: [
                    // Animated Sliding Pill Indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      left: pillLeft,
                      top: pillTop,
                      width: pillWidth,
                      height: pillHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    // Navigation Icons & Labels Row
                    Positioned.fill(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Slot 0: Beranda (Home)
                          Expanded(
                            flex: 1,
                            child: _buildSideNavItem(
                              index: 0,
                              iconUnselected: Icons.home_outlined,
                              iconSelected: Icons.home,
                              label: 'Beranda',
                            ),
                          ),

                          // Slot 1: Jurnal (Diary)
                          Expanded(
                            flex: 1,
                            child: _buildSideNavItem(
                              index: 1,
                              iconUnselected: Icons.menu_book_outlined,
                              iconSelected: Icons.menu_book,
                              label: 'Jurnal',
                            ),
                          ),

                          // Slot 2: Placeholder Space for Center FAB
                          const Expanded(
                            flex: 1,
                            child: SizedBox(),
                          ),

                          // Slot 3: Tren (Monitoring)
                          Expanded(
                            flex: 1,
                            child: _buildSideNavItem(
                              index: 2,
                              iconUnselected: Icons.show_chart_outlined,
                              iconSelected: Icons.show_chart,
                              label: 'Tren',
                            ),
                          ),

                          // Slot 4: Profil (Profile)
                          Expanded(
                            flex: 1,
                            child: _buildSideNavItem(
                              index: 3,
                              iconUnselected: Icons.person_outline,
                              iconSelected: Icons.person,
                              label: 'Profil',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        // Central Floating Circular Chat Action Button (100% Mathematically Centered)
        Positioned(
          bottom: 30,
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/chat');
            },
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6C63FF),
                    Color(0xFF5358CB),
                    Color(0xFF3B3E99),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5358CB).withValues(alpha: 0.45),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: Colors.white,
                  width: 3.0,
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 25,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSideNavItem({
    required int index,
    required IconData iconUnselected,
    required IconData iconSelected,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<Color?>(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              tween: ColorTween(
                begin: isSelected ? AppColors.textLight : AppColors.primary,
                end: isSelected ? AppColors.primary : AppColors.textLight,
              ),
              builder: (context, color, child) {
                return Icon(
                  isSelected ? iconSelected : iconUnselected,
                  size: 22,
                  color: color,
                );
              },
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textLight,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
