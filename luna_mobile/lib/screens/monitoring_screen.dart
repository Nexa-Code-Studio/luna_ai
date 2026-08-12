import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import '../widgets/glass_card.dart';



class MonitoringScreen extends StatefulWidget {

  const MonitoringScreen({super.key});



  @override

  State<MonitoringScreen> createState() => _MonitoringScreenState();

}



class _MonitoringScreenState extends State<MonitoringScreen> {

  String _selectedPeriod = 'week'; // 'today', 'week', 'month'



  final Map<String, Map<String, dynamic>> _periodData = {

    'today': {

      'periodLabel': 'Hari Ini',

      'summary':

          'Evaluasi 3 sesi suara hari ini menunjukkan kecemasan di pagi hari yang mereda di sore hari setelah jeda istirahat.',

      'emotionalCenter': {

        'status': 'Cukup (Kecenderungan Membaik)',

        'level': 3, // 1 to 5 (1=Buruk, 5=Sangat Baik)

        'gradientColors': [Color(0xFFFFF8E1), Color(0xFFFFE082)],

        'textColor': Color(0xFFF57F17),

        'description': 'Keseimbangan emosi mulai pulih di penghujung hari.',

      },

      'risks': [

        {

          'name': 'Stres Akademik',

          'type': 'stress',

          'percent': 0.70,

          'levelLabel': 'Tinggi (70%)',

          'color': Color(0xFFD32F2F),

          'badgeBg': Color(0xFFFFDCDD),

        },

        {

          'name': 'Anxiety (Kecemasan)',

          'type': 'anxiety',

          'percent': 0.65,

          'levelLabel': 'Sedang-Tinggi (65%)',

          'color': Color(0xFFE57373),

          'badgeBg': Color(0xFFFFEBEE),

        },

      ],

      'xLabels': ['06:00', '09:00', '12:00', '15:00', '18:00', '21:00'],

      // 6 bars x 7 emotion segment ratios [happy, netral, fear, sadness, surprise, anger, disgusted]

      'chartData': [

        [0.1, 0.2, 0.5, 0.1, 0.05, 0.03, 0.02],

        [0.05, 0.15, 0.60, 0.15, 0.03, 0.01, 0.01],

        [0.2, 0.4, 0.3, 0.05, 0.03, 0.01, 0.01],

        [0.4, 0.4, 0.1, 0.05, 0.03, 0.01, 0.01],

        [0.3, 0.5, 0.1, 0.05, 0.03, 0.01, 0.01],

        [0.2, 0.4, 0.2, 0.15, 0.03, 0.01, 0.01],

      ],

    },

    'week': {

      'periodLabel': 'Minggu Ini',

      'summary':

          'Tren minggu ini: Keseimbangan emosi meningkat 15%. Puncak ketenangan dicapai pada hari Rabu dan Kamis.',

      'emotionalCenter': {

        'status': 'Baik & Stabil',

        'level': 4,

        'gradientColors': [Color(0xFFE8F5E9), Color(0xFFA5D6A7)],

        'textColor': Color(0xFF2E7D32),

        'description': 'Resiliensi emosional dalam kondisi sangat prima.',

      },

      'risks': [

        {

          'name': 'Stres',

          'type': 'stress',

          'percent': 0.55,

          'levelLabel': 'Sedang (55%)',

          'color': Color(0xFFFB8C00),

          'badgeBg': Color(0xFFFFF3E0),

        },

        {

          'name': 'Anxiety',

          'type': 'anxiety',

          'percent': 0.40,

          'levelLabel': 'Rendah-Sedang (40%)',

          'color': Color(0xFF489BB8),

          'badgeBg': Color(0xFFE0F4FB),

        },

        {

          'name': 'Depresi',

          'type': 'depresi',

          'percent': 0.20,

          'levelLabel': 'Rendah (20%)',

          'color': Color(0xFF8B93FF),

          'badgeBg': Color(0xFFEADBFF),

        },

      ],

      'xLabels': ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'],

      'chartData': [

        [0.1, 0.2, 0.4, 0.2, 0.05, 0.03, 0.02],

        [0.2, 0.3, 0.3, 0.1, 0.05, 0.03, 0.02],

        [0.5, 0.3, 0.1, 0.05, 0.03, 0.01, 0.01],

        [0.6, 0.25, 0.08, 0.04, 0.01, 0.01, 0.01],

        [0.4, 0.3, 0.15, 0.1, 0.03, 0.01, 0.01],

        [0.5, 0.35, 0.05, 0.05, 0.03, 0.01, 0.01],

        [0.3, 0.4, 0.15, 0.1, 0.03, 0.01, 0.01],

      ],

    },

    'month': {

      'periodLabel': 'Bulan Ini',

      'summary':

          'Analisis Bulan Oktober: Kestabilan emosional berada pada kategori Optimal dengan dominasi emosi Netral & Bahagia (62%).',

      'emotionalCenter': {

        'status': 'Sangat Baik (Optimal)',

        'level': 5,

        'gradientColors': [Color(0xFFC8E6C9), Color(0xFF81C784)],

        'textColor': Color(0xFF1B5E20),

        'description': 'Kesehatan mental dan emosi berada pada taraf terbaik bulan ini.',

      },

      'risks': [

        {

          'name': 'Stres',

          'type': 'stress',

          'percent': 0.35,

          'levelLabel': 'Rendah (35%)',

          'color': Color(0xFF4CAF50),

          'badgeBg': Color(0xFFE8F5E9),

        },

        {

          'name': 'Depresi',

          'type': 'depresi',

          'percent': 0.15,

          'levelLabel': 'Sangat Rendah (15%)',

          'color': Color(0xFF8B93FF),

          'badgeBg': Color(0xFFEADBFF),

        },

      ],

      'xLabels': ['M1 (Minggu 1)', 'M2 (Minggu 2)', 'M3 (Minggu 3)', 'M4 (Minggu 4)'],

      'chartData': [

        [0.25, 0.35, 0.25, 0.10, 0.03, 0.01, 0.01],

        [0.40, 0.35, 0.15, 0.05, 0.03, 0.01, 0.01],

        [0.55, 0.30, 0.10, 0.03, 0.01, 0.005, 0.005],

        [0.60, 0.25, 0.08, 0.05, 0.01, 0.005, 0.005],

      ],

    },

  };



  // 7 Emotion parameters color mapping

  final List<Map<String, dynamic>> _emotionLegend = const [

    {'key': 'happy', 'name': 'Bahagia', 'emoji': '😃', 'color': Color(0xFFFFB800)},

    {'key': 'netral', 'name': 'Netral', 'emoji': '😐', 'color': Color(0xFF489BB8)},

    {'key': 'fear', 'name': 'Takut', 'emoji': '😨', 'color': Color(0xFF6C63FF)},

    {'key': 'sadness', 'name': 'Sedih', 'emoji': '😔', 'color': Color(0xFF4A90E2)},

    {'key': 'surprise', 'name': 'Terkejut', 'emoji': '😲', 'color': Color(0xFF9C27B0)},

    {'key': 'anger', 'name': 'Marah', 'emoji': '😡', 'color': Color(0xFFE53935)},

    {'key': 'disgusted', 'name': 'Jijik', 'emoji': '🤢', 'color': Color(0xFF4CAF50)},

  ];



  @override

  Widget build(BuildContext context) {

    final currentData = _periodData[_selectedPeriod]!;

    final emotionalCenter = currentData['emotionalCenter'] as Map<String, dynamic>;

    final risks = List<Map<String, dynamic>>.from(currentData['risks']);

    final xLabels = List<String>.from(currentData['xLabels']);

    final chartData = List<List<double>>.from(

      (currentData['chartData'] as List).map((e) => List<double>.from(e)),

    );



    final Color textColor = emotionalCenter['textColor'] as Color;

    final List<Color> gradientColors = List<Color>.from(emotionalCenter['gradientColors']);

    final int level = emotionalCenter['level'] as int;



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

              // Header Bar with Settings Gear Icon

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

                    const Spacer(),

                    IconButton(

                      icon: const Icon(Icons.settings_outlined),

                      color: AppColors.primary,

                      onPressed: () {},

                    ),

                  ],

                ),

              ),



              // Scrollable Main Content

              Expanded(

                child: SingleChildScrollView(

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



                      // PERIOD FILTER CHIPS (Hari Ini, Minggu Ini, Bulan Ini)

                      Row(

                        children: [

                          _buildPeriodChip('today', 'Hari Ini'),

                          const SizedBox(width: 8),

                          _buildPeriodChip('week', 'Minggu Ini'),

                          const SizedBox(width: 8),

                          _buildPeriodChip('month', 'Bulan Ini'),

                        ],

                      ),

                      const SizedBox(height: 20),



                      // 1. RINGKASAN AI (Filtered by Period)

                      GlassCard(

                        width: double.infinity,

                        padding: const EdgeInsets.all(18),

                        child: Row(

                          children: [

                            Container(

                              width: 44,

                              height: 44,

                              decoration: BoxDecoration(

                                color: const Color(0xFFE0F4FB),

                                borderRadius: BorderRadius.circular(14),

                              ),

                              child: const Icon(

                                Icons.lightbulb_outline,

                                color: Color(0xFF20667B),

                                size: 22,

                              ),

                            ),

                            const SizedBox(width: 14),

                            Expanded(

                              child: Column(

                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [

                                  Row(

                                    children: [

                                      Text(

                                        'RINGKASAN AI',

                                        style: GoogleFonts.inter(

                                          fontSize: 10,

                                          fontWeight: FontWeight.w700,

                                          color: AppColors.textLight,

                                          letterSpacing: 0.8,

                                        ),

                                      ),

                                      const SizedBox(width: 6),

                                      Container(

                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),

                                        decoration: BoxDecoration(

                                          color: AppColors.primaryContainer,

                                          borderRadius: BorderRadius.circular(999),

                                        ),

                                        child: Text(

                                          currentData['periodLabel'],

                                          style: GoogleFonts.inter(

                                            fontSize: 9,

                                            fontWeight: FontWeight.w700,

                                            color: AppColors.primary,

                                          ),

                                        ),

                                      ),

                                    ],

                                  ),

                                  const SizedBox(height: 4),

                                  Text(

                                    currentData['summary'],

                                    style: GoogleFonts.inter(

                                      fontSize: 13,

                                      fontWeight: FontWeight.w600,

                                      color: AppColors.textPrimary,

                                      height: 1.4,

                                    ),

                                  ),

                                ],

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

                                    Text(

                                      'Proporsi emosi per interval ${currentData['periodLabel']}',

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

                              child: CustomPaint(

                                painter: _StackedEmotionChartPainter(

                                  chartData: chartData,

                                  emotionColors: _emotionLegend.map((e) => e['color'] as Color).toList(),

                                ),

                              ),

                            ),

                            const SizedBox(height: 12),



                            // X-Axis Labels Row

                            Row(

                              mainAxisAlignment: MainAxisAlignment.spaceAround,

                              children: xLabels.map((lbl) {

                                return Flexible(

                                  child: Text(

                                    lbl,

                                    maxLines: 1,

                                    overflow: TextOverflow.ellipsis,

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

                                return Container(

                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                                  decoration: BoxDecoration(

                                    color: (item['color'] as Color).withValues(alpha: 0.12),

                                    borderRadius: BorderRadius.circular(999),

                                    border: Border.all(

                                      color: (item['color'] as Color).withValues(alpha: 0.4),

                                    ),

                                  ),

                                  child: Row(

                                    mainAxisSize: MainAxisSize.min,

                                    children: [

                                      Text(item['emoji'], style: const TextStyle(fontSize: 11)),

                                      const SizedBox(width: 4),

                                      Text(

                                        item['name'],

                                        style: GoogleFonts.inter(

                                          fontSize: 10,

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



                      // 3. TINGKAT RISIKO PENYAKIT MENTAL (Stress, Anxiety, Depresi)

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

                            const SizedBox(height: 14),

                            ...risks.map((r) {

                              final double pct = (r['percent'] as num).toDouble();

                              final Color barColor = r['color'] as Color;

                              final Color badgeBg = r['badgeBg'] as Color;



                              return Padding(

                                padding: const EdgeInsets.only(bottom: 14.0),

                                child: Column(

                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [

                                    Row(

                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                                      children: [

                                        Text(

                                          r['name'],

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

                                            r['levelLabel'],

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

                              'LUNA merekomendasikan jeda istirahat teratur dan latihan pernapasan untuk menurunkan tingkat risiko.',

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



                      // 4. PUSAT EMOSIONAL (Gradient Meter Hijau ke Merah)

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

                                  'PUSAT EMOSIONAL HARIAN',

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

                              emotionalCenter['status'],

                              style: GoogleFonts.inter(

                                fontSize: 20,

                                fontWeight: FontWeight.w800,

                                color: textColor,

                              ),

                            ),

                            const SizedBox(height: 4),

                            Text(

                              emotionalCenter['description'],

                              style: GoogleFonts.inter(

                                fontSize: 12,

                                color: textColor.withValues(alpha: 0.9),

                              ),

                            ),

                            const SizedBox(height: 16),



                            // 5-Segment Level Pills (Green to Red Gradient Spectrum)

                            Row(

                              children: List.generate(5, (index) {

                                final segLevel = index + 1;

                                final bool isSel = segLevel == level;

                                // Spectrum colors from Red (1/5 - Worst/Left) to Green (5/5 - Best/Right)

                                final colors = const [

                                  Color(0xFFD32F2F), // Red (Paling Kiri / Sangat Buruk)

                                  Color(0xFFE57373), // Light Red (Buruk)

                                  Color(0xFFFFB74D), // Amber/Orange (Cukup)

                                  Color(0xFF81C784), // Light Green (Baik)

                                  Color(0xFF4CAF50), // Green (Paling Kanan / Sangat Baik)

                                ];



                                return Expanded(

                                  child: Container(

                                    margin: const EdgeInsets.symmetric(horizontal: 3),

                                    height: 28,

                                    decoration: BoxDecoration(

                                      color: colors[index].withValues(alpha: isSel ? 1.0 : 0.4),

                                      borderRadius: BorderRadius.circular(10),

                                      border: isSel

                                          ? Border.all(color: Colors.white, width: 2)

                                          : null,

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

                      const SizedBox(height: 24),

                    ],

                  ),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildPeriodChip(String id, String label) {

    final isSelected = id == _selectedPeriod;

    return Expanded(

      child: GestureDetector(

        onTap: () {

          setState(() {

            _selectedPeriod = id;

          });

        },

        child: Container(

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

          child: Center(

            child: Text(

              label,

              style: GoogleFonts.inter(

                fontSize: 12,

                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,

                color: isSelected ? Colors.white : AppColors.textSecondary,

              ),

            ),

          ),

        ),

      ),

    );

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

    final double barWidth = (availableWidth / barCount) * 0.45;

    final double spacing = (availableWidth - (barWidth * barCount)) / (barCount + 1);



    for (int i = 0; i < barCount; i++) {

      final segments = chartData[i];

      final double barLeft = spacing + i * (barWidth + spacing);

      double currentBottom = size.height;



      for (int j = 0; j < segments.length; j++) {

        final double ratio = segments[j];

        if (ratio <= 0) continue;



        final double segHeight = size.height * ratio;

        final double top = currentBottom - segHeight;



        final rect = Rect.fromLTRB(barLeft, top, barLeft + barWidth, currentBottom);

        final paint = Paint()

          ..color = emotionColors[j % emotionColors.length]

          ..style = PaintingStyle.fill;



        // Draw rounded top segment if it's the top element

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

  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

}

