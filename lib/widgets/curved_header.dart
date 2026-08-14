import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// رأس منحنٍ احترافي قابل لإعادة الاستخدام في جميع صفحات التطبيق
class CurvedHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Gradient gradient;
  final IconData? leadingIcon;
  final Widget? trailing;
  final List<Widget>? decorations;
  final double height;
  final bool showBackButton;

  const CurvedHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.gradient,
    this.leadingIcon,
    this.trailing,
    this.decorations,
    this.height = 170,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CurvedHeaderClipper(),
      child: Container(
        height: height,
        decoration: BoxDecoration(gradient: gradient),
        child: Stack(
          children: [
            // زخارف الخلفية
            Positioned(
              top: -40,
              left: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              right: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            // زخارف إضافية مخصصة
            ...?decorations,
            // المحتوى
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (showBackButton)
                      _buildBackButton(context)
                    else if (leadingIcon != null)
                      _buildLeadingIcon(leadingIcon!)
                    else
                      const SizedBox(width: 48),
                    // العنوان في المنتصف
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.tajawal(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: GoogleFonts.tajawal(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // عنصر اليمين
                    trailing ?? const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.pop(context),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

// ─── منحنى الحافة السفلية ──────────────────────────────────────────────────
class _CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height + 10,
      size.width * 0.5,
      size.height - 20,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 50,
      size.width,
      size.height - 30,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
