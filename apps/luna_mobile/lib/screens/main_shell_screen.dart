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



  final List<Widget> _pages = const [

    HomeScreen(),

    AiDiaryScreen(),

    MonitoringScreen(),

    ProfileScreen(),

  ];



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      body: Stack(

        children: [

          // Listen to UserScrollNotification to show/hide FloatingNavBar on scroll

          NotificationListener<UserScrollNotification>(

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



          // Animated Floating Navigation Bar (Slides down when scrolling down, slides up on scroll up)

          Positioned(

            left: 0,

            right: 0,

            bottom: 0,

            child: AnimatedSlide(

              offset: _isNavBarVisible ? Offset.zero : const Offset(0, 2.0),

              duration: const Duration(milliseconds: 250),

              curve: Curves.easeInOut,

              child: FloatingNavBar(

                currentIndex: _currentIndex,

                onTap: (index) {

                  setState(() {

                    _currentIndex = index;

                  });

                },

              ),

            ),

          ),

        ],

      ),

    );

  }

}

