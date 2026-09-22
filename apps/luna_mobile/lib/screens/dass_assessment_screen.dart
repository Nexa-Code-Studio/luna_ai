import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/utils/responsive_layout_helper.dart';
import '../features/dass/domain/entities/dass_assessment_entity.dart';
import '../features/dass/presentation/providers/dass_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/skeleton_shimmer.dart';
import '../widgets/staggered_entrance.dart';

class DASSAssessmentScreen extends ConsumerStatefulWidget {
  final String initialPeriod;

  const DASSAssessmentScreen({
    super.key,
    this.initialPeriod = 'today',
  });

  @override
  ConsumerState<DASSAssessmentScreen> createState() => _DASSAssessmentScreenState();
}

class _DASSAssessmentScreenState extends ConsumerState<DASSAssessmentScreen> {
  late String _currentPeriod;
  String _selectedFilter = 'all'; // 'all', 'stress', 'anxiety', 'depression'
  final Set<int> _expandedItemIds = {};

  @override
  void initState() {
    super.initState();
    _currentPeriod = widget.initialPeriod;
  }

  Color _getScaleColor(String scale) {
    switch (scale.toLowerCase()) {
      case 'depression':
        return const Color(0xFF74B9FF);
      case 'anxiety':
        return const Color(0xFF6C63FF);
      case 'stress':
      default:
        return const Color(0xFFFF7675);
    }
  }

  String _getScaleLabel(String scale) {
    switch (scale.toLowerCase()) {
      case 'depression':
        return 'Depresi';
      case 'anxiety':
        return 'Kecemasan';
      case 'stress':
      default:
        return 'Stres';
    }
  }

  Color _getConfidenceColor(double conf) {
    if (conf >= 0.80) return const Color(0xFF059669); // Emerald
    if (conf >= 0.50) return const Color(0xFFD97706); // Amber
    return const Color(0xFF6366F1); // Indigo / Slate
  }

  Color _getConfidenceBg(double conf) {
    if (conf >= 0.80) return const Color(0xFFECFDF5);
    if (conf >= 0.50) return const Color(0xFFFFFBEB);
    return const Color(0xFFF5F3FF);
  }

  String _getConfidenceLabel(double conf) {
    if (conf >= 0.80) return 'Keyakinan Tinggi';
    if (conf >= 0.50) return 'Keyakinan Cukup';
    return 'Indikasi Awal';
  }

  @override
  Widget build(BuildContext context) {
    final dassState = ref.watch(dassAssessmentNotifierProvider);
    final notifier = ref.read(dassAssessmentNotifierProvider.notifier);
    final isEditable = _currentPeriod == 'today';

    final currentAssessment = dassState.assessment.asData?.value;
    final staged = dassState.stagedScores;
    final bool hasChanges = isEditable &&
        currentAssessment != null &&
        currentAssessment.items.any((it) => (staged[it.itemId] ?? it.score) != it.score);
    final int changedCount = currentAssessment != null
        ? currentAssessment.items.where((it) => (staged[it.itemId] ?? it.score) != it.score).length
        : 0;
    final bool isUnverified = currentAssessment != null && !currentAssessment.verifiedByUser;
    final bool showSaveBar = isEditable && currentAssessment != null && (hasChanges || isUnverified);

    return Scaffold(
      body: Stack(
        children: [
          Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF6F8FF),
              Color(0xFFEFF2FE),
              Color(0xFFF8F9FE),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              StaggeredEntrance(
                index: 0,
                child: _buildTopBar(context, notifier),
              ),

              // Period Tab Selector (Hari Ini | Minggu Ini | Bulan Ini)
              StaggeredEntrance(
                index: 1,
                child: _buildPeriodSelector(),
              ),

              // Main Content
              Expanded(
                child: dassState.assessment.when(
                  loading: () => const _DassSkeletonLoader(),
                  error: (err, _) => RefreshIndicator(
                    onRefresh: () => notifier.loadTodayAssessment(),
                    color: AppColors.primary,
                    backgroundColor: Colors.white,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 44),
                              const SizedBox(height: 12),
                              Text(
                                'Gagal memuat asesmen DASS-21',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E1B4B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$err',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.redAccent),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => notifier.loadTodayAssessment(),
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Coba Lagi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  data: (assessment) {
                    final staged = dassState.stagedScores;

                    // Filter items according to subscale chip
                    final filteredItems = assessment.items.where((it) {
                      if (_selectedFilter == 'all') return true;
                      return it.scale.toLowerCase() == _selectedFilter.toLowerCase();
                    }).toList();

                    return RefreshIndicator(
                      onRefresh: () => notifier.loadTodayAssessment(),
                      color: AppColors.primary,
                      backgroundColor: Colors.white,
                      displacement: 24,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        children: [
                          // Mode Banner (Editable vs Read-Only)
                          StaggeredEntrance(
                            index: 2,
                            child: _buildModeBanner(isEditable),
                          ),
                          const SizedBox(height: 16),

                          // Subscale 3 Pillars Summary Card
                          StaggeredEntrance(
                            index: 3,
                            child: _buildSubscalesCard(assessment, staged),
                          ),
                          const SizedBox(height: 16),

                          // Subscale Filter Chips (Semua 21 | Stres | Cemas | Depresi)
                          StaggeredEntrance(
                            index: 4,
                            child: _buildFilterChips(assessment.items.length),
                          ),
                          const SizedBox(height: 16),

                          // 21 Questions List
                          StaggeredEntrance(
                            index: 5,
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredItems.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                final currentScore = staged[item.itemId] ?? item.score;
                                return _buildQuestionCard(item, currentScore, isEditable, notifier);
                              },
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // Animated Slide-Up Floating Save Bar
      _buildFloatingSaveBar(
        showSaveBar,
        hasChanges,
        isUnverified,
        changedCount,
        dassState,
        notifier,
      ),
    ],
  ),
);
  }

  Widget _buildFloatingSaveBar(
    bool showSaveBar,
    bool hasChanges,
    bool isUnverified,
    int changedCount,
    DASSAssessmentState dassState,
    DASSAssessmentNotifier notifier,
  ) {
    final String titleText = hasChanges
        ? '$changedCount Butir Diubah'
        : (isUnverified ? 'Sintesis AI Siap' : 'Asesmen Tersimpan');
    final String subtitleText = hasChanges
        ? 'Simpan koreksi asesmen'
        : (isUnverified ? 'Simpan asesmen hari ini' : 'Skor telah terverifikasi');
    final String buttonText = 'Simpan';
    final IconData barIcon = hasChanges ? Icons.edit_note_rounded : Icons.check_circle_outline_rounded;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: IgnorePointer(
        ignoring: !showSaveBar,
        child: AnimatedSlide(
          offset: showSaveBar ? Offset.zero : const Offset(0, 2.0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: showSaveBar ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B4B),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E1B4B).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    barIcon,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: dassState.isSaving
                      ? null
                      : () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          final success = await notifier.saveAssessment();
                          if (!mounted) return;
                          if (success) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Asesmen DASS-21 hari ini berhasil diverifikasi dan disimpan!',
                                  style: GoogleFonts.plusJakartaSans(),
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: dassState.isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          buttonText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, DASSAssessmentNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E1B4B)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lembar Evaluasi DASS-21',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
                Text(
                  'Depression Anxiety Stress Scale (21 Butir)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF7C3AED), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Konfirmasi Ekstraksi AI',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E1B4B),
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    'Apakah Anda yakin ingin memicu analisis AI untuk mengekstrak 21 butir DASS-21 dari riwayat percakapan hari ini?\n\n'
                    'Proses ini akan menganalisis transkrip percakapan terbaru untuk mendeteksi indikator emosi Anda.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF4B5563),
                      height: 1.45,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx, false),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(dialogCtx, true),
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: Text(
                        'Ekstrak Sekarang',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm != true || !mounted) return;

              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Menganalisis dan mengekstrak DASS-21 dari riwayat dialog hari ini...',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              await notifier.extractTodayAssessment();
            },
            icon: const Icon(Icons.auto_awesome, size: 20, color: Color(0xFF7C3AED)),
            tooltip: 'Ekstrak AI dari Percakapan Hari Ini',
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = [
      {'key': 'today', 'label': 'Hari Ini'},
      {'key': 'week', 'label': 'Minggu Ini'},
      {'key': 'month', 'label': 'Bulan Ini'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: periods.map((p) {
          final isSelected = p['key'] == _currentPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentPeriod = p['key']!;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    p['label']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF1E1B4B) : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModeBanner(bool isEditable) {
    if (isEditable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F4EA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF34A853).withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.edit_note_rounded, color: Color(0xFF137333), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tinjau bukti obrolan dan koreksi nilai (0–3) jika diperlukan.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF137333),
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0FE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1A73E8).withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline_rounded, color: Color(0xFF1A73E8), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Mode Riwayat Agregat (Hanya Baca): Menampilkan akumulasi rata-rata indikator pada rentang ini. Pengeditan hanya dapat dilakukan pada asesmen Hari Ini.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF1A73E8),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSubscalesCard(DASSAssessmentEntity assessment, Map<int, int> stagedScores) {
    int strRaw = 0, anxRaw = 0, depRaw = 0;

    for (final item in assessment.items) {
      final s = stagedScores[item.itemId] ?? item.score;
      if (item.scale == 'stress') strRaw += s;
      if (item.scale == 'anxiety') anxRaw += s;
      if (item.scale == 'depression') depRaw += s;
    }

    final int stressScore = strRaw * 2;
    final int anxietyScore = anxRaw * 2;
    final int depressionScore = depRaw * 2;

    final stressSev = _getIndonesianSeverity('stress', stressScore);
    final anxietySev = _getIndonesianSeverity('anxiety', anxietyScore);
    final depressionSev = _getIndonesianSeverity('depression', depressionScore);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Skor 3 Dimensi DASS-21',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: context.responsiveFont(14),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showDassInfoDialog(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F0FE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    size: 15,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _buildSubscaleTile(
                  context,
                  'Stres',
                  stressScore,
                  stressSev,
                  'stress',
                ),
                const SizedBox(width: 8),
                _buildSubscaleTile(
                  context,
                  'Kecemasan',
                  anxietyScore,
                  anxietySev,
                  'anxiety',
                ),
                const SizedBox(width: 8),
                _buildSubscaleTile(
                  context,
                  'Depresi',
                  depressionScore,
                  depressionSev,
                  'depression',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getIndonesianSeverity(String scale, int score) {
    if (scale == 'depression') {
      if (score >= 28) return 'Sangat Berat';
      if (score >= 21) return 'Berat';
      if (score >= 14) return 'Sedang';
      if (score >= 10) return 'Ringan';
      return 'Normal';
    } else if (scale == 'anxiety') {
      if (score >= 20) return 'Sangat Berat';
      if (score >= 15) return 'Berat';
      if (score >= 10) return 'Sedang';
      if (score >= 8) return 'Ringan';
      return 'Normal';
    } else {
      if (score >= 34) return 'Sangat Berat';
      if (score >= 26) return 'Berat';
      if (score >= 19) return 'Sedang';
      if (score >= 15) return 'Ringan';
      return 'Normal';
    }
  }

  Color _getScoreColor(String severityIndo) {
    switch (severityIndo) {
      case 'Sangat Berat':
        return const Color(0xFFD32F2F);
      case 'Berat':
        return const Color(0xFFE65100);
      case 'Sedang':
        return const Color(0xFFF57C00);
      case 'Ringan':
        return const Color(0xFFFBC02D);
      case 'Normal':
      default:
        return const Color(0xFF2E7D32);
    }
  }

  Widget _buildSubscaleTile(
    BuildContext context,
    String label,
    int score,
    String severityIndo,
    String scaleType,
  ) {
    final scoreColor = _getScoreColor(severityIndo);
    final bool isExtremelySevere = severityIndo == 'Sangat Berat';

    final Color bgColor = isExtremelySevere
        ? const Color(0xFFD32F2F)
        : scoreColor.withValues(alpha: 0.08);

    final Color labelColor = isExtremelySevere ? Colors.white70 : scoreColor;

    return Expanded(
      child: BouncingButton(
        onTap: () {
          if (isExtremelySevere) {
            _showPsychologistReferralModal(context, label, score, scaleType);
          } else {
            _showSubscaleInfoModal(context, label, score, severityIndo, scaleType);
          }
        },
        scaleFactor: 0.94,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isExtremelySevere
                  ? const Color(0xFFB71C1C)
                  : scoreColor.withValues(alpha: 0.25),
              width: isExtremelySevere ? 1.5 : 1,
            ),
            boxShadow: isExtremelySevere
                ? [
                    BoxShadow(
                      color: const Color(0xFFD32F2F).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isExtremelySevere) ...[
                    const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.white),
                    const SizedBox(width: 3),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$score',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isExtremelySevere ? Colors.white : scoreColor,
                    ),
                  ),
                  Text(
                    '/42',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isExtremelySevere ? Colors.white70 : AppColors.textLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isExtremelySevere
                      ? Colors.white.withValues(alpha: 0.2)
                      : scoreColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  severityIndo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: isExtremelySevere ? Colors.white : scoreColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(int totalCount) {
    final filters = [
      {'key': 'all', 'label': 'Semua ($totalCount)'},
      {'key': 'stress', 'label': 'Stres (7)'},
      {'key': 'anxiety', 'label': 'Kecemasan (7)'},
      {'key': 'depression', 'label': 'Depresi (7)'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: BouncingButton(
              onTap: () {
                if (!isSelected) {
                  setState(() {
                    _selectedFilter = f['key']!;
                  });
                }
              },
              scaleFactor: 0.92,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  f['label']!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF4B5563),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuestionCard(
    DASSItemEntity item,
    int currentScore,
    bool isEditable,
    DASSAssessmentNotifier notifier,
  ) {
    final scaleColor = _getScaleColor(item.scale);
    final scaleLabel = _getScaleLabel(item.scale);
    final isAnsweredByAI = item.confidence > 0 ||
        (item.evidence != null && item.evidence!.trim().isNotEmpty) ||
        (item.reason != null && item.reason!.trim().isNotEmpty);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Number & Subscale Tag
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scaleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Item ${item.itemId} • $scaleLabel',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scaleColor,
                  ),
                ),
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (item.isUserEdited || (isEditable && item.score != currentScore))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Telah Dikoreksi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  if (isEditable && item.score != currentScore && isAnsweredByAI)
                    GestureDetector(
                      onTap: () => notifier.updateScore(item.itemId, item.score),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.undo_rounded, size: 10, color: Color(0xFF4B5563)),
                            const SizedBox(width: 3),
                            Text(
                              'Saran AI (${item.score})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (isAnsweredByAI) _buildAIAnalysisIconButton(item),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Question Text
          Text(
            item.questionText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
              height: 1.35,
            ),
          ),

          // Explainable AI Accordion (Evidence, Confidence, Reason)
          if (isAnsweredByAI) _buildAIAnalysisSection(item),

          const SizedBox(height: 12),

          // Likert Selector Options (0 - 3)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _buildLikertButton(0, '0: Tdk Ada', currentScore == 0, isEditable, () => notifier.updateScore(item.itemId, 0)),
                const SizedBox(width: 6),
                _buildLikertButton(1, '1: Kadang', currentScore == 1, isEditable, () => notifier.updateScore(item.itemId, 1)),
                const SizedBox(width: 6),
                _buildLikertButton(2, '2: Sering', currentScore == 2, isEditable, () => notifier.updateScore(item.itemId, 2)),
                const SizedBox(width: 6),
                _buildLikertButton(3, '3: Selalu', currentScore == 3, isEditable, () => notifier.updateScore(item.itemId, 3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysisIconButton(DASSItemEntity item) {
    final isExpanded = _expandedItemIds.contains(item.itemId);
    final conf = item.confidence;
    final confColor = _getConfidenceColor(conf);
    final confBg = _getConfidenceBg(conf);
    final confPercent = (conf * 100).round();

    return Tooltip(
      message: isExpanded
          ? 'Tutup Analisis AI'
          : (conf > 0 ? 'Analisis Luna ($confPercent% Yakin)' : 'Lihat Analisis Luna'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedItemIds.remove(item.itemId);
              } else {
                _expandedItemIds.add(item.itemId);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isExpanded ? confBg : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(
                color: isExpanded ? confColor.withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 15,
              color: isExpanded ? confColor : const Color(0xFF6366F1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIAnalysisSection(DASSItemEntity item) {
    final isExpanded = _expandedItemIds.contains(item.itemId);
    final hasEvidence = item.evidence != null && item.evidence!.trim().isNotEmpty;
    final hasReason = item.reason != null && item.reason!.trim().isNotEmpty;
    final conf = item.confidence;
    final confPercent = (conf * 100).round();
    final confColor = _getConfidenceColor(conf);
    final confBg = _getConfidenceBg(conf);
    final confLabel = _getConfidenceLabel(conf);

    return _AIAnalysisAccordion(
      isExpanded: isExpanded,
      item: item,
      confBg: confBg,
      confColor: confColor,
      confPercent: confPercent,
      confLabel: confLabel,
      hasEvidence: hasEvidence,
      hasReason: hasReason,
    );
  }

  Widget _buildLikertButton(
    int score,
    String label,
    bool isSelected,
    bool isEditable,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: BouncingButton(
          onTap: isEditable ? onTap : null,
          scaleFactor: 0.92,
          child: AnimatedScale(
            scale: isSelected ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isEditable ? Colors.white : const Color(0xFFF3F4F6)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isEditable ? const Color(0xFFD1D5DB) : const Color(0xFFE5E7EB)),
                  width: isSelected ? 1.8 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isEditable ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF)),
                  ),
                  child: Text(label),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDassInfoDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Color(0xFFD1D5DB), width: 1),
      ),
      builder: (ctx) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Panduan Skala DASS-21',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'DASS-21 (Depression Anxiety Stress Scales) mengukur 3 indikator psikologis harian (0–42 poin per subskala) dari transkrip percakapanmu bersama Luna AI.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'KATEGORI WARNA & TINGKAT KEPARAHAN:',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              _buildLegendRow('Normal', 'Kondisi emosi stabil & terkendali.', const Color(0xFF2E7D32)),
              _buildLegendRow('Ringan (Mild)', 'Fluktuasi emosi ringan harian.', const Color(0xFFFBC02D)),
              _buildLegendRow('Sedang (Moderate)', 'Mulai mengganggu kenyamanan & butuh jeda istirahat.', const Color(0xFFF57C00)),
              _buildLegendRow('Berat (Severe)', 'Beban emosional terasa berat & perlu perhatian khusus.', const Color(0xFFE65100)),
              _buildLegendRow('Sangat Berat (Extremely Severe)', 'Indikasi krisis — sangat disarankan konsultasi ke psikolog/psikiater.', const Color(0xFFD32F2F)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Saya Mengerti'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendRow(String label, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Text(
              desc,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscaleInfoModal(
    BuildContext context,
    String label,
    int score,
    String severityIndo,
    String scaleType,
  ) {
    final scoreColor = _getScoreColor(severityIndo);
    String definition = '';
    String tip = '';

    if (scaleType == 'depression') {
      definition =
          'Subskala Depresi mengukur tingkat suasana hati disforik, hilangnya motivasi/inisiatif, anhedonia (kesulitan merasakan hal positif), dan perasaan ketidakberhargaan.';
      tip =
          'Coba lakukan aktivitas kecil yang kamu sukai, luapkan pikiran melalui percakapan bersama LUNA, atau jalan santai menghirup udara segar.';
    } else if (scaleType == 'anxiety') {
      definition =
          'Subskala Kecemasan mengukur stimulasi otonomik (otot tegang, detak jantung kencang), cemas situasional, dan ketakutan akan kehilangan kendali.';
      tip =
          'Lakukan teknik pernapasan 4-7-8 atau relaksasi otot bertahap untuk menurunkan stimulasi fisik berlebih.';
    } else {
      definition =
          'Subskala Stres mengukur ketegangan syaraf non-spesifik, reaksi berlebihan pada masalah harian, kegelisahan, dan ketidakmampuan untuk bersantai.';
      tip =
          'Ambil jeda istirahat dari pekerjaan/tugas, hindari multitasking berlebih, dan nikmati minuman hangat.';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Color(0xFFD1D5DB), width: 1),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: scoreColor,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$score / 42 Poin',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Tingkat Keparahan: ',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
                Text(
                  severityIndo,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFEADBFF)),
            const SizedBox(height: 14),
            Text(
              'PENJELASAN INDIKATOR:',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              definition,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, height: 1.45),
            ),
            const SizedBox(height: 14),
            Text(
              'REKOMENDASI MANDIRI:',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: Text(
                tip,
                style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textPrimary, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPsychologistReferralModal(
    BuildContext context,
    String label,
    int score,
    String scaleType,
  ) {
    String detailExplanation = '';

    if (scaleType == 'depression') {
      detailExplanation =
          'Sistem mencatat tingkat Depresi pengguna pada kategori Sangat Berat (Extremely Severe). Kondisi ini dicirikan oleh anhedonia total (kehilangan kemampuan merasakan hal positif), perasaan tidak berharga mendalam, serta keletihan fisik dan emosional yang signifikan.\n\n'
          '⚠️ Catatan Penting: Luna AI adalah pendamping mandiri dan bukan pengganti diagnosis atau terapi medis klinis. Kamu sangat disarankan untuk berbicara langsung dengan Psikolog Klinis atau Psikiater.';
    } else if (scaleType == 'anxiety') {
      detailExplanation =
          'Sistem mencatat tingkat Kecemasan pengguna pada kategori Sangat Berat (Extremely Severe). Kondisi ini ditandai dengan serangan panik intens, detak jantung kencang tanpa alasan fisik, guncangan rasa takut akut, atau kekhawatiran melumpuhkan harian.\n\n'
          '⚠️ Catatan Penting: Gejala kecemasan akut membutuhkan penanganan profesional medis. Sangat disarankan untuk segera menemui Psikolog Klinis atau Psikiater terdekat.';
    } else {
      detailExplanation =
          'Sistem mencatat tingkat Stres pengguna pada kategori Sangat Berat (Extremely Severe). Kondisi ini mengindikasikan burnout ekstrem, ketegangan saraf kronis, kelelahan energi berat, serta keputusasaan dalam menangani tekanan harian.\n\n'
          '⚠️ Catatan Penting: Beban stres kronis dapat berdampak pada kesehatan fisik. Disarankan untuk mengambil jeda penuh dan melakukan sesi konseling bersama psikolog profesional.';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Color(0xFFD1D5DB), width: 1),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SANGAT BERAT (EXTREMELY SEVERE)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFD32F2F),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Indikasi $label: $score / 42 Poin',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFB71C1C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'PENJELASAN KLINIS & REKOMENDASI:',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detailExplanation,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openWhatsappEmergency();
                },
                icon: const Icon(Icons.chat_outlined, size: 20),
                label: Text(
                  'Konsultasi via WhatsApp Psikolog / Krisis',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Tutup Penjelasan',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const String _whatsappEmergencyUrl =
      'https://api.whatsapp.com/send/?phone=6281380073120&text=halo%20kak%2C%20saya%20ingin%20bercerita%20mengenai...&type=phone_number&app_absent=0';

  Future<void> _openWhatsappEmergency() async {
    final uri = Uri.parse(_whatsappEmergencyUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat membuka WhatsApp Konseling Krisis'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }


}

class _AIAnalysisAccordion extends StatefulWidget {
  final bool isExpanded;
  final DASSItemEntity item;
  final Color confBg;
  final Color confColor;
  final int confPercent;
  final String confLabel;
  final bool hasEvidence;
  final bool hasReason;

  const _AIAnalysisAccordion({
    required this.isExpanded,
    required this.item,
    required this.confBg,
    required this.confColor,
    required this.confPercent,
    required this.confLabel,
    required this.hasEvidence,
    required this.hasReason,
  });

  @override
  State<_AIAnalysisAccordion> createState() => _AIAnalysisAccordionState();
}

class _AIAnalysisAccordionState extends State<_AIAnalysisAccordion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _AIAnalysisAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.isDismissed && !widget.isExpanded) {
          return const SizedBox.shrink();
        }
        return ClipRect(
          child: SizeTransition(
            sizeFactor: _expandAnimation,
            alignment: Alignment.topCenter,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: child,
              ),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Confidence Meter Bar
            Row(
              children: [
                Text(
                  'Tingkat Keyakinan AI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.confBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: widget.confColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${widget.confPercent}% • ${widget.confLabel}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: widget.confColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 5,
                width: double.infinity,
                color: const Color(0xFFE2E8F0),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: widget.item.confidence.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.confColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // 2. AI Evidence Quote (if present)
            if (widget.hasEvidence) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote_rounded, size: 16, color: Color(0xFF6366F1)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bukti Obrolan Pengguna:',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '"${widget.item.evidence}"',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF1E293B),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 3. AI Rationale / Reason (if present)
            if (widget.hasReason) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.psychology_alt_rounded, size: 16, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Penalaran AI Luna:',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6D28D9),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.item.reason!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF334155),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (!widget.hasEvidence) ...[
              const SizedBox(height: 8),
              Text(
                'Tidak ditemukan indikasi keluhan pada transkrip obrolan hari ini (Skor 0).',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],

            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Pilihan ini dianalisis otomatis. Kamu dapat mengoreksi skor kapan saja di bawah.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;

  const BouncingButton({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.94,
  });

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 110),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

/// Shimmer skeleton loader for the DASS-21 Assessment Screen.
class _DassSkeletonLoader extends StatelessWidget {
  const _DassSkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmerHost(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Three Score Summary Cards (Depresi, Kecemasan, Stres)
            Row(
              children: List.generate(
                3,
                (index) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      left: index == 0 ? 0 : 4,
                      right: index == 2 ? 0 : 4,
                    ),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      child: Column(
                        children: const [
                          SkeletonCircle(size: 32),
                          SizedBox(height: 8),
                          SkeletonLine(width: 50, height: 12),
                          SizedBox(height: 6),
                          SkeletonLine(width: 40, height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 2. Main Clinical Insight Card Skeleton
            GlassCard(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SkeletonCircle(size: 40),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SkeletonLine(width: 140, height: 16),
                          SizedBox(height: 6),
                          SkeletonLine(width: 90, height: 12),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SkeletonLine(width: double.infinity, height: 13),
                  const SizedBox(height: 8),
                  const SkeletonLine(width: 240, height: 13),
                  const SizedBox(height: 16),
                  const SkeletonBox(width: double.infinity, height: 40, borderRadius: 10),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3. Question Item Preview Skeletons
            ...List.generate(
              2,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GlassCard(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const SkeletonBox(width: 28, height: 28, borderRadius: 6),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            SkeletonLine(width: 160, height: 14),
                            SizedBox(height: 6),
                            SkeletonLine(width: 110, height: 11),
                          ],
                        ),
                      ),
                    ],
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
