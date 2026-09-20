import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// An InheritedWidget that provides the synchronized breathing shimmer opacity
/// to all child skeleton items within its subtree.
class _SkeletonInheritedOpacity extends InheritedWidget {
  final double opacity;

  const _SkeletonInheritedOpacity({
    required this.opacity,
    required super.child,
  });

  static double of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_SkeletonInheritedOpacity>();
    return inherited?.opacity ?? 0.55;
  }

  @override
  bool updateShouldNotify(_SkeletonInheritedOpacity oldWidget) {
    return oldWidget.opacity != opacity;
  }
}

/// A lightweight, GPU-accelerated breathing shimmer container that synchronizes
/// opacity animations for all [SkeletonBox], [SkeletonLine], and [SkeletonCircle] children.
class SkeletonShimmerHost extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minOpacity;
  final double maxOpacity;

  const SkeletonShimmerHost({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1100),
    this.minOpacity = 0.28,
    this.maxOpacity = 0.68,
  });

  @override
  State<SkeletonShimmerHost> createState() => _SkeletonShimmerHostState();
}

class _SkeletonShimmerHostState extends State<SkeletonShimmerHost>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: widget.minOpacity,
      end: widget.maxOpacity,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return _SkeletonInheritedOpacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// A rectangular skeleton placeholder with customizable dimensions and border radius.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? baseColor;
  final Widget? child;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 14.0,
    this.margin,
    this.padding,
    this.baseColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = _SkeletonInheritedOpacity.of(context);
    final color = baseColor ?? AppColors.primary;

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity * 0.25),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }
}

/// A line skeleton placeholder ideal for simulated text lines.
class SkeletonLine extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final Color? baseColor;

  const SkeletonLine({
    super.key,
    this.width,
    this.height = 14.0,
    this.borderRadius = 6.0,
    this.margin,
    this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
      margin: margin,
      baseColor: baseColor,
    );
  }
}

/// A circular skeleton placeholder ideal for avatars, icons, or indicators.
class SkeletonCircle extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry? margin;
  final Color? baseColor;

  const SkeletonCircle({
    super.key,
    this.size = 44.0,
    this.margin,
    this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = _SkeletonInheritedOpacity.of(context);
    final color = baseColor ?? AppColors.primary;

    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity * 0.3),
      ),
    );
  }
}
