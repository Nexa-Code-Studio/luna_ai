import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../widgets/floating_nav_bar.dart';
import 'ai_diary_screen.dart';
import 'home_screen.dart';
import 'monitoring_screen.dart';
import 'profile_screen.dart';



class MainShellScreen extends StatefulWidget {

  const MainShellScreen({super.key});



  @override

  State<MainShellScreen> createState() => _MainShellScreenState();

}



class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;
  bool _isNavBarVisible = true;

  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<AiDiaryScreenState> _diaryKey = GlobalKey<AiDiaryScreenState>();
  final GlobalKey<MonitoringScreenState> _monitoringKey = GlobalKey<MonitoringScreenState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(key: _homeKey),
      AiDiaryScreen(key: _diaryKey),
      MonitoringScreen(key: _monitoringKey),
      const ProfileScreen(),
    ];
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      // Tapping same tab = refresh
      _triggerRefresh(index);
    }
    setState(() => _currentIndex = index);
    _triggerRefresh(index);
  }

  void _triggerRefresh(int index) {
    switch (index) {
      case 0: _homeKey.currentState?.refresh(); break;
      case 1: _diaryKey.currentState?.refresh(); break;
      case 2: _monitoringKey.currentState?.refresh(); break;
      default: break;
    }
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
                  if (notification.direction == ScrollDirection.reverse && _isNavBarVisible) {
                    setState(() {
                      _isNavBarVisible = false;
                    });
                  } else if (notification.direction == ScrollDirection.forward && !_isNavBarVisible) {
                    setState(() {
                      _isNavBarVisible = true;
                    });
                  }
                  return true;
                },
                child: IndexedStack(
                  index: _currentIndex,
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

