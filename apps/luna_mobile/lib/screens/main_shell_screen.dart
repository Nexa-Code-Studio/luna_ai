import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
      const _KeepAliveWrapper(
        child: ProfileScreen(),
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

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );

    _triggerRefresh(index);
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
      default:
        break;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
