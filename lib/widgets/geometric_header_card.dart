import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class GeometricHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final EdgeInsetsGeometry margin;

  const GeometricHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.gradient = AppTheme.brandGradient,
    this.margin = const EdgeInsets.fromLTRB(16, 14, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: 112,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(34),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GeometryPainter())),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.tajawal(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.tajawal(
                          color: Colors.white.withValues(alpha: 0.76),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70,
                  size: 17,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GeometryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = Colors.white.withValues(alpha: 0.07);
    final first = Path()
      ..moveTo(size.width * 0.62, 0)
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.32,
        size.width * 0.62,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(first, paint);

    paint.color = Colors.black.withValues(alpha: 0.06);
    final second = Path()
      ..moveTo(0, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.42,
        size.width * 0.38,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(second, paint);

    paint.color = Colors.white.withValues(alpha: 0.14);
    canvas.drawCircle(Offset(size.width * 0.86, size.height * 0.18), 3, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.26), 1.5, paint);
  }

  @override
  bool shouldRepaint(covariant _GeometryPainter oldDelegate) => false;
}
