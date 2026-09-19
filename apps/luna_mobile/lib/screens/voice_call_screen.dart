import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../features/voice_call/domain/entities/call_state.dart';
import '../features/voice_call/presentation/controllers/ai_call_controller.dart';
import '../features/voice_call/presentation/controllers/ai_call_state.dart';
import '../features/voice_call/presentation/providers/ai_call_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/glass_card.dart';

class VoiceCallScreen extends ConsumerStatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  ConsumerState<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends ConsumerState<VoiceCallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _aiRippleController;

  @override
  void initState() {
    super.initState();
    _aiRippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiCallControllerProvider.notifier).startCall();
    });
  }

  @override
  void dispose() {
    _aiRippleController.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showCrisisAlertModal(String hotline) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Protokol Krisis Aktif', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Luna AI mendeteksi indikasi krisis emosional tinggi. Bantuan darurat profesional tersedia.\n\nHotline Darurat: $hotline',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Saya Aman'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/support');
            },
            child: const Text('Buka Layanan Darurat', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSessionSummaryBottomSheet(int durationSeconds) {
    ref.read(aiCallControllerProvider.notifier).endCall();

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
                        'Durasi: ${_formatDuration(durationSeconds)} • Hybrid Half-Duplex',
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
                      'LUNA telah berhasil merekam percakapanmu melalui arsitektur Hybrid Half-Duplex. Ringkasan emosi harianmu di jurnal telah diperbarui secara otomatis.',
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
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                    arguments: {'initialIndex': 1},
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        return Consumer(
          builder: (context, ref, _) {
            final currentState = ref.watch(aiCallControllerProvider);
            final currentController = ref.read(aiCallControllerProvider.notifier);

            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1B2E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Pengaturan Panggilan',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pilih metode interaksi suara yang paling nyaman untuk Anda.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSettingsModeTile(
                    title: 'Auto Turn (Otomatis)',
                    subtitle: 'Deteksi jeda ucapan otomatis tanpa perlu menekan tombol.',
                    isSelected: currentState.conversationMode == ConversationMode.hybridAuto,
                    onTap: () {
                      currentController.setConversationMode(ConversationMode.hybridAuto);
                      Navigator.pop(modalContext);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsModeTile(
                    title: 'Push-To-Talk (Manual)',
                    subtitle: 'Tekan dan tahan tombol saat Anda ingin berbicara ke LUNA.',
                    isSelected: currentState.conversationMode == ConversationMode.pushToTalk,
                    onTap: () {
                      currentController.setConversationMode(ConversationMode.pushToTalk);
                      Navigator.pop(modalContext);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsModeTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white10,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white60,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : Colors.white38,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCallControllerProvider);
    final controller = ref.read(aiCallControllerProvider.notifier);

    // Trigger crisis modal if active & synchronize AI speech ripple animation
    ref.listen<AiCallViewState>(aiCallControllerProvider, (_, next) {
      if (next.crisisHotline != null) {
        _showCrisisAlertModal(next.crisisHotline!);
      }
      if (next.callState == CallState.aiSpeaking) {
        if (!_aiRippleController.isAnimating) {
          _aiRippleController.repeat();
        }
      } else {
        if (_aiRippleController.isAnimating) {
          _aiRippleController.stop();
          _aiRippleController.reset();
        }
      }
    });

    if (state.callState == CallState.aiSpeaking &&
        !_aiRippleController.isAnimating) {
      _aiRippleController.repeat();
    }

    final int dbPercent = (state.soundLevel * 100).round();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF13111C),
              Color(0xFF0F0E17),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Bar with Back Button, Centered Duration Timer, and Settings Icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          _formatDuration(state.callDurationSeconds),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Colors.white),
                      onPressed: () => _showSettingsBottomSheet(context),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Center Avatar Orb with Multi-Layer Ripple Wave Animation
              _buildInteractiveAvatarOrb(state),

              const SizedBox(height: 24),

              // Title & Clean Subtitle Info
              Text(
                'LUNA AI Assistant',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _getCleanStatusText(state),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: state.isMuted ? const Color(0xFFFF8B94) : Colors.white70,
                  letterSpacing: 0.2,
                ),
              ),

              // Dynamic Live Transcript preview
              if (state.latestPartial.isNotEmpty || state.currentTranscript.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                  child: Text(
                    '"${state.latestPartial.isNotEmpty ? state.latestPartial : state.currentTranscript}"',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.white60,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // AMPLITUDE REACTIVE AUDIO WAVES (Visual Equalizer)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 38,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(16, (index) {
                          final multiplier = (index % 4 + 1) * 0.25;
                          final barHeight = state.isMuted
                              ? 3.5
                              : (3.5 + (state.soundLevel * 30.0 * multiplier)).clamp(3.5, 36.0);

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 90),
                            curve: Curves.easeOut,
                            width: 3.5,
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: state.isMuted
                                  ? Colors.white12
                                  : const Color(0xFFA5B4FC).withValues(
                                      alpha: (0.35 + (state.soundLevel * 0.65)).clamp(0.35, 1.0),
                                    ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          );
                        }),
                      ),
                    ),
                    if (!state.isMuted && state.soundLevel > 0.05) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Level Suara: $dbPercent dB',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(),

              // INTERACTIVE ACTION CONTROLS
              // 1. In LISTENING: "Selesai Bicara" (Manual Force Commit)
              // 2. In AI_SPEAKING or THINKING: "Bicara (Potong AI)" (Manual Barge-In)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildMainActionButton(state, controller),
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
                      onTap: () => controller.toggleMute(),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: state.isMuted
                              ? const Color(0xFFE53935)
                              : Colors.white.withValues(alpha: 0.15),
                        ),
                        child: Icon(
                          state.isMuted ? Icons.mic_off : Icons.mic,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),

                    // End Call Button
                    GestureDetector(
                      onTap: () => _showSessionSummaryBottomSheet(state.callDurationSeconds),
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



  Widget _buildMainActionButton(AiCallViewState state, AiCallController controller) {
    if (state.conversationMode == ConversationMode.pushToTalk) {
      return GestureDetector(
        onTapDown: (_) => controller.pushToTalkPress(),
        onTapUp: (_) => controller.pushToTalkRelease(),
        onTapCancel: () => controller.pushToTalkRelease(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: state.callState == CallState.listening
                ? const Color(0xFFE53935)
                : AppColors.primary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.touch_app, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tahan untuk Bicara',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Hybrid Auto Mode Dynamic Action Button
    if (state.callState == CallState.aiSpeaking || state.callState == CallState.thinking) {
      // Barge-in button
      return ElevatedButton.icon(
        onPressed: () => controller.bargeIn(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFB8C00),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        icon: const Icon(Icons.bolt, color: Colors.white, size: 20),
        label: Text(
          '🎙 Bicara (Potong AI)',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    } else if (state.callState == CallState.listening && state.currentTranscript.isNotEmpty) {
      // Force Commit button
      return ElevatedButton.icon(
        onPressed: () => controller.forceCommit(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
        label: Text(
          'Selesai Bicara',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    return const SizedBox(height: 48);
  }



  Color _getAvatarGlowColor(AiCallViewState state) {
    switch (state.callState) {
      case CallState.aiSpeaking:
        return const Color(0xFF6C63FF);
      case CallState.thinking:
        return const Color(0xFF8B93FF);
      case CallState.interrupting:
        return const Color(0xFFFB8C00);
      case CallState.listening:
      case CallState.idle:
      case CallState.ended:
      case CallState.error:
        return const Color(0xFF8B93FF);
    }
  }

  IconData _getCenterIcon(AiCallViewState state) {
    switch (state.callState) {
      case CallState.aiSpeaking:
        return Icons.record_voice_over;
      case CallState.thinking:
        return Icons.psychology;
      case CallState.interrupting:
        return Icons.bolt;
      case CallState.listening:
      case CallState.idle:
      case CallState.ended:
      case CallState.error:
        return Icons.nightlight_round;
    }
  }

  String _getCleanStatusText(AiCallViewState state) {
    if (state.isMuted) return 'Mikrofon Di-Mute';

    switch (state.callState) {
      case CallState.listening:
        return state.isUserSpeaking
            ? 'Mendengarkan (Anda sedang berbicara)'
            : 'Mendengarkan...';
      case CallState.thinking:
        return 'AI Memproses...';
      case CallState.aiSpeaking:
        return 'LUNA Sedang Berbicara...';
      case CallState.interrupting:
        return 'Memotong Suara LUNA...';
      case CallState.idle:
      case CallState.ended:
      case CallState.error:
        return state.errorMessage ?? 'Standby';
    }
  }

  Widget _buildInteractiveAvatarOrb(AiCallViewState state) {
    final bool isAiSpeaking = state.callState == CallState.aiSpeaking;
    final glowColor = _getAvatarGlowColor(state);

    return AnimatedBuilder(
      animation: _aiRippleController,
      builder: (context, child) {
        final rippleValue = _aiRippleController.value;

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Concentric ripple wave rings when AI is speaking
              if (isAiSpeaking) ...[
                // Ripple Wave 3 (Outermost)
                _buildRippleWave(rippleValue, 0.66, 150.0, 115.0, glowColor),
                // Ripple Wave 2 (Middle)
                _buildRippleWave(rippleValue, 0.33, 150.0, 85.0, glowColor),
                // Ripple Wave 1 (Innermost)
                _buildRippleWave(rippleValue, 0.0, 150.0, 55.0, glowColor),
              ] else ...[
                // Outer Amplitude Glow Ring for User Speech / Standby
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOutQuad,
                  width: 156 + (state.soundLevel * 46),
                  height: 156 + (state.soundLevel * 46),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: glowColor.withValues(
                      alpha: state.isMuted
                          ? 0.03
                          : (0.08 + (state.soundLevel * 0.16)),
                    ),
                  ),
                ),
              ],

              // Inner Avatar Orb with breathing pulse during AI speech
              Transform.scale(
                scale: isAiSpeaking
                    ? (1.0 + 0.045 * math.sin(rippleValue * 2 * math.pi))
                    : 1.0,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B93FF), Color(0xFF5358CB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(
                          alpha: state.isMuted
                              ? 0.12
                              : (isAiSpeaking ? 0.5 : 0.35),
                        ),
                        blurRadius: isAiSpeaking ? 38 : 32,
                        spreadRadius: isAiSpeaking ? 4 : 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _getCenterIcon(state),
                      size: 62,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRippleWave(
    double controllerValue,
    double phaseOffset,
    double baseSize,
    double maxExpansion,
    Color color,
  ) {
    final progress = (controllerValue + phaseOffset) % 1.0;
    final size = baseSize + (progress * maxExpansion);
    final opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.40;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: opacity * 0.85),
          width: 1.8 - (progress * 0.8),
        ),
        color: color.withValues(alpha: opacity * 0.18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity * 0.28),
            blurRadius: 16 * progress + 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
