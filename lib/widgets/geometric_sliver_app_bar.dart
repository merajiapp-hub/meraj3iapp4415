import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'curved_header.dart';

class GeometricSliverAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Gradient? gradient;
  final List<Widget>? actions;

  const GeometricSliverAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.gradient,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, right: 48, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 10),
              ),
          ],
        ),
        background: ClipPath(
          clipper: MerajHeaderClipper(),
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient ?? AppTheme.deepBlueGradient,
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Positioned(
                  left: -50,
                  bottom: -40,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  right: 80,
                  bottom: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.03),
                    ),
                  ),
                ),
                if (icon != null)
                  Positioned(
                    left: 18,
                    bottom: 8,
                    child: Icon(
                      icon,
                      size: 66,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

