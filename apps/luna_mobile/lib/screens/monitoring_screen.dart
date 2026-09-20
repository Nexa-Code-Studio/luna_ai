import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/dass/presentation/providers/dass_provider.dart';
import '../features/monitoring/domain/entities/monitoring_data_entity.dart';
import '../features/monitoring/presentation/providers/monitoring_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/skeleton_shimmer.dart';

class MonitoringScreen extends ConsumerStatefulWidget {
  const MonitoringScreen({super.key});

  @override
  ConsumerState<MonitoringScreen> createState() => MonitoringScreenState();
}

class MonitoringScreenState extends ConsumerState<MonitoringScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh();
    }
  }

  void refresh() {
    ref.invalidate(monitoringDataProvider);
  }

  // 7 Emotion parameters color mapping matching backend & design system
  final List<Map<String, dynamic>> _emotionLegend = const [
    {'key': 'happy', 'name': 'Bahagia & Senang', 'emoji': '😃', 'color': Color(0xFFFFB800)},
    {'key': 'netral', 'name': 'Netral & Tenang', 'emoji': '😌', 'color': Color(0xFF4ECDC4)},
    {'key': 'fear', 'name': 'Cemas & Takut', 'emoji': '😰', 'color': Color(0xFF6C63FF)},
    {'key': 'sadness', 'name': 'Sedih', 'emoji': '😢', 'color': Color(0xFF74B9FF)},
    {'key': 'surprise', 'name': 'Terkejut', 'emoji': '😲', 'color': Color(0xFFA29BFE)},
    {'key': 'anger', 'name': 'Marah', 'emoji': '😡', 'color': Color(0xFFFF7675)},
    {'key': 'disgusted', 'name': 'Jijik / Muak', 'emoji': '🤢', 'color': Color(0xFF55EFC4)},
  ];

  Color _parseHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final clean = hex.replaceFirst('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
      return Color(int.parse(clean, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  List<Color> _getGradientColors(int level) {
    switch (level) {
      case 5:
        return const [Color(0xFFC8E6C9), Color(0xFF81C784)];
      case 4:
        return const [Color(0xFFE8F5E9), Color(0xFFA5D6A7)];
      case 3:
        return const [Color(0xFFFFF8E1), Color(0xFFFFE082)];
      case 2:
        return const [Color(0xFFFFE0B2), Color(0xFFFFB74D)];
      case 1:
        return const [Color(0xFFFFEBEE), Color(0xFFFFCDD2)];
      case 0:
      default:
        return const [Color(0xFFF1F5F9), Color(0xFFE2E8F0)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final asyncData = ref.watch(monitoringDataProvider);

    return Scaffold(
      body: Container(
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
              // Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/luna_logo.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.nightlight_round,
                          size: 28,
                          color: AppColors.primary,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'LUNA',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Content with Pull-to-Refresh
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(monitoringDataProvider);
                    try {
                      await ref.read(monitoringDataProvider.future);
                    } catch (_) {}
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 100.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Subtitle
                        Text(
                          'Ritem & Tren Emosional',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Grafik dinamika 7 emosi dan tingkat risiko kesehatan mentalmu.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // PERIOD FILTER CHIPS
                        Row(
                          children: [
                            _buildPeriodChip('today', 'Hari Ini', selectedPeriod),
                            const SizedBox(width: 8),
                            _buildPeriodChip('week', 'Minggu Ini', selectedPeriod),
                            const SizedBox(width: 8),
                            _buildPeriodChip('month', 'Bulan Ini', selectedPeriod),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ASYNC CONTENT
                        asyncData.when(
                          data: (data) => _buildMonitoringContent(context, data),
                          loading: () => _buildLoadingState(),
                          error: (error, _) => _buildErrorState(error),
                        ),
                      ],
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

  Widget _buildPeriodChip(String id, String label, String activePeriod) {
    final isSelected = id == activePeriod;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(selectedPeriodProvider.notifier).state = id;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(999),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonitoringContent(BuildContext context, MonitoringDataEntity data) {
    final emotionalCenter = data.emotionalCenter;
    final int level = emotionalCenter.level;
    final Color textColor = _parseHex(emotionalCenter.textColorHex, const Color(0xFF2E7D32));
    final List<Color> gradientColors = _getGradientColors(level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. RINGKASAN AI
        GlassCard(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon + Title + Period Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'RINGKASAN AI',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      data.periodLabel,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Body content text cleanly below icon and title
              Text(
                data.summary,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. STACKED BAR CHART RITEM SUASANA HATI (7 Emosi)
        GlassCard(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STACKED BAR RITEM 7 EMOSI',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textLight,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Proporsi emosi per interval ${data.periodLabel}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEADBFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '7 PARAMETER',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Custom Painted Vertical Stacked Bar Chart
              SizedBox(
                height: 160,
                width: double.infinity,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _StackedEmotionChartPainter(
                      chartData: data.chartData,
                      emotionColors: _emotionLegend.map((e) => e['color'] as Color).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // X-Axis Labels Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: data.xLabels.map((lbl) {
                  return Flexible(
                    child: Text(
                      lbl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              const Divider(height: 1, color: Color(0xFFEBECEF)),
              const SizedBox(height: 14),

              // Legend Key for 7 Emotions
              Text(
                'KUNCI WARNA EMOSI',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _emotionLegend.map((item) {
                  final Color solidColor = item['color'] as Color;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: solidColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(item['emoji'], style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          item['name'],
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. TINGKAT RISIKO KESEHATAN MENTAL
        GlassCard(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.health_and_safety_outlined,
                    size: 20,
                    color: Color(0xFFD32F2F),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'TINGKAT RISIKO KESEHATAN MENTAL',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textLight,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ...data.risks.map((r) {
                final double pct = r.percent;
                final Color barColor = _parseHex(r.colorHex, const Color(0xFFFB8C00));
                final Color badgeBg = _parseHex(r.badgeBgHex, const Color(0xFFFFF3E0));

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            r.name,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              r.levelLabel,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: barColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE2E4F0),
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 4),
              Text(
                'LUNA merekomendasikan jeda istirahat teratur dan latihan pernapasan untuk menstabilkan kondisi psikologis.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. PUSAT EMOSIONAL HARIAN
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: textColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PUSAT EMOSIONAL',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textColor.withValues(alpha: 0.8),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                emotionalCenter.status,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                emotionalCenter.description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: textColor.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 16),

              // 5-Segment Level Pills (Red to Green Spectrum)
              Row(
                children: List.generate(5, (index) {
                  final segLevel = index + 1;
                  final bool isSel = segLevel == level;
                  final colors = const [
                    Color(0xFFD32F2F), // 1: Sangat Buruk (Red)
                    Color(0xFFE57373), // 2: Buruk
                    Color(0xFFFFB74D), // 3: Cukup (Amber)
                    Color(0xFF81C784), // 4: Baik (Light Green)
                    Color(0xFF4CAF50), // 5: Sangat Baik (Green)
                  ];

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 28,
                      decoration: BoxDecoration(
                        color: colors[index].withValues(alpha: isSel ? 1.0 : 0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: isSel ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                      child: isSel
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        // 5. KARTU RINGKASAN & AKSES LEMBAR DASS-21 (Hanya muncul jika ada asesmen DASS riil)
        _buildDASSLauncherCard(context, ref.watch(selectedPeriodProvider)),
      ],
    );
  }

  Widget _buildDASSLauncherCard(BuildContext context, String selectedPeriod) {
    final dassState = ref.watch(dassAssessmentNotifierProvider);

    return dassState.assessment.when(
      data: (assessment) {
        // Jangan tampilkan kartu jika belum pernah ada asesmen DASS yang dipicu atau diekstraksi
        final bool hasValidAssessment = assessment.id != null &&
            assessment.status != 'unassessed' &&
            assessment.status.isNotEmpty &&
            (assessment.verifiedByUser || assessment.status == 'auto_extracted');

        if (!hasValidAssessment) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: GlassCard(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F4FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.psychology_outlined,
                        color: Color(0xFF20667B),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'LEMBAR EVALUASI DASS-21',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textLight,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () => _showDassInfoDialog(context),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE8F0FE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            assessment.verifiedByUser
                                ? 'Skor DASS-21 telah diverifikasi'
                                : 'Tersintesis otomatis • Ketuk untuk meninjau',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Mini Subscale Summary Pills
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      _buildSubscaleMiniChip(
                        context,
                        'Stres',
                        assessment.stressScore,
                        assessment.stressSeverity,
                        'stress',
                      ),
                      const SizedBox(width: 8),
                      _buildSubscaleMiniChip(
                        context,
                        'Kecemasan',
                        assessment.anxietyScore,
                        assessment.anxietySeverity,
                        'anxiety',
                      ),
                      const SizedBox(width: 8),
                      _buildSubscaleMiniChip(
                        context,
                        'Depresi',
                        assessment.depressionScore,
                        assessment.depressionSeverity,
                        'depression',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Open Full Assessment Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/dass_assessment',
                        arguments: {'period': selectedPeriod},
                      );
                    },
                    icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
                    label: Text(
                      selectedPeriod == 'today'
                          ? 'Buka & Tinjau Asesmen Hari Ini'
                          : 'Buka Lembar Evaluasi Riwayat',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  String _getIndonesianSeverity(String scaleType, int score, String rawSeverity) {
    final s = rawSeverity.toLowerCase();
    if (s.contains('extremely') || s.contains('sangat berat')) return 'Sangat Berat';
    if (s.contains('severe') || s.contains('berat')) return 'Berat';
    if (s.contains('moderate') || s.contains('sedang')) return 'Sedang';
    if (s.contains('mild') || s.contains('ringan')) return 'Ringan';
    if (s.contains('normal')) return 'Normal';

    if (scaleType == 'depression') {
      if (score >= 28) return 'Sangat Berat';
      if (score >= 21) return 'Berat';
      if (score >= 14) return 'Sedang';
      if (score >= 10) return 'Ringan';
      return 'Normal';
    } else if (scaleType == 'anxiety') {
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

  Widget _buildSubscaleMiniChip(
    BuildContext context,
    String label,
    int score,
    String rawSeverity,
    String scaleType,
  ) {
    final severityIndo = _getIndonesianSeverity(scaleType, score, rawSeverity);
    final scoreColor = _getScoreColor(severityIndo);
    final bool isExtremelySevere = severityIndo == 'Sangat Berat';

    final Color bgColor = isExtremelySevere
        ? const Color(0xFFD32F2F)
        : scoreColor.withValues(alpha: 0.08);

    final Color labelColor = isExtremelySevere ? Colors.white70 : scoreColor;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isExtremelySevere) {
            _showPsychologistReferralModal(context, label, score, scaleType);
          } else {
            _showSubscaleInfoModal(context, label, score, severityIndo, scaleType);
          }
        },
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

  Widget _buildLoadingState() {
    return SkeletonShimmerHost(
      child: Column(
        children: [
          // 1. Clinical Status Header Skeleton
          GlassCard(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SkeletonCircle(size: 38),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonLine(width: 130, height: 15),
                        SizedBox(height: 6),
                        SkeletonLine(width: 80, height: 12),
                      ],
                    ),
                    const Spacer(),
                    const SkeletonBox(width: 60, height: 24, borderRadius: 12),
                  ],
                ),
                const SizedBox(height: 16),
                const SkeletonLine(width: double.infinity, height: 13),
                const SizedBox(height: 6),
                const SkeletonLine(width: 200, height: 13),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. Trend Chart Skeleton
          GlassCard(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    SkeletonLine(width: 140, height: 16),
                    SkeletonBox(width: 70, height: 26, borderRadius: 8),
                  ],
                ),
                const SizedBox(height: 20),
                const SkeletonBox(width: double.infinity, height: 160, borderRadius: 12),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 3. Dual Metrics Skeleton
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: const [
                      SkeletonLine(width: 60, height: 12),
                      SizedBox(height: 8),
                      SkeletonLine(width: 40, height: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: const [
                      SkeletonLine(width: 60, height: 12),
                      SizedBox(height: 8),
                      SkeletonLine(width: 40, height: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text(
            'Gagal Memuat Data Tren',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pastikan koneksi internet atau server backend aktif.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(monitoringDataProvider);
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
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

/// Custom Painter for 7-Emotion Vertical Stacked Bar Chart
class _StackedEmotionChartPainter extends CustomPainter {
  final List<List<double>> chartData;
  final List<Color> emotionColors;

  _StackedEmotionChartPainter({
    required this.chartData,
    required this.emotionColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (chartData.isEmpty) return;

    final int barCount = chartData.length;
    final double availableWidth = size.width;
    const double maxBarWidth = 28.0;
    final double barWidth = min(maxBarWidth, (availableWidth / barCount) * 0.45);

    for (int i = 0; i < barCount; i++) {
      final segments = chartData[i];
      final double centerX = (i + 0.5) * (availableWidth / barCount);
      final double barLeft = centerX - (barWidth / 2);
      double currentBottom = size.height;

      final double totalRatio = segments.fold(0.0, (sum, val) => sum + val);
      if (totalRatio <= 0) {
        // Draw subtle baseline indicator for empty bar slot
        final baseRect = Rect.fromLTRB(barLeft, size.height - 3, barLeft + barWidth, size.height);
        final basePaint = Paint()
          ..color = const Color(0xFFD8DCE8)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(baseRect, const Radius.circular(2)), basePaint);
        continue;
      }

      for (int j = 0; j < segments.length; j++) {
        final double ratio = segments[j];
        if (ratio <= 0) continue;

        final double segHeight = (size.height - 4) * (ratio / totalRatio);
        final double top = currentBottom - segHeight;

        final rect = Rect.fromLTRB(barLeft, top, barLeft + barWidth, currentBottom);
        final paint = Paint()
          ..color = emotionColors[j % emotionColors.length]
          ..style = PaintingStyle.fill;

        final RRect rrect = RRect.fromRectAndCorners(
          rect,
          topLeft: Radius.circular(j == 0 ? 6 : 0),
          topRight: Radius.circular(j == 0 ? 6 : 0),
          bottomLeft: Radius.circular(j == segments.length - 1 ? 6 : 0),
          bottomRight: Radius.circular(j == segments.length - 1 ? 6 : 0),
        );

        canvas.drawRRect(rrect, paint);
        currentBottom = top;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StackedEmotionChartPainter oldDelegate) {
    return oldDelegate.chartData != chartData;
  }
}
