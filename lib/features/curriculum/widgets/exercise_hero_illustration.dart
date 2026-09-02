import 'package:flutter/material.dart';

import 'package:lanspeech/core/constants/colors.dart';

/// The calm hero illustration (face silhouette + soundwave + leaf sprout,
/// inside a soft glow) used on exercise screens that don't already have a
/// recording or reflection control competing for visual focus — see
/// [ExercisePlayerScreen] for exactly when this appears.
///
/// This reuses the same hand-drawn [CustomPainter] approach already used
/// for [LanSpeechLogo] rather than introducing an image asset or a new
/// illustration package, so the app's whole visual language — logo, hero
/// art, everything — comes from the same drawing technique and palette.
class ExerciseHeroIllustration extends StatelessWidget {
  final double size;

  const ExerciseHeroIllustration({super.key, this.size = 220});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.teal.withOpacity(0.12),
            ),
          ),
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.teal.withOpacity(0.10),
            ),
          ),
          CustomPaint(
            size: Size(size, size),
            painter: _HeroPainter(),
          ),
        ],
      ),
    );
  }
}

class _HeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 220.0;

    final facePaint = Paint()
      ..color = AppColors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * scale
      ..strokeCap = StrokeCap.round;

    final wavePrimaryPaint = Paint()
      ..color = AppColors.darkTeal
      ..style = PaintingStyle.fill;

    final waveAccentPaint = Paint()
      ..color = AppColors.yellow
      ..style = PaintingStyle.fill;

    final sparklePaint = Paint()
      ..color = AppColors.yellow.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final leafPaint = Paint()
      ..color = AppColors.teal.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    // Left-facing face silhouette, positioned left-of-center.
    final facePath = Path()
      ..moveTo(110 * scale, 40 * scale)
      ..quadraticBezierTo(80 * scale, 44 * scale, 70 * scale, 72 * scale)
      ..lineTo(62 * scale, 96 * scale)
      ..lineTo(48 * scale, 102 * scale)
      ..lineTo(64 * scale, 110 * scale)
      ..quadraticBezierTo(56 * scale, 116 * scale, 64 * scale, 122 * scale)
      ..quadraticBezierTo(54 * scale, 128 * scale, 66 * scale, 136 * scale)
      ..quadraticBezierTo(60 * scale, 146 * scale, 76 * scale, 152 * scale)
      ..quadraticBezierTo(100 * scale, 158 * scale, 106 * scale, 182 * scale);
    canvas.drawPath(facePath, facePaint);

    // Soundwave bars in front of the face, one accent bar in the middle.
    _bar(canvas, 108 * scale, 108 * scale, 6 * scale, 26 * scale, wavePrimaryPaint);
    _bar(canvas, 122 * scale, 108 * scale, 6 * scale, 46 * scale, wavePrimaryPaint);
    _bar(canvas, 136 * scale, 108 * scale, 7 * scale, 70 * scale, waveAccentPaint);
    _bar(canvas, 150 * scale, 108 * scale, 6 * scale, 46 * scale, wavePrimaryPaint);
    _bar(canvas, 164 * scale, 108 * scale, 6 * scale, 26 * scale, wavePrimaryPaint);

    // Small leaf sprout, lower-right of the soundwave.
    final leafPath1 = Path()
      ..moveTo(118 * scale, 176 * scale)
      ..quadraticBezierTo(112 * scale, 158 * scale, 130 * scale, 150 * scale)
      ..quadraticBezierTo(126 * scale, 168 * scale, 118 * scale, 176 * scale);
    canvas.drawPath(leafPath1, leafPaint);

    final leafPath2 = Path()
      ..moveTo(118 * scale, 176 * scale)
      ..quadraticBezierTo(126 * scale, 164 * scale, 146 * scale, 164 * scale)
      ..quadraticBezierTo(134 * scale, 174 * scale, 118 * scale, 176 * scale);
    canvas.drawPath(leafPath2, leafPaint);

    // Scattered sparkle accents.
    _sparkle(canvas, Offset(40 * scale, 50 * scale), 4 * scale, sparklePaint);
    _sparkle(canvas, Offset(178 * scale, 60 * scale), 3 * scale, sparklePaint);
    _sparkle(canvas, Offset(190 * scale, 130 * scale), 3.5 * scale, sparklePaint);
  }

  void _bar(Canvas canvas, double x, double centerY, double width, double height, Paint paint) {
    final rect = Rect.fromCenter(center: Offset(x, centerY), width: width, height: height);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(width / 2)), paint);
  }

  void _sparkle(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r * 0.3, center.dy - r * 0.3)
      ..lineTo(center.dx + r, center.dy)
      ..lineTo(center.dx + r * 0.3, center.dy + r * 0.3)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r * 0.3, center.dy + r * 0.3)
      ..lineTo(center.dx - r, center.dy)
      ..lineTo(center.dx - r * 0.3, center.dy - r * 0.3)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
