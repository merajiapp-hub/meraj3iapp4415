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
      expandedHeight: 110,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: showBackButton
          ? IconButton(
              tooltip: 'رجوع',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.black54,
                size: 28,
              ),
            )
          : null,
      leadingWidth: showBackButton ? 54 : 0,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
          child: ClipPath(
            clipper: _CutSliverHeaderClipper(),
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient ?? AppTheme.brandGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.14),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
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
              ),
            ),
          ),
        ),
      ),
      title: null,
    );
  }
}

class _CutSliverHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - 52, 0);
    path.lineTo(size.width, size.height * 0.34);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
