import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/notifications_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/curved_header.dart';
import 'announcements_screen.dart';
import 'news_screen.dart';
import 'notification_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'all';

  List<String> get _filterOptions => const [
    'all',
    'general',
    'news',
    'announcement',
    'certificate',
    'unread',
  ];

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _headerController,
            curve: Curves.easeOutCubic,
          ),
        );
    _headerController.forward();

    // تعليم جميع الإشعارات كمقروءة عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationsProvider>(
        context,
        listen: false,
      ).markAllAsRead();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundDark
          : const Color(0xFFF0F4F8),
      body: Column(
        children: [
          _buildCurvedHeader(isDark),
          _buildFilterBar(isDark),
          Expanded(
            child: Consumer<NotificationsProvider>(
              builder: (context, provider, _) {
                // ─── حالة التحميل ───────────────────────────────────
                if (provider.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'جارٍ تحميل الإشعارات...',
                          style: GoogleFonts.tajawal(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                List<AppNotificationModel> notifications = provider
                    .notifications
                    .toList();
                if (_activeFilter != 'all') {
                  notifications = notifications.where((n) {
                    switch (_activeFilter) {
                      case 'unread':
                        return !n.isRead;
                      case 'general':
                        return {
                          NotificationType.general,
                          NotificationType.update,
                          NotificationType.reminder,
                          NotificationType.system,
                          NotificationType.chatReply,
                        }.contains(n.type);
                      case 'news':
                        return n.type == NotificationType.news;
                      case 'announcement':
                        return n.type == NotificationType.announcement;
                      case 'certificate':
                        return n.type == NotificationType.certificate;
                      default:
                        return true;
                    }
                  }).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  notifications = notifications
                      .where(
                        (n) =>
                            n.title.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                            n.body.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ),
                      )
                      .toList();
                }

                if (notifications.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return _NotificationCard(
                      notification: notifications[index],
                      isDark: isDark,
                      onDelete: () {
                        provider.deleteNotification(notifications[index].id);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── الرأس المنحني ──────────────────────────────────────────────────────────
  Widget _buildCurvedHeader(bool isDark) {
    return SlideTransition(
      position: _headerSlide,
      child: FadeTransition(
        opacity: _headerFade,
        child: Consumer<NotificationsProvider>(
          builder: (context, provider, _) => CurvedHeader(
            title: 'الإشعارات',
            gradient: AppTheme.brandGradient,
            trailing: provider.notifications.isEmpty
                ? null
                : IconButton(
                    tooltip: 'حذف الكل',
                    onPressed: () => _showDeleteAllDialog(provider),
                    icon: const Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.redAccent,
                      size: 24,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ─── شريط البحث والفلاتر ───────────────────────────────────────────────────
  Widget _buildFilterBar(bool isDark) {
    final filterLabels = {
      'all': 'الكل',
      'general': 'العامة',
      'unread': 'غير المقروء',
      'news': 'الأخبار',
      'announcement': 'الإعلانات',
      'certificate': 'الشهادات',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'البحث في الإشعارات...',
                hintStyle: GoogleFonts.tajawal(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: GoogleFonts.tajawal(fontSize: 14),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final key = _filterOptions[index];
                final selected = _activeFilter == key;
                return ChoiceChip(
                  label: Text(filterLabels[key] ?? key),
                  selected: selected,
                  onSelected: (_) => setState(() => _activeFilter = key),
                  backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.18),
                  labelStyle: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: selected
                        ? AppTheme.primaryColor
                        : (isDark ? Colors.white70 : Colors.grey[700]),
                    fontWeight: FontWeight.bold,
                  ),
                  avatar: selected
                      ? const Icon(Icons.check_rounded, size: 14)
                      : null,
                  side: BorderSide(
                    color: selected
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── الحالة الفارغة ─────────────────────────────────────────────────────────
  Widget _buildEmptyState(bool isDark) {
    final emptyMessage = switch (_activeFilter) {
      'all' =>
        _searchQuery.isNotEmpty ? 'لا توجد نتائج للبحث' : 'لا توجد إشعارات',
      'general' => 'لا توجد إشعارات عامة',
      'unread' => 'لا توجد إشعارات غير مقروءة',
      'news' => 'لا توجد إشعارات للأخبار',
      'announcement' => 'لا توجد إشعارات للإعلانات',
      'certificate' => 'لا توجد إشعارات للشهادات',
      _ => 'لا توجد إشعارات',
    };

    final emptySubtitle = _searchQuery.isNotEmpty
        ? 'حاول البحث بكلمات أخرى'
        : _activeFilter == 'all'
        ? 'ستظهر هنا إشعاراتك الجديدة'
        : 'جرب فلترًا مختلفًا';

    return SizedBox.expand(
      child: Container(
        color: isDark ? AppTheme.backgroundDark : const Color(0xFFF0F4F8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                emptyMessage,
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── حوار حذف الكل ─────────────────────────────────────────────────────────
  void _showDeleteAllDialog(NotificationsProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'حذف جميع الإشعارات',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'هل أنت متأكد من حذف جميع الإشعارات؟',
          style: GoogleFonts.tajawal(),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: GoogleFonts.tajawal(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteAll();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'حذف الكل',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── بطاقة الإشعار ───────────────────────────────────────────────────────────
class _NotificationCard extends StatefulWidget {
  final AppNotificationModel notification;
  final bool isDark;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.isDark,
    required this.onDelete,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _openRelatedScreen(BuildContext context) async {
    final targetType = widget.notification.targetType;
    if (targetType == 'externalUrl') {
      final uri = Uri.tryParse(widget.notification.targetId ?? '');
      if (uri == null ||
          !uri.hasAuthority ||
          uri.host.isEmpty ||
          !const {'http', 'https'}.contains(uri.scheme.toLowerCase())) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('رابط الإشعار غير صالح.')));
        return;
      }
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر فتح الرابط.')));
      }
      return;
    }
    final route = switch (targetType) {
      'news' => MaterialPageRoute(
        builder: (_) => NewsScreen(selectedId: widget.notification.targetId),
      ),
      'announcement' => MaterialPageRoute(
        builder: (_) =>
            AnnouncementsScreen(selectedId: widget.notification.targetId),
      ),
      _ => MaterialPageRoute(
        builder: (_) =>
            NotificationDetailsScreen(notification: widget.notification),
      ),
    };

    await Navigator.push(context, route);
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return DateFormat('dd/MM/yyyy – hh:mm a', 'ar').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.redAccent),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          onTapDown: (_) => _scaleController.forward(),
          onTapUp: (_) => _scaleController.reverse(),
          onTapCancel: () => _scaleController.reverse(),
          onTap: () {
            _scaleController.reverse();
            _openRelatedScreen(context);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: widget.isDark ? AppTheme.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: n.isRead
                    ? (widget.isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFF1F5F9))
                    : n.typeColor.withValues(alpha: 0.3),
                width: n.isRead ? 1 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: n.typeColor.withValues(alpha: n.isRead ? 0.05 : 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // أيقونة النوع
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: n.typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(n.typeIcon, color: n.typeColor, size: 24),
                        if (!n.isRead)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: n.typeColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: n.typeColor.withValues(alpha: 0.4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // المحتوى
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                n.title,
                                style: GoogleFonts.tajawal(
                                  fontSize: 15,
                                  fontWeight: n.isRead
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                  color: widget.isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            // badge النوع
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: n.typeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                n.typeLabel,
                                style: GoogleFonts.tajawal(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: n.typeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          n.body,
                          style: GoogleFonts.tajawal(
                            fontSize: 13,
                            color: widget.isDark
                                ? Colors.white60
                                : const Color(0xFF64748B),
                            height: 1.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(n.timestamp),
                              style: GoogleFonts.tajawal(
                                fontSize: 11,
                                color: Colors.grey[400],
                              ),
                            ),
                            const Spacer(),
                            if (!n.isRead)
                              Text(
                                '● غير مقروء',
                                style: GoogleFonts.tajawal(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: n.typeColor,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: () => _openRelatedScreen(context),
                            icon: Icon(
                              n.targetType == 'externalUrl'
                                  ? Icons.open_in_new_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 16,
                            ),
                            label: Text(
                              switch (n.targetType) {
                                'news' => 'فتح الخبر',
                                'announcement' => 'فتح الإعلان',
                                'externalUrl' => 'فتح الرابط',
                                'certificate' => 'عرض الشهادة',
                                'chat' => 'فتح المحادثة',
                                _ => 'عرض التفاصيل',
                              },
                              style: GoogleFonts.tajawal(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // زر الحذف
                  IconButton(
                    onPressed: widget.onDelete,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.grey[400],
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
