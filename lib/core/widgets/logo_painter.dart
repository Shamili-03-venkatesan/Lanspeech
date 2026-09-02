import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lanspeech/core/constants/colors.dart';

class LanSpeechLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isDark;

  const LanSpeechLogo({
    super.key,
    this.size = 100,
    this.showText = true,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.white : AppColors.navy;
    final subtitleColor = isDark ? AppColors.yellow : AppColors.teal;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: LogoPainter(),
        ),
        if (showText) ...[
          const SizedBox(height: 16),
          Text(
            'LanSpeech',
            style: GoogleFonts.poppins(
              fontSize: size * 0.28,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Speak. Practice. Progress.',
            style: GoogleFonts.poppins(
              fontSize: size * 0.12,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
              letterSpacing: 1.0,
            ),
          ),
        ]
      ],
    );
  }
}

class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Use scale factor to support any widget dimensions
    final double scale = w / 100.0;

    // Paints
    final facePaint = Paint()
      ..color = AppColors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * scale
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = AppColors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * scale
      ..strokeCap = StrokeCap.round;

    final wavePrimaryPaint = Paint()
      ..color = AppColors.darkTeal
      ..style = PaintingStyle.fill;

    final waveAccentPaint = Paint()
      ..color = AppColors.yellow
      ..style = PaintingStyle.fill;

    // Draw Gold/Orange Outer Speech Arc
    // An elegant arc spanning from upper-right down around to bottom-right
    final rect = Rect.fromCircle(
      center: Offset(50 * scale, 50 * scale),
      radius: 44 * scale,
    );
    canvas.drawArc(
      rect,
      -0.5, // Start angle (radians)
      4.2, // Sweep angle
      false,
      arcPaint,
    );

    // Draw Left-Facing Human Silhouette Path
    final facePath = Path();
    // Start at top forehead area
    facePath.moveTo(50 * scale, 12 * scale);
    // Forehead curve
    facePath.quadraticBezierTo(
      34 * scale,
      14 * scale,
      30 * scale,
      30 * scale,
    );
    // Nose bridge
    facePath.lineTo(26 * scale, 42 * scale);
    // Nose tip
    facePath.lineTo(20 * scale, 45 * scale);
    facePath.lineTo(27 * scale, 49 * scale);
    // Lip curve top
    facePath.quadraticBezierTo(
      24 * scale,
      52 * scale,
      27 * scale,
      55 * scale,
    );
    // Lower lip
    facePath.quadraticBezierTo(
      23 * scale,
      58 * scale,
      28 * scale,
      62 * scale,
    );
    // Chin
    facePath.quadraticBezierTo(
      26 * scale,
      68 * scale,
      33 * scale,
      71 * scale,
    );
    // Jawline
    facePath.quadraticBezierTo(
      45 * scale,
      74 * scale,
      48 * scale,
      86 * scale,
    );

    canvas.drawPath(facePath, facePaint);

    // Draw Sound Wave bars inside (x centers roughly around 50 to 70)
    // 5 bars with rounded capsules
    _drawCapsule(canvas, 48 * scale, 50 * scale, 4 * scale, 16 * scale,
        wavePrimaryPaint);
    _drawCapsule(canvas, 55 * scale, 50 * scale, 4 * scale, 28 * scale,
        wavePrimaryPaint);
    _drawCapsule(canvas, 62 * scale, 50 * scale, 4 * scale, 42 * scale,
        waveAccentPaint); // Tall middle orange bar
    _drawCapsule(canvas, 69 * scale, 50 * scale, 4 * scale, 28 * scale,
        wavePrimaryPaint);
    _drawCapsule(canvas, 76 * scale, 50 * scale, 4 * scale, 16 * scale,
        wavePrimaryPaint);
  }

  void _drawCapsule(Canvas canvas, double x, double centerY, double width,
      double height, Paint paint) {
    final rect = Rect.fromCenter(
      center: Offset(x, centerY),
      width: width,
      height: height,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(width / 2));
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
