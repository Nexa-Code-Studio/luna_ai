import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';



class VoiceCallScreen extends StatefulWidget {

  const VoiceCallScreen({super.key});



  @override

  State<VoiceCallScreen> createState() => _VoiceCallScreenState();

}



class _VoiceCallScreenState extends State<VoiceCallScreen> {

  bool _isMuted = false;

  bool _isSpeakerOn = false;



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      body: Container(

        width: double.infinity,

        height: double.infinity,

        decoration: const BoxDecoration(

          gradient: LinearGradient(

            colors: [

              Color(0xFF1D2353),

              Color(0xFF161B3D),

              Color(0xFF11142F),

            ],

            begin: Alignment.topCenter,

            end: Alignment.bottomCenter,

          ),

        ),

        child: SafeArea(

          child: Padding(

            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),

            child: Column(

              children: [

                // Top Navigation & Status Bar

                Row(

                  children: [

                    // Minimize Arrow Dropdown Button

                    GestureDetector(

                      onTap: () {

                        Navigator.pop(context);

                      },

                      child: Container(

                        width: 44,

                        height: 44,

                        decoration: BoxDecoration(

                          shape: BoxShape.circle,

                          color: Colors.white.withValues(alpha: 0.12),

                        ),

                        child: const Icon(

                          Icons.keyboard_arrow_down,

                          color: Colors.white,

                          size: 26,

                        ),

                      ),

                    ),

                    const Spacer(),

                    // Listening Chip Indicator

                    Container(

                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

                      decoration: BoxDecoration(

                        color: Colors.white.withValues(alpha: 0.12),

                        borderRadius: BorderRadius.circular(999),

                      ),

                      child: Row(

                        children: [

                          Container(

                            width: 8,

                            height: 8,

                            decoration: const BoxDecoration(

                              shape: BoxShape.circle,

                              color: Color(0xFF4CAF50),

                            ),

                          ),

                          const SizedBox(width: 8),

                          Text(

                            'LUNA IS LISTENING',

                            style: GoogleFonts.inter(

                              fontSize: 11,

                              fontWeight: FontWeight.w700,

                              color: Colors.white,

                              letterSpacing: 1.0,

                            ),

                          ),

                        ],

                      ),

                    ),

                    const Spacer(),

                    const SizedBox(width: 44), // Spacer alignment balance

                  ],

                ),

                const Spacer(),



                // Center 3D Iridescent Sphere Visual

                Container(

                  width: 220,

                  height: 220,

                  decoration: BoxDecoration(

                    shape: BoxShape.circle,

                    gradient: const SweepGradient(

                      colors: [

                        Color(0xFFFFB6C1),

                        Color(0xFFE2DAFF),

                        Color(0xFFA7E6FF),

                        Color(0xFF8B93FF),

                        Color(0xFFFFB6C1),

                      ],

                    ),

                    boxShadow: [

                      BoxShadow(

                        color: const Color(0xFF8B93FF).withValues(alpha: 0.4),

                        blurRadius: 50,

                        spreadRadius: 8,

                      ),

                    ],

                  ),

                  child: Container(

                    margin: const EdgeInsets.all(3),

                    decoration: const BoxDecoration(

                      shape: BoxShape.circle,

                      gradient: RadialGradient(

                        colors: [

                          Colors.white,

                          Color(0xFFE0DAFF),

                          Color(0xFF7A83FF),

                        ],

                        center: Alignment(-0.3, -0.3),

                        radius: 0.8,

                      ),

                    ),

                  ),

                ),

                const SizedBox(height: 40),



                // Title & Duration Timer

                Text(

                  'LUNA',

                  style: GoogleFonts.inter(

                    fontSize: 26,

                    fontWeight: FontWeight.w800,

                    color: Colors.white,

                    letterSpacing: 1.2,

                  ),

                ),

                const SizedBox(height: 6),

                Text(

                  '02 : 46',

                  style: GoogleFonts.inter(

                    fontSize: 18,

                    fontWeight: FontWeight.w500,

                    color: Colors.white.withValues(alpha: 0.7),

                    letterSpacing: 1.5,

                  ),

                ),

                const Spacer(),



                // Bottom Action Buttons Controls

                Row(

                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                  children: [

                    // Mute Button

                    GestureDetector(

                      onTap: () {

                        setState(() {

                          _isMuted = !_isMuted;

                        });

                      },

                      child: Container(

                        width: 56,

                        height: 56,

                        decoration: BoxDecoration(

                          shape: BoxShape.circle,

                          color: _isMuted

                              ? Colors.white

                              : Colors.white.withValues(alpha: 0.15),

                        ),

                        child: Icon(

                          _isMuted ? Icons.mic_off : Icons.mic_none,

                          color: _isMuted ? const Color(0xFF1D2353) : Colors.white,

                          size: 24,

                        ),

                      ),

                    ),



                    // End Call Button (Red Circle)

                    GestureDetector(

                      onTap: () {

                        Navigator.pop(context);

                      },

                      child: Container(

                        width: 72,

                        height: 72,

                        decoration: BoxDecoration(

                          shape: BoxShape.circle,

                          color: const Color(0xFFD32F2F),

                          boxShadow: [

                            BoxShadow(

                              color: const Color(0xFFD32F2F).withValues(alpha: 0.4),

                              blurRadius: 20,

                              offset: const Offset(0, 6),

                            ),

                          ],

                        ),

                        child: const Icon(

                          Icons.call_end,

                          color: Colors.white,

                          size: 32,

                        ),

                      ),

                    ),



                    // Speaker Button

                    GestureDetector(

                      onTap: () {

                        setState(() {

                          _isSpeakerOn = !_isSpeakerOn;

                        });

                      },

                      child: Container(

                        width: 56,

                        height: 56,

                        decoration: BoxDecoration(

                          shape: BoxShape.circle,

                          color: _isSpeakerOn

                              ? Colors.white

                              : Colors.white.withValues(alpha: 0.15),

                        ),

                        child: Icon(

                          _isSpeakerOn ? Icons.volume_up : Icons.volume_up_outlined,

                          color: _isSpeakerOn ? const Color(0xFF1D2353) : Colors.white,

                          size: 24,

                        ),

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 24),

              ],

            ),

          ),

        ),

      ),

    );

  }

}

