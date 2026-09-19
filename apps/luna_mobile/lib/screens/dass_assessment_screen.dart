import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../features/dass/domain/entities/dass_assessment_entity.dart';
import '../features/dass/presentation/providers/dass_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

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
              _buildTopBar(context, notifier),

              // Period Tab Selector (Hari Ini | Minggu Ini | Bulan Ini)
              _buildPeriodSelector(),

              // Main Content
              Expanded(
                child: dassState.assessment.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
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
                  ),
                  data: (assessment) {
                    final staged = dassState.stagedScores;

                    // Filter items according to subscale chip
                    final filteredItems = assessment.items.where((it) {
                      if (_selectedFilter == 'all') return true;
                      return it.scale.toLowerCase() == _selectedFilter.toLowerCase();
                    }).toList();

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      children: [
                        // Mode Banner (Editable vs Read-Only)
                        _buildModeBanner(isEditable),
                        const SizedBox(height: 16),

                        // Subscale 3 Pillars Summary Card
                        _buildSubscalesCard(assessment),
                        const SizedBox(height: 16),

                        // Subscale Filter Chips (Semua 21 | Stres | Cemas | Depresi)
                        _buildFilterChips(assessment.items.length),
                        const SizedBox(height: 16),

                        // 21 Questions List
                        ListView.separated(
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
                        const SizedBox(height: 80),
                      ],
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
        ? '$changedCount Butir Diperbarui'
        : (isUnverified ? 'Sintesis AI Siap Dikonfirmasi' : 'Asesmen Tersimpan');
    final String subtitleText = hasChanges
        ? (isUnverified ? 'Simpan koreksi & verifikasi untuk hari ini' : 'Simpan koreksi skor DASS-21')
        : (isUnverified ? 'Konfirmasi untuk simpan asesmen hari ini' : 'Skor hari ini telah terverifikasi');
    final String buttonText = hasChanges
        ? (isUnverified ? 'Simpan & Verifikasi' : 'Simpan')
        : 'Konfirmasi & Simpan';
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    barIcon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitleText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
              ScaffoldMessenger.of(context).showSnackBar(
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
          IconButton(
            onPressed: () => notifier.loadTodayAssessment(),
            icon: const Icon(Icons.refresh_rounded, size: 22, color: AppColors.primary),
            tooltip: 'Segarkan data',
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F4EA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF34A853).withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.edit_note_rounded, color: Color(0xFF137333), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Mode Interaktif: Anda dapat meninjau kutipan bukti obrolan Luna hari ini dan mengoreksi skala nilai 0–3 jika diperlukan.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF137333),
                  height: 1.35,
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

  Widget _buildSubscalesCard(DASSAssessmentEntity assessment) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Skor 3 Dimensi DASS-21',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: assessment.verifiedByUser ? const Color(0xFFE6F4EA) : const Color(0xFFFFF0D4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  assessment.verifiedByUser ? 'Terverifikasi User' : 'Deteksi AI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: assessment.verifiedByUser ? const Color(0xFF137333) : const Color(0xFFB06000),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSubscaleTile('Stres', assessment.stressScore, assessment.stressSeverity, const Color(0xFFFF7675)),
              const SizedBox(width: 8),
              _buildSubscaleTile('Kecemasan', assessment.anxietyScore, assessment.anxietySeverity, const Color(0xFF6C63FF)),
              const SizedBox(width: 8),
              _buildSubscaleTile('Depresi', assessment.depressionScore, assessment.depressionSeverity, const Color(0xFF74B9FF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscaleTile(String label, int score, String severity, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$score',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                severity,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
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
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                f['label']!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF4B5563),
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                ),
              ),
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _selectedFilter = f['key']!;
                  });
                }
              },
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

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Number & Subscale Tag
          Row(
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
              const Spacer(),
              if (item.isUserEdited)
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

          // AI Evidence Quote
          if (item.evidence != null && item.evidence!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded, size: 16, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Bukti Obrolan: "${item.evidence}"',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Likert Selector Options (0 - 3)
          Row(
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
        ],
      ),
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
      child: GestureDetector(
        onTap: isEditable ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isEditable ? Colors.white : const Color(0xFFF3F4F6)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isEditable ? const Color(0xFFD1D5DB) : const Color(0xFFE5E7EB)),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isEditable ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
