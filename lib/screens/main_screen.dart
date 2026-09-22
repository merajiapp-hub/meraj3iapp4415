import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'home_page.dart';
import 'notes_screen.dart';
import 'task_manager_screen.dart';
import 'downloads_screen.dart';
import 'favorites_screen.dart';

class MainScreen extends StatefulWidget {
  final bool isGuest;
  const MainScreen({super.key, this.isGuest = false});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _exitToastShown = false;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(isGuest: widget.isGuest),
      NotesScreen(onBackToHome: () => setState(() => _currentIndex = 0)),
      const TaskManagerScreen(),
      const DownloadsScreen(),
      const FavoritesScreen(),
    ];
  }

  void _handleBackButton() {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }

    if (_exitToastShown) {
      SystemNavigator.pop();
      return;
    }
    _exitToastShown = true;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (ctx) => Positioned(
        bottom: 80,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B2A2A), Color(0xFF0D3030)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'اضغط مرة أخرى للخروج من التطبيق',
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
      if (mounted) _exitToastShown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _handleBackButton();
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          decoration: const BoxDecoration(color: Colors.transparent),
          child: SafeArea(
            child: Container(
              height: 90,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _NavItem(
                      icon: Icons.home_rounded,
                      label: 'الرئيسية',
                      index: 0,
                      currentIndex: _currentIndex,
                      onTap: () => setState(() => _currentIndex = 0),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.edit_note_rounded,
                      label: 'الملاحظات',
                      index: 1,
                      currentIndex: _currentIndex,
                      onTap: () {
                        if (widget.isGuest) {
                          _showGuestSnackBar();
                          return;
                        }
                        setState(() => _currentIndex = 1);
                      },
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.task_alt_rounded,
                      label: 'المهام',
                      index: 2,
                      currentIndex: _currentIndex,
                      onTap: () {
                        if (widget.isGuest) {
                          _showGuestSnackBar();
                          return;
                        }
                        setState(() => _currentIndex = 2);
                      },
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.download_rounded,
                      label: 'التنزيلات',
                      index: 3,
                      currentIndex: _currentIndex,
                      onTap: () {
                        if (widget.isGuest) {
                          _showGuestSnackBar();
                          return;
                        }
                        setState(() => _currentIndex = 3);
                      },
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.favorite_rounded,
                      label: 'المفضلة',
                      index: 4,
                      currentIndex: _currentIndex,
                      onTap: () {
                        if (widget.isGuest) {
                          _showGuestSnackBar();
                          return;
                        }
                        setState(() => _currentIndex = 4);
                      },
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

  void _showGuestSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'يرجى تسجيل الدخول للوصول لهذه الميزة',
          style: GoogleFonts.tajawal(),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    final activeColor = AppTheme.primaryColor;
    final inactiveColor = const Color(0xFF6C7A7A);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        height: 72,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: isSelected ? 52 : 42,
              height: isSelected ? 52 : 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF0B6B58), Color(0xFF14A085)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : const Color(0xFFF3F7F7),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0B6B58) : const Color(0xFFE7ECEC),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0B6B58).withValues(alpha: 0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: isSelected ? 24 : 22,
                color: isSelected ? Colors.white : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: GoogleFonts.tajawal(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? activeColor : inactiveColor,
                height: 1.2,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
