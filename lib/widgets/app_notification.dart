import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum NotifType { success, error, warning, info }

class AppNotification {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    NotifType? type,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    final resolvedType =
        type ?? (isError ? NotifType.error : NotifType.success);

    entry = OverlayEntry(
      builder: (context) => _NotificationWidget(
        message: message,
        type: resolvedType,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (entry.mounted) entry.remove();
    });
  }

  static void showLogout(BuildContext context) {
    show(context, 'تم تسجيل الخروج بنجاح', type: NotifType.info);
  }
}

class _NotificationWidget extends StatefulWidget {
  final String message;
  final NotifType type;
  final VoidCallback onDismiss;

  const _NotificationWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _bgColor {
    switch (widget.type) {
      case NotifType.success:
        return const Color(0xFF10B981);
      case NotifType.error:
        return const Color(0xFFEF4444);
      case NotifType.warning:
        return const Color(0xFFF59E0B);
      case NotifType.info:
        return const Color(0xFF3B82F6);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case NotifType.success:
        return Icons.check_circle_rounded;
      case NotifType.error:
        return Icons.cancel_rounded;
      case NotifType.warning:
        return Icons.warning_rounded;
      case NotifType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _bgColor.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(_icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: GoogleFonts.tajawal(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
