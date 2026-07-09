import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Illustration originale et stylisée (pas une photo) de la e-208 : silhouette
/// jaune avec bandes noires façon "racing stripes" sur le capot/toit.
class CarHero extends StatelessWidget {
  const CarHero({super.key, this.height = 180});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.surfaceAlt, AppColors.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _CarSilhouettePainter()),
          ),
          Positioned(
            left: 16,
            top: 14,
            child: Text(
              'e-208',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final groundY = h * 0.78;

    final bodyPaint = Paint()..color = AppColors.yellow;
    final stripePaint = Paint()..color = AppColors.stripe;
    final glassPaint = Paint()..color = Colors.black.withOpacity(0.55);
    final wheelPaint = Paint()..color = Colors.black;
    final rimPaint = Paint()..color = Colors.white.withOpacity(0.85);

    // Corps de la voiture (silhouette simplifiée, vue de profil).
    final body = Path()
      ..moveTo(w * 0.08, groundY)
      ..lineTo(w * 0.10, groundY - h * 0.16)
      ..quadraticBezierTo(w * 0.16, groundY - h * 0.30, w * 0.30, groundY - h * 0.34)
      ..lineTo(w * 0.40, groundY - h * 0.34)
      ..quadraticBezierTo(w * 0.46, groundY - h * 0.52, w * 0.60, groundY - h * 0.52)
      ..quadraticBezierTo(w * 0.72, groundY - h * 0.52, w * 0.76, groundY - h * 0.34)
      ..lineTo(w * 0.85, groundY - h * 0.34)
      ..quadraticBezierTo(w * 0.94, groundY - h * 0.30, w * 0.95, groundY - h * 0.14)
      ..lineTo(w * 0.95, groundY)
      ..close();
    canvas.drawPath(body, bodyPaint);

    // Vitres.
    final glass = Path()
      ..moveTo(w * 0.42, groundY - h * 0.34)
      ..quadraticBezierTo(w * 0.47, groundY - h * 0.47, w * 0.59, groundY - h * 0.47)
      ..quadraticBezierTo(w * 0.68, groundY - h * 0.47, w * 0.73, groundY - h * 0.34)
      ..close();
    canvas.drawPath(glass, glassPaint);

    // Bandes noires façon "racing stripes" sur le capot/toit.
    for (final dx in [0.47, 0.53]) {
      final stripe = Path()
        ..moveTo(w * dx, groundY - h * 0.52)
        ..lineTo(w * (dx + 0.03), groundY - h * 0.52)
        ..lineTo(w * (dx + 0.01), groundY - h * 0.20)
        ..lineTo(w * (dx - 0.02), groundY - h * 0.20)
        ..close();
      canvas.drawPath(stripe, stripePaint);
    }

    // Roues.
    final wheelRadius = h * 0.09;
    for (final cx in [w * 0.26, w * 0.80]) {
      final center = Offset(cx, groundY);
      canvas.drawCircle(center, wheelRadius, wheelPaint);
      canvas.drawCircle(center, wheelRadius * 0.45, rimPaint);
    }

    // Sol.
    final groundPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, groundY + wheelRadius * 0.9), Offset(w, groundY + wheelRadius * 0.9), groundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
