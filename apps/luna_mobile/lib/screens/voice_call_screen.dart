import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../features/voice_call/domain/entities/call_state.dart';
import '../features/voice_call/presentation/controllers/ai_call_controller.dart';
import '../features/voice_call/presentation/controllers/ai_call_state.dart';
import '../features/voice_call/presentation/providers/ai_call_provider.dart';
import '../services/daily_progress_local_service.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/glass_card.dart';
import 'support_emergency_screen.dart';

class VoiceCallScreen extends ConsumerStatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  ConsumerState<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends ConsumerState<VoiceCallScreen>
    with TickerProviderStateMixin {
  late final AnimationController _aiRippleController;

  @override
  void initState() {
    super.initState();
    _aiRippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

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

  void _handleExitCall(AiCallViewState state) {
    if (state.isCrisisSession) {
      ref.read(aiCallControllerProvider.notifier).endCall();
      Navigator.pushReplacement(context, SupportEmergencyScreen.route());
    } else {
      _showSessionSummaryBottomSheet(state.callDurationSeconds);
    }
  }

  bool _isHighDistressSession(AiCallViewState state) {
    if (state.crisisHotline != null) return true;
    final text = '${state.currentTranscript} ${state.aiTranscript}'.toLowerCase();
    final highDistressKeywords = [
      'krisis',
      'panik',
      'sesak',
      'bunuh diri',
      'menyakiti',
      'tidak sanggup',
      'kelelahan mental',
      'anxiety berat',
      'depresi berat',
      'putus asa',
      'tidak ada harapan',
      'takut sekali',
      'stres berat',
    ];
    return highDistressKeywords.any((k) => text.contains(k));
  }

  bool _isDassTriggeredSession(AiCallViewState state) {
    if (state.crisisHotline != null) return true;
    final text = '${state.currentTranscript} ${state.aiTranscript}'.toLowerCase();
    final dassKeywords = [
      'dass',
      'skala 0',
      'skor 0',
      'pertanyaan asesmen',
      'gejala yang kamu rasakan',
      'seberapa sering kamu merasa',
      'jantung berdebar',
      'sulit bernapas',
      'cemas berlebihan',
      'merasa putus asa',
      'kehilangan minat',
      'panik',
      'stres berat',
      'depresi berat',
    ];
    return dassKeywords.any((k) => text.contains(k));
  }

  void _showSessionSummaryBottomSheet(int durationSeconds) {
    final state = ref.read(aiCallControllerProvider);
    ref.read(aiCallControllerProvider.notifier).endCall();
    final isHighDistress = _isHighDistressSession(state);
    final hasDassTriggered = _isDassTriggeredSession(state);

    if (isHighDistress) {
      _showPostCallCrisisModal(durationSeconds);
    } else {
      _showNormalSessionSummaryBottomSheet(
        durationSeconds,
        false,
        hasDassTriggered: hasDassTriggered,
      );
    }
  }

  void _showPostCallCrisisModal(int durationSeconds) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Heart Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFE0E3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE57373).withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Color(0xFFE57373),
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                'Deteksi Beban Emosional Berat 🍃',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'LUNA mendeteksi tingkat ketegangan dan beban emosional yang tinggi dalam percakapan tadi. Kamu tidak harus memikulnya sendirian.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),

              // Reassurance info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE57373).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.air_rounded,
                      color: Color(0xFFE57373),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tersedia Latihan Napas 4-7-8 untuk menstabilkan detak jantung, kontak orang terpercaya, dan hotline krisis.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF881337),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action 1: Open Crisis Support (Pink/Rose button)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE57373),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.favorite_rounded, size: 18),
                  label: Text(
                    'Buka Latihan Napas & Bantuan Krisis',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/support');
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Action 2: Review Session Summary
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showNormalSessionSummaryBottomSheet(
                      durationSeconds,
                      true,
                      hasDassTriggered: true,
                    );
                  },
                  child: Text(
                    'Lihat Ringkasan Sesi Dulu',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNormalSessionSummaryBottomSheet(
    int durationSeconds,
    bool isHighDistress, {
    bool hasDassTriggered = false,
  }) {
    DailyProgressLocalService.recordConversationCheckin(hasConversation: true);

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
              const SizedBox(height: 16),

              // If High Distress: Show top Crisis Support Card
              if (isHighDistress) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE57373).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFDCDD),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Color(0xFFE57373),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Intervensi De-eskalasi Disarankan',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFD32F2F),
                              ),
                            ),
                            Text(
                              'Coba teknik napas 4-7-8 untuk menenangkan detak jantung.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/support');
                        },
                        child: Text(
                          'Buka →',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFD32F2F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              if (hasDassTriggered) ...[
                GlassCard(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F4FB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'SINTESIS OTOMATIS DASS-21',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF20667B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'LUNA telah mengekstrak indikator stres, kecemasan, dan suasana hatimu dari percakapan tadi ke dalam lembar DASS-21 hari ini. Kamu bisa langsung meninjau bukti kutipan obrolan, mengedit skor, atau melengkapi butir yang belum terbahas.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CustomPillButton(
                  text: 'Tinjau & Lengkapi Skor DASS-21',
                  suffixIcon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    Navigator.pop(context); // Close Bottom Sheet
                    Navigator.pushNamed(context, '/dass_assessment');
                  },
                ),
                const SizedBox(height: 10),
              ] else ...[
                GlassCard(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'REFLEKSI HARIAN TERSIMPAN',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2E7D32),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Obrolanmu telah tersimpan dan terangkum rapi ke dalam catatan refleksi emosimu hari ini. Kamu bisa membacanya kembali kapan saja.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              CustomPillButton(
                text: 'Lihat Detail Jurnal Refleksi',
                isOutline: hasDassTriggered,
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
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                  child: Text(
                    'Kembali ke Beranda',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
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

    if (!_aiRippleController.isAnimating) {
      _aiRippleController.repeat();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleExitCall(state);
        }
      },
      child: Scaffold(
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
                        onPressed: () => _handleExitCall(state),
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



              const Spacer(),

              // INTERACTIVE ACTION CONTROLS
              // 1. In LISTENING: "Selesai Bicara" (Manual Force Commit)
              // 2. In AI_SPEAKING or THINKING: "Bicara (Potong AI)" (Manual Barge-In)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildMainActionButton(state, controller),
              ),

              const SizedBox(height: 24),

              // Bottom Control Bar (Mute, End Call, Speaker)
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
                      onTap: () => _handleExitCall(state),
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

                    // Speakerphone Toggle Button
                    GestureDetector(
                      onTap: () => controller.toggleSpeaker(),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: state.isSpeakerOn
                              ? const Color(0xFF3F51B5)
                              : Colors.white.withValues(alpha: 0.15),
                        ),
                        child: Icon(
                          state.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                          color: Colors.white,
                          size: 26,
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
    if (state.callState == CallState.aiSpeaking) {
      // Barge-in / Jeda AI button (Simple & elegant, matching Selesai Bicara style)
      return ElevatedButton.icon(
        onPressed: () => controller.bargeIn(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF59E0B),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
        ),
        icon: const Icon(Icons.pause_rounded, color: Colors.white, size: 20),
        label: Text(
          'Jeda AI',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
      );
    } else if (state.callState == CallState.thinking) {
      // Non-interactive thinking badge to prevent accidental tap cancellation
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(
              'Luna sedang memproses...',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    } else if (state.callState == CallState.listening &&
        (state.currentTranscript.isNotEmpty || state.latestPartial.isNotEmpty)) {
      // Force Commit button (Only when user has actually spoken something)
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
    final double soundLevel = state.isMuted ? 0.0 : state.soundLevel;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _aiRippleController,
        builder: (context, child) {
          final animValue = _aiRippleController.value;

          return Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                // 1. RADIAL FREQUENCY EQUALIZER BARS (CIRCULAR AUDIO SPECTRUM)
                CustomPaint(
                  size: const Size(280, 280),
                  painter: _RadialFrequencyBarsPainter(
                    animationProgress: animValue,
                    soundLevel: soundLevel,
                    isAiSpeaking: isAiSpeaking,
                    isMuted: state.isMuted,
                  ),
                ),

                // 2. SOFT AMBIENT IRIDESCENT HALO
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC7D2FE).withValues(
                          alpha: state.isMuted ? 0.08 : 0.20 + ((isAiSpeaking ? soundLevel : 0.0) * 0.25),
                        ),
                        blurRadius: 36 + ((isAiSpeaking ? soundLevel : 0.0) * 20),
                        spreadRadius: 3,
                      ),
                      BoxShadow(
                        color: const Color(0xFFFFD1DC).withValues(
                          alpha: state.isMuted ? 0.05 : 0.15 + ((isAiSpeaking ? soundLevel : 0.0) * 0.15),
                        ),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),

                // 3. MAIN ORB (PASTEL / IRIDESCENT SPHERE)
                Container(
                  width: 174,
                  height: 174,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Soft iridescent pastel gradient exactly like the design
                    gradient: const RadialGradient(
                      center: Alignment(-0.25, -0.35),
                      radius: 0.95,
                      colors: [
                        Color(0xFFFFFFFF), // soft white highlight
                        Color(0xFFEDE9FE), // pale lavender
                        Color(0xFFE0E7FF), // soft periwinkle
                        Color(0xFFBAE6FD), // soft cyan edge
                      ],
                      stops: [0.0, 0.45, 0.75, 1.0],
                    ),
                    border: Border.all(
                      // Thin subtle iridescent outer border
                      color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                      width: 1.5,
                    ),
                    boxShadow: [
                      // Subtle rim illumination
                      BoxShadow(
                        color: const Color(0xFF818CF8).withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: const Color(0xFFF472B6).withValues(alpha: 0.20),
                        blurRadius: 20,
                        spreadRadius: -2,
                        offset: const Offset(4, -2),
                      ),
                    ],
                  ),
                  child: Center(
                    // 4. UNIFIED MORPHING VOICE NODES VISUALIZER
                    // Seamless pure code transformation:
                    // Listening / User Speaking / AI Speaking: Equalizer bars / flat dots
                    // Thinking: Nodes morph, expand, orbit in circle with glowing aurora colors, and return smoothly.
                    child: _MorphingVoiceNodesVisualizer(
                      callState: state.callState,
                      soundLevel: soundLevel,
                      isAiSpeaking: isAiSpeaking,
                      animValue: animValue,
                      isMuted: state.isMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
}

/// Unified 5-node interactive visualizer built entirely in pure Flutter code.
/// 
/// Behaviors:
/// 1. IDLE / LISTENING: 5 flat aligned dots.
/// 2. USER SPEAKING / AI SPEAKING: 5 vertical music bars reacting to speech intonation.
/// 3. THINKING (Morphing Animation):
///    - Dots merge & curve into a rotating circular orbit.
///    - Orbit expands outwards (radius 0px -> 26px).
///    - Colors transition smoothly to glowing iridescent aurora (Cyan -> Violet -> Pink).
///    - Dots rotate with gentle breathing harmonic wave.
///    - When thinking finishes, orbit shrinks back and aligns seamlessly into line dots/bars.
class _MorphingVoiceNodesVisualizer extends StatefulWidget {
  final CallState callState;
  final double soundLevel;
  final bool isAiSpeaking;
  final double animValue;
  final bool isMuted;

  const _MorphingVoiceNodesVisualizer({
    required this.callState,
    required this.soundLevel,
    required this.isAiSpeaking,
    required this.animValue,
    required this.isMuted,
  });

  @override
  State<_MorphingVoiceNodesVisualizer> createState() => _MorphingVoiceNodesVisualizerState();
}

class _MorphingVoiceNodesVisualizerState extends State<_MorphingVoiceNodesVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _morphController;
  late final Animation<double> _morphAnimation;

  static const double _dotSize = 5.0;
  static const List<double> _minHeights = [8.0, 12.0, 16.0, 12.0, 8.0];
  static const List<double> _maxHeights = [26.0, 42.0, 58.0, 42.0, 26.0];

  final List<double> _currentHeights = [_dotSize, _dotSize, _dotSize, _dotSize, _dotSize];

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _morphAnimation = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeInOutCubic,
    );

    if (widget.callState == CallState.thinking) {
      _morphController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _MorphingVoiceNodesVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.callState == CallState.thinking && oldWidget.callState != CallState.thinking) {
      _morphController.forward();
    } else if (widget.callState != CallState.thinking && oldWidget.callState == CallState.thinking) {
      _morphController.reverse();
    }

    _updatePhysics();
  }

  void _updatePhysics() {
    final double sound = widget.isMuted ? 0.0 : widget.soundLevel;
    final bool hasAudio = sound > 0.03 || (widget.isAiSpeaking && sound > 0.02);

    for (int i = 0; i < 5; i++) {
      double targetHeight;

      if (widget.callState == CallState.thinking) {
        // In thinking mode: nodes become circular dots
        targetHeight = _dotSize;
      } else if (!hasAudio || widget.isMuted) {
        // Silence / Idle: Flat dots
        targetHeight = _dotSize;
      } else if (widget.isAiSpeaking) {
        // AI Speaking: Dynamic vocal formant distribution & intonation contours
        // 5 nodes represent frequency bands across speech spectrum:
        // Node 0: Chest resonance / low fundamental (100-250 Hz)
        // Node 1: Pitch inflection / F0 contour (glide with Indonesian sentence intonation)
        // Node 2: First Formant F1 / Vowel energy (500-1000 Hz, peak acoustic power)
        // Node 3: Second Formant F2 / Articulation transitions (1.5-2.5 kHz)
        // Node 4: Sibilance / High treble energy (3-5 kHz)
        final double anim = widget.animValue;
        final double band0 = sound * (0.85 + 0.20 * math.sin(anim * 2 * math.pi * 3.5));
        final double band1 = sound * (1.15 + 0.28 * math.sin(anim * 2 * math.pi * 5.2 + 0.8));
        final double band2 = sound * (1.45 + 0.35 * math.sin(anim * 2 * math.pi * 7.0 + 1.6));
        final double band3 = sound * (1.15 + 0.26 * math.sin(anim * 2 * math.pi * 6.1 + 2.4));
        final double band4 = sound * (0.80 + 0.22 * math.sin(anim * 2 * math.pi * 8.4 + 3.2));

        final bands = [band0, band1, band2, band3, band4];
        final intonationScale = bands[i].clamp(0.0, 1.0);

        targetHeight = sound > 0.02
            ? _minHeights[i] + (intonationScale * (_maxHeights[i] - _minHeights[i]))
            : _dotSize;
      } else {
        // User speech
        final multipliers = [0.75, 1.1, 1.35, 1.05, 0.7];
        final variance = math.sin(widget.animValue * 2 * math.pi * 6.0 + (i * 1.5)) * 0.15;
        final intonationScale = (sound * multipliers[i] + variance).clamp(0.0, 1.0);
        targetHeight = _minHeights[i] + (intonationScale * (_maxHeights[i] - _minHeights[i]));
      }

      final isRising = targetHeight > _currentHeights[i];
      final factor = isRising
          ? (widget.isAiSpeaking ? 0.60 : 0.45)
          : (widget.isAiSpeaking ? 0.22 : 0.25);
      _currentHeights[i] += (targetHeight - _currentHeights[i]) * factor;
    }
  }

  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _morphController,
      builder: (context, child) {
        final morphValue = _morphAnimation.value;

        return SizedBox(
          width: 174,
          height: 174,
          child: ClipOval(
            child: RepaintBoundary(
              child: CustomPaint(
                size: const Size(174, 174),
                painter: _VoiceNodesMorphPainter(
                  morphProgress: morphValue,
                  animProgress: widget.animValue,
                  barHeights: List<double>.from(_currentHeights),
                  isThinking: widget.callState == CallState.thinking,
                  isMuted: widget.isMuted,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Profile containing harmonized color tokens for each of the 5 nodes,
/// tailored to Luna AI's pastel/periwinkle/lavender brand design system.
class _NodeColorProfile {
  final Color core;       // Saturated core tone
  final Color highlight;  // Lighter glowing highlight tone
  final Color ambient;    // Soft luminous dispersion tint
  const _NodeColorProfile(this.core, this.highlight, this.ambient);
}

/// CustomPainter that renders continuous morphing of the 5 nodes into an organic,
/// abstract swirling fluid gradient ball (inspired by flow_thinking.gif).
class _VoiceNodesMorphPainter extends CustomPainter {
  final double morphProgress;
  final double animProgress;
  final List<double> barHeights;
  final bool isThinking;
  final bool isMuted;

  _VoiceNodesMorphPainter({
    required this.morphProgress,
    required this.animProgress,
    required this.barHeights,
    required this.isThinking,
    required this.isMuted,
  });

  // 5 Color profiles aligned with Luna AI brand & the abstract fluid palette:
  // Node 0 (Left): Sky Cyan (Luna Tertiary)
  // Node 1 (Mid-Left): Electric Periwinkle (Luna Primary)
  // Node 2 (Center): Deep Violet Orchid
  // Node 3 (Mid-Right): Radiant Fuchsia Pink
  // Node 4 (Right): Sunset Coral Rose
  static const List<_NodeColorProfile> _profiles = [
    _NodeColorProfile(Color(0xFF0284C7), Color(0xFF38BDF8), Color(0xFFA7E6FF)),
    _NodeColorProfile(Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFFC7D2FE)),
    _NodeColorProfile(Color(0xFF7E22CE), Color(0xFFA855F7), Color(0xFFE9D5FF)),
    _NodeColorProfile(Color(0xFFDB2777), Color(0xFFF472B6), Color(0xFFFCE7F3)),
    _NodeColorProfile(Color(0xFFE11D48), Color(0xFFFB7185), Color(0xFFFFE4E6)),
  ];

  static const Color _defaultIndigo = Color(0xFF5358CB); // Luna Primary

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const int nodeCount = 5;
    const double barWidth = 4.8;
    const double lineSpacing = 10.5;

    // 1. FLUID ABSTRACT BACKGROUND BLEND (ACTIVE DURING THINKING)
    if (morphProgress > 0.01 && !isMuted) {
      // Soft atmospheric backdrop within the sphere (contained center spread)
      final backdropPaint = Paint()
        ..color = const Color(0xFFEDE9FE).withValues(alpha: 0.35 * morphProgress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16.0);
      canvas.drawCircle(center, 44.0 * morphProgress, backdropPaint);

      // Render the 5 expanding organic fluid lobes
      for (int i = 0; i < nodeCount; i++) {
        final profile = _profiles[i];
        // 1.0x integer revolution ensures 100% seamless continuity when loop repeats
        final double theta = (i * 2 * math.pi / nodeCount) + (animProgress * 2 * math.pi * 1.0);

        // Controlled Lissajous displacement with integer harmonic cycles
        final double lissajousX = math.cos(theta) * (18.0 + math.sin(animProgress * 2 * math.pi * 1.0 + i) * 4.0);
        final double lissajousY = math.sin(theta) * (16.0 + math.cos(animProgress * 2 * math.pi * 1.0 - i) * 4.0);
        final Offset linePos = Offset(center.dx + (i - 2) * lineSpacing, center.dy);
        final Offset orbitPos = center + Offset(lissajousX, lissajousY);
        final Offset lobeCenter = Offset.lerp(linePos, orbitPos, morphProgress)!;

        // Controlled fluid radius with 2.0x integer harmonic breathing wave
        final double baseRadius = Tween<double>(begin: 3.0, end: 38.0).transform(morphProgress);
        final double breathing = math.sin((animProgress * 2 * math.pi * 2.0) + (i * 1.3)) * 4.5 * morphProgress;
        final double lobeRadius = baseRadius + breathing;

        // Generate undulating organic fluid path (harmonic contour with integer wave cycles)
        final Path lobePath = Path();
        const int vertices = 16;
        for (int v = 0; v <= vertices; v++) {
          final double angle = (v / vertices) * 2 * math.pi;
          final double wave1 = math.sin((angle * 2.0) + (animProgress * 2 * math.pi * 2.0) + i) * 0.16;
          final double wave2 = math.cos((angle * 3.0) - (animProgress * 2 * math.pi * 1.0) + (i * 0.8)) * 0.10;
          final double r = lobeRadius * (1.0 + (wave1 + wave2) * morphProgress);
          final double vx = lobeCenter.dx + r * math.cos(angle);
          final double vy = lobeCenter.dy + r * math.sin(angle);
          if (v == 0) {
            lobePath.moveTo(vx, vy);
          } else {
            lobePath.lineTo(vx, vy);
          }
        }
        lobePath.close();

        // Multi-stop radial gradient for silky fluid density
        final lobePaint = Paint()
          ..shader = RadialGradient(
            center: Alignment(
              -0.20 * math.cos(theta),
              -0.20 * math.sin(theta),
            ),
            radius: 0.90,
            colors: [
              profile.highlight.withValues(alpha: 0.82 * morphProgress),
              profile.core.withValues(alpha: 0.62 * morphProgress),
              profile.ambient.withValues(alpha: 0.22 * morphProgress),
              profile.core.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.42, 0.75, 1.0],
          ).createShader(Rect.fromCircle(center: lobeCenter, radius: lobeRadius * 1.2))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0 * morphProgress);

        canvas.drawPath(lobePath, lobePaint);
      }

      // 2. CURVING FLUID SILK RIBBONS (with 1.0x integer revolution and synchronous sweep)
      final ribbonProgress = (morphProgress - 0.15).clamp(0.0, 0.85) / 0.85;
      if (ribbonProgress > 0.02) {
        final double ribbonAngle = animProgress * 2 * math.pi * 1.0;
        final Path ribbon1 = Path();
        ribbon1.moveTo(
          center.dx + 42 * math.cos(ribbonAngle),
          center.dy + 42 * math.sin(ribbonAngle),
        );
        ribbon1.quadraticBezierTo(
          center.dx + 16 * math.cos(ribbonAngle + 1.8),
          center.dy + 16 * math.sin(ribbonAngle + 1.8),
          center.dx + 42 * math.cos(ribbonAngle + math.pi),
          center.dy + 42 * math.sin(ribbonAngle + math.pi),
        );

        final ribbonPaint1 = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9.0 * ribbonProgress
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            center: Alignment.center,
            startAngle: ribbonAngle,
            endAngle: ribbonAngle + (2 * math.pi),
            colors: [
              _profiles[0].highlight.withValues(alpha: 0.45 * ribbonProgress),
              _profiles[2].highlight.withValues(alpha: 0.45 * ribbonProgress),
              _profiles[3].highlight.withValues(alpha: 0.40 * ribbonProgress),
              _profiles[0].highlight.withValues(alpha: 0.45 * ribbonProgress),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: 46.0))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.0 * ribbonProgress);

        canvas.drawPath(ribbon1, ribbonPaint1);
      }

      // 3. SPECULAR GLASS GLARE OVERLAY
      final glarePaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.70,
          colors: [
            Colors.white.withValues(alpha: 0.35 * morphProgress),
            Colors.white.withValues(alpha: 0.08 * morphProgress),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: 54.0));
      canvas.drawCircle(center, 52.0, glarePaint);
    }

    // 4. THE 5 EQUALIZER NODES (SMOOTHLY FADE OUT DURING THINKING FLUID STATE)
    final double nodeOpacity = (1.0 - (morphProgress * 1.4)).clamp(0.0, 1.0);
    if (nodeOpacity > 0.01) {
      for (int i = 0; i < nodeCount; i++) {
        final double lineX = center.dx + (i - 2) * lineSpacing;
        final double lineY = center.dy;
        final currentCenter = Offset(lineX, lineY);

        final double targetHeight = barHeights[i];
        final Color nodeColor = isMuted
            ? const Color(0xFF94A3B8).withValues(alpha: nodeOpacity)
            : _defaultIndigo.withValues(alpha: nodeOpacity);

        final rRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: currentCenter,
            width: barWidth,
            height: targetHeight.clamp(barWidth, 60.0),
          ),
          const Radius.circular(999),
        );

        final nodePaint = Paint()
          ..color = nodeColor
          ..style = PaintingStyle.fill;

        canvas.drawRRect(rRect, nodePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceNodesMorphPainter oldDelegate) {
    if (oldDelegate.morphProgress != morphProgress ||
        oldDelegate.animProgress != animProgress ||
        oldDelegate.isThinking != isThinking ||
        oldDelegate.isMuted != isMuted) {
      return true;
    }
    if (oldDelegate.barHeights.length != barHeights.length) return true;
    for (int i = 0; i < barHeights.length; i++) {
      if ((oldDelegate.barHeights[i] - barHeights[i]).abs() > 0.1) {
        return true;
      }
    }
    return false;
  }
}

/// CustomPainter that renders radial frequency audio equalizer bars around the orb perimeter,
/// matching the exact visual style from the reference video (istockphoto-2265409964).
/// When silent, all radial bars shrink to zero / tiny baseline dots.
class _RadialFrequencyBarsPainter extends CustomPainter {
  final double animationProgress;
  final double soundLevel;
  final bool isAiSpeaking;
  final bool isMuted;

  _RadialFrequencyBarsPainter({
    required this.animationProgress,
    required this.soundLevel,
    required this.isAiSpeaking,
    required this.isMuted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isMuted || !isAiSpeaking) return;

    final center = Offset(size.width / 2, size.height / 2);
    const baseRadius = 89.0; // Starts right at outer perimeter of the 174px orb
    const totalPoints = 72; // High resolution points around 360 degrees for silky curves

    final double masterIntensity = (soundLevel * 1.15).clamp(0.0, 1.0);
    if (masterIntensity <= 0.01) return;

    final points = <Offset>[];
    final innerEchoPoints = <Offset>[];

    for (int i = 0; i < totalPoints; i++) {
      final double theta = (i / totalPoints) * 2 * math.pi;

      final double harmonicCluster1 = math.sin(theta * 2.0 - 0.5);
      final double harmonicCluster2 = math.cos(theta * 3.0 + 1.2);
      final double clusterFactor = ((harmonicCluster1 * 0.7 + harmonicCluster2 * 0.3).abs()).clamp(0.0, 1.0);

      final double freqJitter = ((math.sin((i * 7.7) + (animationProgress * 2 * math.pi * 5.0)) + 1.0) / 2.0);

      final double spikeFactor = math.pow(clusterFactor, 2.2).toDouble();
      final double dynamicHeight = (masterIntensity * 42.0 * (0.25 + (spikeFactor * 0.75))) * (0.6 + freqJitter * 0.4);

      final double barLength = 2.0 + dynamicHeight;
      final double currentRadius = baseRadius + barLength;

      final double endX = center.dx + currentRadius * math.cos(theta);
      final double endY = center.dy + currentRadius * math.sin(theta);
      points.add(Offset(endX, endY));

      // Subtle inner harmonic wave for depth
      final double innerRadius = baseRadius + (barLength * 0.5);
      final double innerX = center.dx + innerRadius * math.cos(theta);
      final double innerY = center.dy + innerRadius * math.sin(theta);
      innerEchoPoints.add(Offset(innerX, innerY));
    }

    // 1. Build Outer Wavy Path (Smooth closed quadratic bezier)
    final outerPath = Path();
    final n = points.length;
    final firstMid = Offset(
      (points[n - 1].dx + points[0].dx) / 2,
      (points[n - 1].dy + points[0].dy) / 2,
    );
    outerPath.moveTo(firstMid.dx, firstMid.dy);

    for (int i = 0; i < n; i++) {
      final next = points[(i + 1) % n];
      final mid = Offset(
        (points[i].dx + next.dx) / 2,
        (points[i].dy + next.dy) / 2,
      );
      outerPath.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    outerPath.close();

    // 2. Build Inner Echo Wavy Path
    final innerPath = Path();
    final innerFirstMid = Offset(
      (innerEchoPoints[n - 1].dx + innerEchoPoints[0].dx) / 2,
      (innerEchoPoints[n - 1].dy + innerEchoPoints[0].dy) / 2,
    );
    innerPath.moveTo(innerFirstMid.dx, innerFirstMid.dy);

    for (int i = 0; i < n; i++) {
      final next = innerEchoPoints[(i + 1) % n];
      final mid = Offset(
        (innerEchoPoints[i].dx + next.dx) / 2,
        (innerEchoPoints[i].dy + next.dy) / 2,
      );
      innerPath.quadraticBezierTo(innerEchoPoints[i].dx, innerEchoPoints[i].dy, mid.dx, mid.dy);
    }
    innerPath.close();

    final bounds = Rect.fromCircle(center: center, radius: baseRadius + 48.0);

    // Render soft glowing backdrop for the wavy perimeter
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..color = const Color(0xFFA855F7).withValues(alpha: (0.35 * masterIntensity).clamp(0.0, 0.6))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawPath(outerPath, glowPaint);

    // Render inner echo wave
    final echoPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFC084FC).withValues(alpha: (0.35 * masterIntensity).clamp(0.0, 0.5));
    canvas.drawPath(innerPath, echoPaint);

    // Render crisp primary wavy outer line with sweeping gradient
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.4
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFA855F7), // Purple
          Color(0xFFE879F9), // Fuchsia / Magenta
          Color(0xFF818CF8), // Indigo / Violet
          Color(0xFFA855F7), // Purple loop
        ],
      ).createShader(bounds);

    canvas.drawPath(outerPath, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _RadialFrequencyBarsPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.soundLevel != soundLevel ||
        oldDelegate.isAiSpeaking != isAiSpeaking ||
        oldDelegate.isMuted != isMuted;
  }
}
