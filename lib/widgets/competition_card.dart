import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CompetitionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String emoji;
  final Gradient gradient;
  final bool isPublished;
  final VoidCallback? onTap;

  const CompetitionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.emoji,
    required this.gradient,
    required this.isPublished,
    this.onTap,
  });

  @override
  State<CompetitionCard> createState() => _CompetitionCardState();
}

class _CompetitionCardState extends State<CompetitionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cardContent = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isPublished
            ? (isDark ? const Color(0xFF1E293B) : Colors.white)
            : (isDark ? const Color(0xFF0F172A) : Colors.grey[100]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: widget.isPublished
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
        border: Border.all(
          color: widget.isPublished
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFF1F5F9))
              : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: widget.isPublished
                  ? widget.gradient
                  : LinearGradient(
                      colors: isDark
                          ? [Colors.grey[800]!, Colors.grey[700]!]
                          : [Colors.grey[400]!, Colors.grey[300]!],
                    ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: widget.isPublished
                  ? [
                      BoxShadow(
                        color: (widget.gradient as LinearGradient)
                            .colors
                            .first
                            .withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                widget.emoji,
                style: TextStyle(
                  fontSize: 28,
                  foreground: widget.isPublished
                      ? null
                      : (Paint()
                        ..colorFilter = const ColorFilter.mode(
                          Colors.grey,
                          BlendMode.saturation,
                        )),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.title,
                        style: GoogleFonts.tajawal(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.isPublished
                              ? (isDark ? Colors.white : Colors.black87)
                              : Colors.grey[500],
                        ),
                      ),
                    ),
                    if (!widget.isPublished) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'قريباً',
                          style: GoogleFonts.tajawal(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[700],
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: widget.isPublished ? Colors.grey[500] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: widget.isPublished ? Colors.grey[400] : Colors.transparent,
          ),
        ],
      ),
    );

    if (!widget.isPublished) {
      return cardContent;
    }

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: cardContent,
      ),
    );
  }
}
