import 'package:flutter/material.dart';

/// شارة حساب المشترك الذهبية PRO
class ProBadge extends StatelessWidget {
  final double fontSize;
  final bool showCrown;
  final EdgeInsets padding;

  const ProBadge({
    super.key,
    this.fontSize = 11,
    this.showCrown = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFDE68A),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showCrown) ...[
            Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: fontSize + 3,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            'PRO',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
