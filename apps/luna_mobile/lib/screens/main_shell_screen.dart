import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../widgets/floating_nav_bar.dart';
import 'ai_diary_screen.dart';
import 'home_screen.dart';
import 'monitoring_screen.dart';
import 'profile_screen.dart';

/// Lightweight wrapper ensuring each tab maintains its state and scroll position across switches.
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class MainShellScreen extends StatefulWidget {
  final int initialIndex;

  const MainShellScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;
  bool _isNavBarVisible = true;
  late final PageController _pageController;

  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<AiDiaryScreenState> _diaryKey = GlobalKey<AiDiaryScreenState>();
  final GlobalKey<MonitoringScreenState> _monitoringKey = GlobalKey<MonitoringScreenState>();
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey<ProfileScreenState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
    _pageController = PageController(initialPage: _currentIndex);
    _pages = [
      _KeepAliveWrapper(
        child: HomeScreen(
          key: _homeKey,
          onNavigateTab: _onTabTapped,
        ),
      ),
      _KeepAliveWrapper(
        child: AiDiaryScreen(key: _diaryKey),
      ),
      _KeepAliveWrapper(
        child: MonitoringScreen(key: _monitoringKey),
      ),
      _KeepAliveWrapper(
        child: ProfileScreen(key: _profileKey),
      ),
    ];
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      // Tapping same tab = refresh
      _triggerRefresh(index);
      return;
    }

    setState(() {
      _currentIndex = index;
      _isNavBarVisible = true;
    });

    _pageController
        .animateToPage(
          index,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        )
        .then((_) {
          if (mounted) {
            _triggerRefresh(index);
          }
        });
  }

  void _triggerRefresh(int index) {
    switch (index) {
      case 0:
        _homeKey.currentState?.refresh();
        break;
      case 1:
        _diaryKey.currentState?.refresh();
        break;
      case 2:
        _monitoringKey.currentState?.refresh();
        break;
      case 3:
        _profileKey.currentState?.refresh();
        break;
      default:
        break;
    }
  }

  Future<bool> _showExitConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Empathetic Icon Circle
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.nightlight_round,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                Text(
                  'Keluar dari LUNA?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                // Friendly, Reassuring Message
                Text(
                  'Apakah kamu yakin ingin menutup aplikasi? Seluruh sesi dialog, catatan refleksi, dan progres perawatan dirimu hari ini telah tersimpan dengan aman.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),

                // Warm Reassurance Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Text('🌿', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'LUNA selalu siap menemanimu kapan pun kamu ingin kembali bercerita.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF475569),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Action Buttons
                Row(
                  children: [
                    // Keluar Button
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE11D48),
                          side: const BorderSide(color: Color(0xFFFECDD3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Keluar',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tetap di Sini Button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Tetap di Sini',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          _onTabTapped(0);
          return;
        }
        final shouldExit = await _showExitConfirmationDialog();
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: NotificationListener<UserScrollNotification>(
                  onNotification: (notification) {
                    if (notification.direction == ScrollDirection.reverse &&
                        _isNavBarVisible) {
                      setState(() {
                        _isNavBarVisible = false;
                      });
                    } else if (notification.direction == ScrollDirection.forward &&
                        !_isNavBarVisible) {
                      setState(() {
                        _isNavBarVisible = true;
                      });
                    }
                    return true;
                  },
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _pages,
                  ),
                ),
              ),
            ),

            // Animated Floating Navigation Bar (Slides down when scrolling down, slides up on scroll up)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: AnimatedSlide(
                    offset: _isNavBarVisible ? Offset.zero : const Offset(0, 2.0),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: FloatingNavBar(
                      currentIndex: _currentIndex,
                      onTap: _onTabTapped,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
