// path: lib/widgets/live_badge.dart
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Small pulsing "LIVE" pill. Used on vendor cards, profile headers,
/// and as a modifier over map markers so live vendors are unmistakable.
class LiveBadge extends StatefulWidget {
  final double fontSize;
  const LiveBadge({super.key, this.fontSize = 11});

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.neon.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neon, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween(begin: 0.35, end: 1.0).animate(_controller),
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.neon,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'LIVE',
            style: TextStyle(
              color: AppColors.neon,
              fontWeight: FontWeight.w700,
              fontSize: widget.fontSize,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
