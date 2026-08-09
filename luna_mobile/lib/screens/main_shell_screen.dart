import 'package:flutter/material.dart';

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

          // Tab pages inside IndexedStack for instant, stateful, smooth switching

          IndexedStack(

            index: _currentIndex,

            children: _pages,

          ),



          // Floating Navigation Bar overlay

          Positioned(

            left: 0,

            right: 0,

            bottom: 0,

            child: FloatingNavBar(

              currentIndex: _currentIndex,

              onTap: (index) {

                setState(() {

                  _currentIndex = index;

                });

              },

            ),

          ),

        ],

      ),

    );

  }

}

