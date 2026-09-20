import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Color profile token for the fluid shimmering nodes inside the Luna Orb.
class _NodeColorProfile {
  final Color core;
  final Color highlight;
  final Color ambient;
  const _NodeColorProfile(this.core, this.highlight, this.ambient);
}

/// A mesmerizing, fluid iridescent loading orb inspired by Luna AI's voice visualizer.
/// Displays an undulating iridescent sphere with organic swirling fluid lobes,
/// pulsing halo, and an optional calm breathing status message.
class LunaLoadingOrb extends StatefulWidget {
  final double size;
  final String? message;
  final bool showHalo;

  const LunaLoadingOrb({
    super.key,
    this.size = 180.0,
    this.message,
    this.showHalo = true,
  });

  @override
  State<LunaLoadingOrb> createState() => _LunaLoadingOrbState();
}

class _LunaLoadingOrbState extends State<LunaLoadingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double orbSize = widget.size;
    final double innerSize = orbSize * 0.78;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final animProgress = _controller.value;
          final double pulse = math.sin(animProgress * 2 * math.pi) * 0.5 + 0.5;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: orbSize,
                height: orbSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Soft Ambient Iridescent Halo
                    if (widget.showHalo)
                      Container(
                        width: innerSize * 1.15,
                        height: innerSize * 1.15,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC7D2FE).withValues(
                                alpha: 0.25 + (pulse * 0.15),
                              ),
                              blurRadius: 36 + (pulse * 14),
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: const Color(0xFFFFD1DC).withValues(
                                alpha: 0.20 + (pulse * 0.10),
                              ),
                              blurRadius: 28,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),

                    // 2. Main Spherical Body with Soft Pastel Gradient
                    Container(
                      width: innerSize,
                      height: innerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          center: Alignment(-0.25, -0.35),
                          radius: 0.95,
                          colors: [
                            Color(0xFFFFFFFF), // Soft white highlight
                            Color(0xFFEDE9FE), // Pale lavender
                            Color(0xFFE0E7FF), // Soft periwinkle
                            Color(0xFFBAE6FD), // Soft cyan edge
                          ],
                          stops: [0.0, 0.45, 0.75, 1.0],
                        ),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                          width: 1.5,
                        ),
                        boxShadow: [
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
                      child: ClipOval(
                        child: CustomPaint(
                          size: Size(innerSize, innerSize),
                          painter: _LunaOrbFluidPainter(
                            animProgress: animProgress,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Optional Status Message
              if (widget.message != null && widget.message!.isNotEmpty) ...[
                const SizedBox(height: 18),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: 0.75 + (pulse * 0.25),
                  child: Text(
                    widget.message!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// CustomPainter that renders organic swirling fluid lobes and silky ribbons.
class _LunaOrbFluidPainter extends CustomPainter {
  final double animProgress;

  const _LunaOrbFluidPainter({required this.animProgress});

  static const List<_NodeColorProfile> _profiles = [
    _NodeColorProfile(Color(0xFF0284C7), Color(0xFF38BDF8), Color(0xFFA7E6FF)),
    _NodeColorProfile(Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFFC7D2FE)),
    _NodeColorProfile(Color(0xFF7E22CE), Color(0xFFA855F7), Color(0xFFE9D5FF)),
    _NodeColorProfile(Color(0xFFDB2777), Color(0xFFF472B6), Color(0xFFFCE7F3)),
    _NodeColorProfile(Color(0xFFE11D48), Color(0xFFFB7185), Color(0xFFFFE4E6)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double scale = size.width / 174.0;
    const int nodeCount = 5;

    // 1. Fluid Abstract Background Atmosphere
    final backdropPaint = Paint()
      ..color = const Color(0xFFEDE9FE).withValues(alpha: 0.40)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 16.0 * scale);
    canvas.drawCircle(center, 44.0 * scale, backdropPaint);

    // 2. Swirling Organic Fluid Lobes
    for (int i = 0; i < nodeCount; i++) {
      final profile = _profiles[i];
      final double theta = (i * 2 * math.pi / nodeCount) + (animProgress * 2 * math.pi * 1.0);

      final double lissajousX = (math.cos(theta) * (18.0 + math.sin(animProgress * 2 * math.pi * 1.0 + i) * 4.0)) * scale;
      final double lissajousY = (math.sin(theta) * (16.0 + math.cos(animProgress * 2 * math.pi * 1.0 - i) * 4.0)) * scale;
      final Offset lobeCenter = center + Offset(lissajousX, lissajousY);

      final double baseRadius = 32.0 * scale;
      final double breathing = math.sin((animProgress * 2 * math.pi * 2.0) + (i * 1.3)) * 4.5 * scale;
      final double lobeRadius = baseRadius + breathing;

      final Path lobePath = Path();
      const int vertices = 16;
      for (int v = 0; v <= vertices; v++) {
        final double angle = (v / vertices) * 2 * math.pi;
        final double wave1 = math.sin((angle * 2.0) + (animProgress * 2 * math.pi * 2.0) + i) * 0.16;
        final double wave2 = math.cos((angle * 3.0) - (animProgress * 2 * math.pi * 1.0) + (i * 0.8)) * 0.10;
        final double r = lobeRadius * (1.0 + wave1 + wave2);
        final double vx = lobeCenter.dx + r * math.cos(angle);
        final double vy = lobeCenter.dy + r * math.sin(angle);
        if (v == 0) {
          lobePath.moveTo(vx, vy);
        } else {
          lobePath.lineTo(vx, vy);
        }
      }
      lobePath.close();

      final lobePaint = Paint()
        ..shader = RadialGradient(
          center: Alignment(
            -0.20 * math.cos(theta),
            -0.20 * math.sin(theta),
          ),
          radius: 0.90,
          colors: [
            profile.highlight.withValues(alpha: 0.82),
            profile.core.withValues(alpha: 0.62),
            profile.ambient.withValues(alpha: 0.22),
            profile.core.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.42, 0.75, 1.0],
        ).createShader(Rect.fromCircle(center: lobeCenter, radius: lobeRadius * 1.2))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0 * scale);

      canvas.drawPath(lobePath, lobePaint);
    }

    // 3. Curving Fluid Silk Ribbon
    final double ribbonAngle = animProgress * 2 * math.pi * 1.0;
    final Path ribbon = Path();
    ribbon.moveTo(
      center.dx + 38 * scale * math.cos(ribbonAngle),
      center.dy + 38 * scale * math.sin(ribbonAngle),
    );
    ribbon.quadraticBezierTo(
      center.dx + 14 * scale * math.cos(ribbonAngle + 1.8),
      center.dy + 14 * scale * math.sin(ribbonAngle + 1.8),
      center.dx + 38 * scale * math.cos(ribbonAngle + math.pi),
      center.dy + 38 * scale * math.sin(ribbonAngle + math.pi),
    );

    final ribbonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.5 * scale
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: ribbonAngle,
        endAngle: ribbonAngle + (2 * math.pi),
        colors: [
          _profiles[0].highlight.withValues(alpha: 0.45),
          _profiles[2].highlight.withValues(alpha: 0.45),
          _profiles[3].highlight.withValues(alpha: 0.40),
          _profiles[0].highlight.withValues(alpha: 0.45),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 42.0 * scale))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5.0 * scale);

    canvas.drawPath(ribbon, ribbonPaint);

    // 4. Specular Glass Glare Overlay
    final glarePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 0.70,
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 52.0 * scale));
    canvas.drawCircle(center, 50.0 * scale, glarePaint);
  }

  @override
  bool shouldRepaint(covariant _LunaOrbFluidPainter oldDelegate) {
    return oldDelegate.animProgress != animProgress;
  }
}
