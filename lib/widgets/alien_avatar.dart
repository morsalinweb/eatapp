// path: lib/widgets/alien_avatar.dart
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// A painted "alien head" avatar used as the on-brand placeholder wherever
/// a person hasn't set a real profile photo yet. When [imageUrl] is
/// provided (a real uploaded photo), it's shown instead — the painted
/// alien remains the fallback while it loads, on error, or when no photo
/// has been set.
class AlienAvatar extends StatelessWidget {
  final double size;
  final bool glow;
  final Color background;
  final String? imageUrl;

  const AlienAvatar({
    super.key,
    this.size = 44,
    this.glow = false,
    this.background = AppColors.surfaceRaised,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = imageUrl != null && imageUrl!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.neonDim, width: 1.4),
        boxShadow: glow ? AppShadows.neonGlow(blur: 14, opacity: 0.4) : null,
      ),
      child: hasPhoto
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorBuilder: (context, error, stackTrace) => _fallback(),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() => Padding(
        padding: EdgeInsets.all(size * 0.16),
        child: CustomPaint(painter: _AlienHeadPainter()),
      );
}

class _AlienHeadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neon
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round;

    final headRect = Rect.fromLTWH(
      size.width * 0.18,
      0,
      size.width * 0.64,
      size.height * 0.82,
    );
    final headPath = Path()
      ..addOval(headRect);
    canvas.drawPath(headPath, paint);

    final eyePaint = Paint()..color = AppColors.neon;
    final leftEye = Rect.fromCenter(
      center: Offset(size.width * 0.37, size.height * 0.42),
      width: size.width * 0.16,
      height: size.height * 0.26,
    );
    final rightEye = Rect.fromCenter(
      center: Offset(size.width * 0.63, size.height * 0.42),
      width: size.width * 0.16,
      height: size.height * 0.26,
    );
    canvas.drawOval(leftEye, eyePaint);
    canvas.drawOval(rightEye, eyePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}