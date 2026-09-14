import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// رأس موحد على نمط البطاقة المقطوعة/المقصوصة، مشابه للتصميم المطلوب.
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
    this.height = 90,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        children: [
          if (showBackButton || trailing != null)
            SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (showBackButton)
                    _buildExternalButton(
                      context,
                      Icons.arrow_forward_rounded,
                      () => Navigator.maybePop(context),
                    )
                  else
                    const SizedBox(width: 40),
                  if (trailing != null)
                    trailing!
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),
          ClipPath(
            clipper: _CutHeaderClipper(),
            child: Container(
              height: height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: gradient,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  maxLines: 1,
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return IconButton(
      onPressed: onPressed,
      tooltip: 'رجوع',
      icon: Icon(icon, color: Colors.black54, size: 28),
    );
  }
}

class _CutHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - 58, 0);
    path.lineTo(size.width, size.height * 0.34);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
