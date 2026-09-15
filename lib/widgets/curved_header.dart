import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// رأس موحد ذو زوايا دائرية
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
    this.height = 70,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      height: height + topPadding,
      padding: EdgeInsets.only(top: topPadding),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...?decorations,
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: GoogleFonts.tajawal(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: GoogleFonts.tajawal(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
          // Back Button (Right side for RTL Arabic)
          if (showBackButton)
            Positioned(
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.maybePop(context),
                tooltip: 'رجوع',
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 26),
              ),
            ),
          // Trailing Action (Left side)
          if (trailing != null)
            Positioned(
              left: 8,
              child: trailing!,
            ),
        ],
      ),
    );
  }
}
