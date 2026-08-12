import 'dart:async';

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../services/vad_audio_service.dart';

import '../theme/app_colors.dart';

import '../widgets/custom_button.dart';

import '../widgets/glass_card.dart';



class VoiceCallScreen extends StatefulWidget {

  const VoiceCallScreen({super.key});



  @override

  State<VoiceCallScreen> createState() => _VoiceCallScreenState();

}



class _VoiceCallScreenState extends State<VoiceCallScreen> {

  final VadAudioService _vadService = VadAudioService();

  late StreamSubscription<VadState> _vadStateSubscription;

  late StreamSubscription<double> _amplitudeSubscription;



  VadState _currentVadState = VadState.listening;

  double _currentAmplitude = 0.1;

  bool _isMuted = false;

  int _callDurationSeconds = 0;

  Timer? _durationTimer;



  @override

  void initState() {

    super.initState();

    _vadService.startListening();



    _vadStateSubscription = _vadService.vadStateStream.listen((state) {

      if (mounted) {

        setState(() {

          _currentVadState = state;

        });

      }

    });



    _amplitudeSubscription = _vadService.audioAmplitudeStream.listen((amp) {

      if (mounted) {

        setState(() {

          _currentAmplitude = amp;

        });

      }

    });



    // Call duration timer

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {

      if (mounted) {

        setState(() {

          _callDurationSeconds++;

        });

      }

    });

  }



  @override

  void dispose() {

    _vadStateSubscription.cancel();

    _amplitudeSubscription.cancel();

    _durationTimer?.cancel();

    _vadService.stopListening();

    super.dispose();

  }



  String _formatDuration(int totalSeconds) {

    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');

    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';

  }



  void _showSessionSummaryBottomSheet() {

    showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (context) {

        return Container(

          padding: const EdgeInsets.all(24),

          decoration: const BoxDecoration(

            color: Colors.white,

            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),

          ),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Center(

                child: Container(

                  width: 40,

                  height: 4,

                  decoration: BoxDecoration(

                    color: Colors.grey.shade300,

                    borderRadius: BorderRadius.circular(999),

                  ),

                ),

              ),

              const SizedBox(height: 16),

              Row(

                children: [

                  Container(

                    padding: const EdgeInsets.all(10),

                    decoration: BoxDecoration(

                      color: AppColors.primaryContainer,

                      borderRadius: BorderRadius.circular(14),

                    ),

                    child: const Icon(

                      Icons.check_circle_outline,

                      color: AppColors.primary,

                      size: 24,

                    ),

                  ),

                  const SizedBox(width: 12),

                  Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(

                        'Sesi Suara Selesai 🍃',

                        style: GoogleFonts.inter(

                          fontSize: 18,

                          fontWeight: FontWeight.w800,

                          color: AppColors.textPrimary,

                        ),

                      ),

                      Text(

                        'Durasi: ${_formatDuration(_callDurationSeconds)} • VAD Terdeteksi',

                        style: GoogleFonts.inter(

                          fontSize: 12,

                          color: AppColors.textSecondary,

                        ),

                      ),

                    ],

                  ),

                ],

              ),

              const SizedBox(height: 20),

              GlassCard(

                width: double.infinity,

                padding: const EdgeInsets.all(16),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      'ANALISIS AI SESI INI',

                      style: GoogleFonts.inter(

                        fontSize: 10,

                        fontWeight: FontWeight.w700,

                        color: AppColors.textLight,

                        letterSpacing: 0.8,

                      ),

                    ),

                    const SizedBox(height: 6),

                    Text(

                      'LUNA telah berhasil merekam dan menganalisis percakapan suaramu. Ringkasan emosi harianmu di jurnal telah diperbarui secara otomatis.',

                      style: GoogleFonts.inter(

                        fontSize: 13,

                        color: AppColors.textPrimary,

                        height: 1.4,

                      ),

                    ),

                  ],

                ),

              ),

              const SizedBox(height: 20),

              CustomPillButton(

                text: 'Lihat Detail Jurnal',

                onPressed: () {

                  Navigator.pop(context); // Close Bottom Sheet

                  Navigator.pop(context); // Back to Chat/Home

                  Navigator.pushNamed(context, '/diary');

                },

              ),

            ],

          ),

        );

      },

    );

  }



  @override

  Widget build(BuildContext context) {

    final int dbPercent = (_currentAmplitude * 100).round();



    return Scaffold(

      body: Container(

        width: double.infinity,

        height: double.infinity,

        decoration: const BoxDecoration(

          gradient: LinearGradient(

            colors: [

              Color(0xFF1E1B2E),

              Color(0xFF282545),

              Color(0xFF1A1829),

            ],

            begin: Alignment.topCenter,

            end: Alignment.bottomCenter,

          ),

        ),

        child: SafeArea(

          child: Column(

            children: [

              // Header Bar with VAD Status Badge

              Padding(

                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),

                child: Row(

                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [

                    IconButton(

                      icon: const Icon(Icons.arrow_back, color: Colors.white),

                      onPressed: () => Navigator.pop(context),

                    ),

                    _buildVadStatusBadge(),

                    Text(

                      _formatDuration(_callDurationSeconds),

                      style: GoogleFonts.inter(

                        fontSize: 14,

                        fontWeight: FontWeight.w700,

                        color: Colors.white70,

                      ),

                    ),

                  ],

                ),

              ),



              const Spacer(),



              // Center Avatar Orb with Dynamic Amplitude Glow

              Center(

                child: Stack(

                  alignment: Alignment.center,

                  children: [

                    // Outer Amplitude Glow Ring

                    AnimatedContainer(

                      duration: const Duration(milliseconds: 120),

                      width: 160 + (_currentAmplitude * 60),

                      height: 160 + (_currentAmplitude * 60),

                      decoration: BoxDecoration(

                        shape: BoxShape.circle,

                        color: _getVadColor().withValues(alpha: 0.25),

                      ),

                    ),

                    // Inner Avatar Orb

                    Container(

                      width: 150,

                      height: 150,

                      decoration: BoxDecoration(

                        shape: BoxShape.circle,

                        gradient: const LinearGradient(

                          colors: [Color(0xFF8B93FF), Color(0xFF5358CB)],

                        ),

                        boxShadow: [

                          BoxShadow(

                            color: _getVadColor().withValues(alpha: 0.5),

                            blurRadius: 30,

                            spreadRadius: 4,

                          ),

                        ],

                      ),

                      child: const Center(

                        child: Icon(

                          Icons.nightlight_round,

                          size: 64,

                          color: Colors.white,

                        ),

                      ),

                    ),

                  ],

                ),

              ),



              const SizedBox(height: 24),



              // Title & Subtitle Info

              Text(

                'LUNA AI Assistant',

                style: GoogleFonts.inter(

                  fontSize: 22,

                  fontWeight: FontWeight.w800,

                  color: Colors.white,

                ),

              ),

              const SizedBox(height: 4),

              Text(

                _getVadStatusDescription(),

                style: GoogleFonts.inter(

                  fontSize: 13,

                  color: Colors.white70,

                ),

              ),



              const SizedBox(height: 24),



              // AMPLITUDE REACTIVE AUDIO WAVES (Visual VAD Equalizer)

              Padding(

                padding: const EdgeInsets.symmetric(horizontal: 40.0),

                child: Column(

                  children: [

                    SizedBox(

                      height: 50,

                      child: Row(

                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                        crossAxisAlignment: CrossAxisAlignment.center,

                        children: List.generate(12, (index) {

                          // Calculate dynamic height based on current amplitude & position

                          final multiplier = (index % 3 + 1) * 0.3;

                          final barHeight = (10 + (_currentAmplitude * 38 * multiplier))

                              .clamp(8.0, 48.0);



                          return AnimatedContainer(

                            duration: const Duration(milliseconds: 90),

                            width: 6,

                            height: barHeight,

                            decoration: BoxDecoration(

                              color: _getVadColor().withValues(alpha: _isMuted ? 0.3 : 0.9),

                              borderRadius: BorderRadius.circular(999),

                            ),

                          );

                        }),

                      ),

                    ),

                    const SizedBox(height: 8),

                    Text(

                      'Input Amplitudo VAD: $dbPercent dB',

                      style: GoogleFonts.inter(

                        fontSize: 11,

                        fontWeight: FontWeight.w600,

                        color: Colors.white38,

                      ),

                    ),

                  ],

                ),

              ),



              const Spacer(),



              // INTERACTIVE SPEECH DEMO CONTROLLER (Tap to speak / pause / barge-in)

              Padding(

                padding: const EdgeInsets.symmetric(horizontal: 24.0),

                child: Row(

                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [

                    ElevatedButton.icon(

                      onPressed: () {

                        if (_currentVadState == VadState.userSpeaking) {

                          _vadService.triggerSpeechPause();

                        } else {

                          _vadService.triggerSpeechStart();

                        }

                      },

                      style: ElevatedButton.styleFrom(

                        backgroundColor: _currentVadState == VadState.userSpeaking

                            ? const Color(0xFFE53935)

                            : AppColors.primary,

                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),

                      ),

                      icon: Icon(

                        _currentVadState == VadState.userSpeaking

                            ? Icons.pause_circle_outline

                            : Icons.record_voice_over,

                        color: Colors.white,

                        size: 18,

                      ),

                      label: Text(

                        _currentVadState == VadState.userSpeaking

                            ? 'Selesaikan Bicara (Hening)'

                            : 'Mulai Bicara (VAD Trigger)',

                        style: GoogleFonts.inter(

                          fontSize: 12,

                          fontWeight: FontWeight.w700,

                          color: Colors.white,

                        ),

                      ),

                    ),

                  ],

                ),

              ),



              const SizedBox(height: 24),



              // Bottom Control Bar (Mute, End Call)

              Padding(

                padding: const EdgeInsets.fromLTRB(36.0, 0, 36.0, 32.0),

                child: Row(

                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                  children: [

                    // Mute Microphone Button

                    GestureDetector(

                      onTap: () {

                        setState(() {

                          _isMuted = _vadService.toggleMute();

                        });

                      },

                      child: Container(

                        width: 56,

                        height: 56,

                        decoration: BoxDecoration(

                          shape: BoxShape.circle,

                          color: _isMuted

                              ? const Color(0xFFE53935)

                              : Colors.white.withValues(alpha: 0.15),

                        ),

                        child: Icon(

                          _isMuted ? Icons.mic_off : Icons.mic,

                          color: Colors.white,

                          size: 26,

                        ),

                      ),

                    ),



                    // End Call Button

                    GestureDetector(

                      onTap: () {

                        _showSessionSummaryBottomSheet();

                      },

                      child: Container(

                        width: 64,

                        height: 64,

                        decoration: const BoxDecoration(

                          shape: BoxShape.circle,

                          color: Color(0xFFD32F2F),

                        ),

                        child: const Icon(

                          Icons.call_end,

                          color: Colors.white,

                          size: 30,

                        ),

                      ),

                    ),

                  ],

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildVadStatusBadge() {

    String label;

    Color badgeBg;

    Color textColor;

    IconData icon;



    switch (_currentVadState) {

      case VadState.userSpeaking:

        label = 'BICARA TERDETEKSI';

        badgeBg = const Color(0xFFFFDCDD);

        textColor = const Color(0xFFD32F2F);

        icon = Icons.graphic_eq;

        break;

      case VadState.aiProcessing:

        label = 'MENYINTESIS JAWABAN...';

        badgeBg = const Color(0xFFE2F3FF);

        textColor = const Color(0xFF0288D1);

        icon = Icons.hourglass_top_rounded;

        break;

      case VadState.aiSpeaking:

        label = 'LUNA MERESPONS';

        badgeBg = const Color(0xFFEADBFF);

        textColor = AppColors.primary;

        icon = Icons.volume_up;

        break;

      case VadState.bargeInInterrupted:

        label = 'BARGE-IN INTERRUPT!';

        badgeBg = const Color(0xFFFFF3E0);

        textColor = const Color(0xFFFB8C00);

        icon = Icons.bolt;

        break;

      case VadState.idle:
      case VadState.listening:
        label = 'MENDENGARKAN SUARA';
        badgeBg = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        icon = Icons.mic_none;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Color _getVadColor() {
    switch (_currentVadState) {
      case VadState.userSpeaking:
        return const Color(0xFFE53935);
      case VadState.aiProcessing:
        return const Color(0xFF0288D1);
      case VadState.aiSpeaking:
        return AppColors.primary;
      case VadState.bargeInInterrupted:
        return const Color(0xFFFB8C00);
      case VadState.idle:
      case VadState.listening:
        return const Color(0xFF4CAF50);
    }
  }

  String _getVadStatusDescription() {
    if (_isMuted) return 'Mikrofon Di-mute';

    switch (_currentVadState) {
      case VadState.userSpeaking:
        return 'VAD Aktif • Merekam Suara Pengguna...';
      case VadState.aiProcessing:
        return 'Hening Terdeteksi • Menyiapkan Jawaban AI...';
      case VadState.aiSpeaking:
        return 'LUNA Sedang Bicara (Dapat Disela Kapan Saja)';
      case VadState.bargeInInterrupted:
        return 'Interrupsi Terdeteksi! Memotong Suara LUNA...';
      case VadState.idle:
      case VadState.listening:
        return 'VAD Siap • Silakan Bicara Kapan Saja';
    }
  }

}

