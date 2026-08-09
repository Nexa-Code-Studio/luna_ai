import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import '../widgets/glass_card.dart';



class MonitoringScreen extends StatelessWidget {

  const MonitoringScreen({super.key});



  @override

  Widget build(BuildContext context) {

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

                    const Spacer(),

                    IconButton(

                      icon: const Icon(Icons.notifications_none_outlined),

                      color: AppColors.primary,

                      onPressed: () {},

                    ),

                  ],

                ),

              ),



              // Scrollable Content

              Expanded(

                child: SingleChildScrollView(

                  padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 100.0),

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      // Title & Subtitle

                      Text(

                        'Wawasan Ritem Emosional',

                        style: GoogleFonts.inter(

                          fontSize: 22,

                          fontWeight: FontWeight.w800,

                          color: AppColors.textPrimary,

                        ),

                      ),

                      const SizedBox(height: 4),

                      Text(

                        'Gambaran lembut tentang dinamika perasaanmu minggu ini.',

                        style: GoogleFonts.inter(

                          fontSize: 14,

                          color: AppColors.textSecondary,

                        ),

                      ),

                      const SizedBox(height: 20),



                      // Card 1: RINGKASAN MINGGUAN

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

                                  Text(

                                    'RINGKASAN MINGGUAN',

                                    style: GoogleFonts.inter(

                                      fontSize: 10,

                                      fontWeight: FontWeight.w700,

                                      color: AppColors.textLight,

                                      letterSpacing: 0.8,

                                    ),

                                  ),

                                  const SizedBox(height: 4),

                                  Text(

                                    'Tren minggu ini: Kamu mulai menemukan keseimbangan setelah awal minggu yang sibuk.',

                                    style: GoogleFonts.inter(

                                      fontSize: 14,

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



                      // Card 2: GRAFIK RITEM SUASANA HATI

                      GlassCard(

                        width: double.infinity,

                        padding: const EdgeInsets.all(20),

                        child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            Row(

                              mainAxisAlignment: MainAxisAlignment.spaceBetween,

                              children: [

                                Text(

                                  'RITEM SUASANA HATI',

                                  style: GoogleFonts.inter(

                                    fontSize: 11,

                                    fontWeight: FontWeight.w700,

                                    color: AppColors.textLight,

                                    letterSpacing: 0.8,

                                  ),

                                ),

                                Row(

                                  children: [

                                    Container(

                                      width: 8,

                                      height: 8,

                                      decoration: const BoxDecoration(

                                        shape: BoxShape.circle,

                                        color: AppColors.primary,

                                      ),

                                    ),

                                    const SizedBox(width: 6),

                                    Text(

                                      'Energi',

                                      style: GoogleFonts.inter(

                                        fontSize: 12,

                                        fontWeight: FontWeight.w600,

                                        color: AppColors.textPrimary,

                                      ),

                                    ),

                                  ],

                                ),

                              ],

                            ),

                            const SizedBox(height: 20),

                            SizedBox(

                              height: 130,

                              width: double.infinity,

                              child: CustomPaint(

                                painter: _MoodChartPainter(),

                              ),

                            ),

                            const SizedBox(height: 12),

                            Row(

                              mainAxisAlignment: MainAxisAlignment.spaceBetween,

                              children: const [

                                _DayLabel('Sen'),

                                _DayLabel('Sel'),

                                _DayLabel('Rab'),

                                _DayLabel('Kam'),

                                _DayLabel('Jum'),

                                _DayLabel('Sab'),

                                _DayLabel('Min'),

                              ],

                            ),

                          ],

                        ),

                      ),

                      const SizedBox(height: 16),



                      // Card 3: TINGKAT STRES

                      GlassCard(

                        width: double.infinity,

                        padding: const EdgeInsets.all(20),

                        child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            Row(

                              children: [

                                const Icon(

                                  Icons.water_drop_outlined,

                                  size: 18,

                                  color: Color(0xFF605A79),

                                ),

                                const SizedBox(width: 8),

                                Text(

                                  'TINGKAT STRES',

                                  style: GoogleFonts.inter(

                                    fontSize: 11,

                                    fontWeight: FontWeight.w700,

                                    color: AppColors.textLight,

                                    letterSpacing: 0.8,

                                  ),

                                ),

                              ],

                            ),

                            const SizedBox(height: 12),

                            Row(

                              crossAxisAlignment: CrossAxisAlignment.baseline,

                              textBaseline: TextBaseline.alphabetic,

                              children: [

                                Text(

                                  '70%',

                                  style: GoogleFonts.inter(

                                    fontSize: 28,

                                    fontWeight: FontWeight.w800,

                                    color: AppColors.textPrimary,

                                  ),

                                ),

                                const SizedBox(width: 8),

                                Text(

                                  'Meningkat',

                                  style: GoogleFonts.inter(

                                    fontSize: 14,

                                    fontWeight: FontWeight.w600,

                                    color: AppColors.textSecondary,

                                  ),

                                ),

                              ],

                            ),

                            const SizedBox(height: 6),

                            Text(

                              'Ingat untuk menarik napas dalam-dalam hari ini.',

                              style: GoogleFonts.inter(

                                fontSize: 13,

                                color: AppColors.textLight,

                              ),

                            ),

                            const SizedBox(height: 14),

                            ClipRRect(

                              borderRadius: BorderRadius.circular(999),

                              child: LinearProgressIndicator(

                                value: 0.7,

                                minHeight: 8,

                                backgroundColor: const Color(0xFFE2E4F0),

                                valueColor: const AlwaysStoppedAnimation<Color>(

                                  Color(0xFF605A79),

                                ),

                              ),

                            ),

                          ],

                        ),

                      ),

                      const SizedBox(height: 16),



                      // Card 4: PUSAT EMOSIONAL

                      GlassCard(

                        width: double.infinity,

                        padding: const EdgeInsets.all(20),

                        child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            Row(

                              children: [

                                const Icon(

                                  Icons.balance,

                                  size: 18,

                                  color: Color(0xFF20667B),

                                ),

                                const SizedBox(width: 8),

                                Text(

                                  'PUSAT EMOSIONAL',

                                  style: GoogleFonts.inter(

                                    fontSize: 11,

                                    fontWeight: FontWeight.w700,

                                    color: AppColors.textLight,

                                    letterSpacing: 0.8,

                                  ),

                                ),

                              ],

                            ),

                            const SizedBox(height: 12),

                            Text(

                              'Baik',

                              style: GoogleFonts.inter(

                                fontSize: 24,

                                fontWeight: FontWeight.w800,

                                color: const Color(0xFF20667B),

                              ),

                            ),

                            const SizedBox(height: 4),

                            Text(

                              'Ketangguhan dirimu bersinar dengan baik.',

                              style: GoogleFonts.inter(

                                fontSize: 13,

                                color: AppColors.textSecondary,

                              ),

                            ),

                            const SizedBox(height: 16),

                            Row(

                              children: [

                                _buildPill(isSelected: false, color: const Color(0xFFD6E2E8)),

                                const SizedBox(width: 8),

                                _buildPill(isSelected: false, color: const Color(0xFFA1C6D4)),

                                const SizedBox(width: 8),

                                _buildPill(isSelected: false, color: const Color(0xFF67A5BC)),

                                const SizedBox(width: 8),

                                _buildPill(isSelected: true, color: const Color(0xFF20667B)),

                                const SizedBox(width: 8),

                                _buildPill(isSelected: false, color: const Color(0xFFD6E2E8)),

                              ],

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



  Widget _buildPill({required bool isSelected, required Color color}) {

    return Expanded(

      child: Container(

        height: 32,

        decoration: BoxDecoration(

          color: color,

          borderRadius: BorderRadius.circular(12),

        ),

        child: isSelected

            ? const Icon(Icons.check, color: Colors.white, size: 18)

            : null,

      ),

    );

  }

}



class _DayLabel extends StatelessWidget {

  final String text;

  const _DayLabel(this.text);



  @override

  Widget build(BuildContext context) {

    return Text(

      text,

      style: GoogleFonts.inter(

        fontSize: 11,

        fontWeight: FontWeight.w500,

        color: AppColors.textLight,

      ),

    );

  }

}



class _MoodChartPainter extends CustomPainter {

  @override

  void paint(Canvas canvas, Size size) {

    final points = [

      Offset(0, size.height * 0.5),

      Offset(size.width * 0.16, size.height * 0.65),

      Offset(size.width * 0.33, size.height * 0.2),

      Offset(size.width * 0.5, size.height * 0.25),

      Offset(size.width * 0.66, size.height * 0.45),

      Offset(size.width * 0.83, size.height * 0.25),

      Offset(size.width, size.height * 0.1),

    ];



    final path = Path()..moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {

      final p0 = points[i];

      final p1 = points[i + 1];

      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);

      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

      path.cubicTo(

        controlPoint1.dx,

        controlPoint1.dy,

        controlPoint2.dx,

        controlPoint2.dy,

        p1.dx,

        p1.dy,

      );

    }



    final fillPath = Path.from(path)

      ..lineTo(size.width, size.height)

      ..lineTo(0, size.height)

      ..close();



    final fillPaint = Paint()

      ..shader = LinearGradient(

        colors: [

          const Color(0xFF8B93FF).withValues(alpha: 0.4),

          const Color(0xFF8B93FF).withValues(alpha: 0.05),

        ],

        begin: Alignment.topCenter,

        end: Alignment.bottomCenter,

      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));



    canvas.drawPath(fillPath, fillPaint);



    final strokePaint = Paint()

      ..color = AppColors.primary

      ..strokeWidth = 3

      ..style = PaintingStyle.stroke

      ..strokeCap = StrokeCap.round;



    canvas.drawPath(path, strokePaint);



    final dotPaint = Paint()..color = Colors.white;

    final dotBorderPaint = Paint()

      ..color = AppColors.primary

      ..strokeWidth = 2

      ..style = PaintingStyle.stroke;



    for (final p in points) {

      canvas.drawCircle(p, 5, dotPaint);

      canvas.drawCircle(p, 5, dotBorderPaint);

    }

  }



  @override

  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

}

