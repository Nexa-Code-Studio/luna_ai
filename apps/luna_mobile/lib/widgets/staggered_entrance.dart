import 'dart:async';
import 'package:flutter/material.dart';

/// Lightweight, GPU-accelerated entrance animation that staggers content
/// appearance (fade + gentle upward slide) one-by-one based on [index].
class StaggeredEntrance extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration baseDelay;
  final Duration staggerInterval;
  final Duration duration;
  final Offset slideOffset;

  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 60),
    this.staggerInterval = const Duration(milliseconds: 40),
    this.duration = const Duration(milliseconds: 320),
    this.slideOffset = const Offset(0.0, 0.08),
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curved = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(curved);

    final delayMs = widget.baseDelay.inMilliseconds +
        (widget.index.clamp(0, 8) * widget.staggerInterval.inMilliseconds);

    if (delayMs <= 0) {
      _animController.forward();
    } else {
      _delayTimer = Timer(Duration(milliseconds: delayMs), () {
        if (mounted) {
          _animController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
