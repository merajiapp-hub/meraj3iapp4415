import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../data/note_models.dart';

class PaperBackground extends StatelessWidget {
  final NotePageSettings settings;
  final Widget child;

  const PaperBackground({
    super.key,
    required this.settings,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PaperPainter(settings: settings),
      child: child,
    );
  }
}

class _PaperPainter extends CustomPainter {
  final NotePageSettings settings;

  _PaperPainter({required this.settings});

  @override
  void paint(Canvas canvas, Size size) {
    if (settings.paperType == 'blank') return;

    final paint = Paint()
      ..color = (settings.lineColor != null 
          ? Color(settings.lineColor!) 
          : (settings.isDark ? Colors.white : Colors.black))
          .withValues(alpha: settings.lineOpacity)
      ..strokeWidth = 1.0;

    final spacing = settings.lineSpacing;

    if (settings.paperType == 'horizontal' || settings.paperType == 'school') {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      
      // Add red margin line for school paper
      if (settings.paperType == 'school') {
        final marginPaint = Paint()
          ..color = Colors.red.withValues(alpha: 0.3)
          ..strokeWidth = 1.5;
        canvas.drawLine(const Offset(40, 0), Offset(40, size.height), marginPaint);
      }
    } else if (settings.paperType == 'vertical') {
      for (double x = spacing; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
    } else if (settings.paperType == 'grid') {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      for (double x = spacing; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
    } else if (settings.paperType == 'dots') {
      paint.strokeCap = StrokeCap.round;
      paint.strokeWidth = 2.0;
      for (double y = spacing; y < size.height; y += spacing) {
        for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawPoints(ui.PointMode.points, [Offset(x, y)], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PaperPainter oldDelegate) {
    return oldDelegate.settings.paperType != settings.paperType ||
           oldDelegate.settings.lineSpacing != settings.lineSpacing ||
           oldDelegate.settings.lineColor != settings.lineColor ||
           oldDelegate.settings.lineOpacity != settings.lineOpacity ||
           oldDelegate.settings.isDark != settings.isDark;
  }
}

