import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class GeometricSliverAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Gradient? gradient;
  final List<Widget>? actions;
  final bool showBackButton;

  const GeometricSliverAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.gradient,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 90,
      pinned: true,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
      ),
      backgroundColor: Colors.transparent,
      leading: showBackButton
          ? IconButton(
              tooltip: 'رجوع',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 26,
              ),
            )
          : null,
      actions: actions,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: gradient ?? AppTheme.brandGradient,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: FlexibleSpaceBar(
          centerTitle: true,
          titlePadding: const EdgeInsets.only(bottom: 16, left: 40, right: 40),
          title: Text(
            title,
            maxLines: 1,
            style: GoogleFonts.tajawal(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 17,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
