import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/video_lesson_models.dart';
import 'video_web_embed.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  VideoPlayerWidget — عارض فيديو فائق التطور باحترافية أعلى من يوتيوب
// ══════════════════════════════════════════════════════════════════════════════
class VideoPlayerWidget extends StatefulWidget {
  final VideoLesson lesson;
  final String? localFilePath;
  final int initialPositionSeconds;
  final ValueChanged<int>? onPositionChanged;
  final VoidCallback? onPlayStarted;
  final VoidCallback? onCompleted;
  final bool isProUser;
  final VoidCallback? onUpgradeToPro;

  const VideoPlayerWidget({
    super.key,
    required this.lesson,
    this.localFilePath,
    this.initialPositionSeconds = 0,
    this.onPositionChanged,
    this.onPlayStarted,
    this.onCompleted,
    this.isProUser = true,
    this.onUpgradeToPro,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with TickerProviderStateMixin {
  bool _isPlaying = false;
  bool _isControlsVisible = true;
  bool _isFullscreen = false;
  bool _isLocked = false;
  bool _showUnlockHint = false;

  // الإيماءات والمؤثرات التفاعلية
  bool _showRewindIndicator = false;
  bool _showForwardIndicator = false;
  Timer? _rewindTimer;
  Timer? _forwardTimer;

  // دقة الفيديو وسرعة التشغيل
  String _selectedQuality = '1080p FHD';
  double _playbackSpeed = 1.0;
  bool _isMuted = false;

  // التوقيت والشريط
  double _currentSeconds = 0;
  double _totalDurationSeconds = 600; // قيمة افتراضية
  Timer? _controlsTimer;
  Timer? _playbackTicker;

  // الرسوم المتحركة للنبض والتكبير
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _currentSeconds = widget.initialPositionSeconds.toDouble();
    _parseDuration();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  void _parseDuration() {
    final parts = widget.lesson.duration.split(':');
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]) ?? 0;
      final s = int.tryParse(parts[1]) ?? 0;
      final total = (m * 60 + s).toDouble();
      if (total > 0) _totalDurationSeconds = total;
    } else if (parts.length == 3) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final s = int.tryParse(parts[2]) ?? 0;
      final total = (h * 3600 + m * 60 + s).toDouble();
      if (total > 0) _totalDurationSeconds = total;
    }
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _playbackTicker?.cancel();
    _rewindTimer?.cancel();
    _forwardTimer?.cancel();
    _pulseCtrl.dispose();
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    if (_isPlaying && !_isLocked) {
      _controlsTimer = Timer(const Duration(milliseconds: 3500), () {
        if (mounted && _isPlaying) {
          setState(() => _isControlsVisible = false);
        }
      });
    }
  }

  void _togglePlay() {
    if (widget.lesson.isPro && !widget.isProUser) {
      widget.onUpgradeToPro?.call();
      return;
    }

    setState(() {
      _isPlaying = !_isPlaying;
      _isControlsVisible = true;
    });

    if (_isPlaying) {
      widget.onPlayStarted?.call();
      _startTicker();
      _resetControlsTimer();
    } else {
      _playbackTicker?.cancel();
      _controlsTimer?.cancel();
    }
  }

  void _startTicker() {
    _playbackTicker?.cancel();
    _playbackTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isPlaying) return;
      setState(() {
        _currentSeconds += _playbackSpeed;
        if (_currentSeconds >= _totalDurationSeconds) {
          _currentSeconds = _totalDurationSeconds;
          _isPlaying = false;
          _isControlsVisible = true;
          widget.onCompleted?.call();
          _playbackTicker?.cancel();
        }
      });
      widget.onPositionChanged?.call(_currentSeconds.toInt());
    });
  }

  void _seekBy(double delta) {
    if (_isLocked) return;
    setState(() {
      _currentSeconds = (_currentSeconds + delta).clamp(0.0, _totalDurationSeconds);
      _isControlsVisible = true;
    });
    widget.onPositionChanged?.call(_currentSeconds.toInt());
    _resetControlsTimer();
  }

  void _triggerDoubleTapSeek(bool isForward) {
    if (_isLocked) return;
    _seekBy(isForward ? 10 : -10);

    if (isForward) {
      setState(() => _showForwardIndicator = true);
      _forwardTimer?.cancel();
      _forwardTimer = Timer(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _showForwardIndicator = false);
      });
    } else {
      setState(() => _showRewindIndicator = true);
      _rewindTimer?.cancel();
      _rewindTimer = Timer(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _showRewindIndicator = false);
      });
    }
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _resetControlsTimer();
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
      if (_isLocked) {
        _isControlsVisible = false;
        _showUnlockHint = true;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showUnlockHint = false);
        });
      } else {
        _isControlsVisible = true;
        _resetControlsTimer();
      }
    });
  }

  String _formatTime(double sec) {
    final s = sec.toInt();
    final m = s ~/ 60;
    final remainingS = s % 60;
    return '${m.toString().padLeft(2, '0')}:${remainingS.toString().padLeft(2, '0')}';
  }

  Future<void> _openExternalOrInApp() async {
    widget.onPlayStarted?.call();
    final url = widget.lesson.previewUrl;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProLocked = widget.lesson.isPro && !widget.isProUser;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(_isFullscreen ? 0 : 20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── 1. خلفية الفيديو أو الـ Iframe ──────────────────────────────
            if (kIsWeb && _isPlaying)
              Positioned.fill(
                child: VideoWebEmbed(
                  url: widget.lesson.previewUrl,
                  title: widget.lesson.title,
                ),
              )
            else
              Positioned.fill(
                child: widget.lesson.effectiveThumbnailUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.lesson.effectiveThumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: const Color(0xFF0F172A),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF14B8A6),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => _buildFallbackGraphic(),
                      )
                    : _buildFallbackGraphic(),
              ),

            // ── 2. مناطق اللمس الحساسة للإيماءات (Double Tap) ───────────────
            Positioned.fill(
              child: Row(
                children: [
                  // النصف الأيمن: نقر مزدوج لتقديم 10 ثوانٍ (في العربية اليمين هو التقديم)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onDoubleTap: () => _triggerDoubleTapSeek(true),
                      onTap: () {
                        if (_isLocked) {
                          setState(() => _showUnlockHint = true);
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) setState(() => _showUnlockHint = false);
                          });
                          return;
                        }
                        setState(() => _isControlsVisible = !_isControlsVisible);
                        if (_isControlsVisible && _isPlaying) _resetControlsTimer();
                      },
                    ),
                  ),
                  // النصف الأيسر: نقر مزدوج لتأخير 10 ثوانٍ
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onDoubleTap: () => _triggerDoubleTapSeek(false),
                      onTap: () {
                        if (_isLocked) {
                          setState(() => _showUnlockHint = true);
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) setState(() => _showUnlockHint = false);
                          });
                          return;
                        }
                        setState(() => _isControlsVisible = !_isControlsVisible);
                        if (_isControlsVisible && _isPlaying) _resetControlsTimer();
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── 3. تموجات ومؤشرات النقر المزدوج (Rewind / Forward) ─────────
            if (_showForwardIndicator)
              Positioned(
                right: 40,
                child: _buildSeekRipple(isForward: true),
              ),
            if (_showRewindIndicator)
              Positioned(
                left: 40,
                child: _buildSeekRipple(isForward: false),
              ),

            // ── 4. طبقة التعتيم الزجاجية لعناصر التحكم ─────────────────────
            if (!_isLocked)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_isControlsVisible && _isPlaying,
                  child: AnimatedOpacity(
                    opacity: (_isControlsVisible || !_isPlaying) ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── 5. حاجز الاشتراك الذهبي Pro Locked Overlay ──────────────────
            if (isProLocked)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.82),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Color(0xFFF59E0B),
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'هذا الدرس مخصص لمشتركي مراجعي Pro',
                        style: GoogleFonts.tajawal(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اشترك الآن للوصول الكامل إلى جميع الشروحات بدقة عالية وبدون إعلانات',
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.flash_on_rounded, size: 18),
                        label: Text(
                          'ترقية الحساب إلى Pro الآن ⚡',
                          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: widget.onUpgradeToPro,
                      ),
                    ],
                  ),
                ),
              ),

            // ── 6. شريط التحكم العلوي الزجاجي (HUD) ─────────────────────────
            if (!isProLocked && !_isLocked)
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: AnimatedOpacity(
                  opacity: (_isControlsVisible || !_isPlaying) ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Row(
                    children: [
                      // زر قفل الشاشة لمنع اللمس غير المقصود
                      _buildGlassIconBtn(
                        icon: Icons.lock_open_rounded,
                        tooltip: 'قفل أزرار التحكم',
                        onTap: _toggleLock,
                      ),
                      const SizedBox(width: 8),

                      // عنوان الفيديو
                      Expanded(
                        child: Text(
                          widget.lesson.title,
                          style: GoogleFonts.tajawal(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // اختيار دقة الفيديو
                      _buildQualityMenu(),
                      const SizedBox(width: 8),

                      // اختيار السرعة
                      _buildSpeedMenu(),
                      const SizedBox(width: 8),

                      // زر كتم الصوت / إلغاء الكتم
                      _buildGlassIconBtn(
                        icon: _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        tooltip: _isMuted ? 'إلغاء كتم الصوت' : 'كتم الصوت',
                        onTap: () {
                          setState(() => _isMuted = !_isMuted);
                          _resetControlsTimer();
                        },
                      ),
                      const SizedBox(width: 8),

                      // ملء الشاشة
                      _buildGlassIconBtn(
                        icon: _isFullscreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        tooltip: 'ملء الشاشة',
                        onTap: _toggleFullscreen,
                      ),
                    ],
                  ),
                ),
              ),

            // ── 7. زر فتح القفل أثناء القفل ────────────────────────────────
            if (_isLocked)
              Positioned(
                top: 14,
                left: 14,
                child: AnimatedOpacity(
                  opacity: _showUnlockHint ? 1.0 : 0.6,
                  duration: const Duration(milliseconds: 200),
                  child: InkWell(
                    onTap: _toggleLock,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF14B8A6), width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_rounded, size: 16, color: Color(0xFF14B8A6)),
                          const SizedBox(width: 6),
                          Text(
                            'اضغط لإلغاء القفل',
                            style: GoogleFonts.tajawal(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── 8. أزرار التحكم المركزية الفاخرة (Play / Pause / Seek) ─────
            if (!isProLocked && !_isLocked)
              AnimatedOpacity(
                opacity: (_isControlsVisible || !_isPlaying) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // زر التقديم 10 ثوانٍ (يمين)
                    _buildGlassActionBtn(
                      icon: Icons.forward_10_rounded,
                      label: '10s',
                      onTap: () => _seekBy(10),
                    ),
                    const SizedBox(width: 24),

                    // زر التشغيل المركزي العملاق
                    ScaleTransition(
                      scale: _isPlaying ? const AlwaysStoppedAnimation(1.0) : _pulseAnim,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows) {
                              _openExternalOrInApp();
                            } else {
                              _togglePlay();
                            }
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF006C4A), Color(0xFF059669)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF059669).withValues(alpha: 0.55),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ],
                              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),

                    // زر التأخير 10 ثوانٍ (يسار)
                    _buildGlassActionBtn(
                      icon: Icons.replay_10_rounded,
                      label: '10s',
                      onTap: () => _seekBy(-10),
                    ),
                  ],
                ),
              ),

            // ── 9. شريط السحب والتوقيت السفلي المتطور ──────────────────────
            if (!isProLocked && !_isLocked)
              Positioned(
                bottom: 6,
                left: 12,
                right: 12,
                child: AnimatedOpacity(
                  opacity: (_isControlsVisible || !_isPlaying) ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // سلايدر شريط التقدم الفخم
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4.0,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: const Color(0xFF006C4A),
                          inactiveTrackColor: Colors.white24,
                          thumbColor: const Color(0xFF82F5C1),
                        ),
                        child: Slider(
                          value: _currentSeconds.clamp(0.0, _totalDurationSeconds),
                          min: 0.0,
                          max: _totalDurationSeconds,
                          onChanged: (val) {
                            setState(() => _currentSeconds = val);
                            _resetControlsTimer();
                          },
                          onChangeEnd: (val) {
                            widget.onPositionChanged?.call(val.toInt());
                            if (_isPlaying) _startTicker();
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTime(_currentSeconds),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  _formatTime(_totalDurationSeconds),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _selectedQuality,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── أزرار الزجاج الشفاف ──────────────────────────────────────────────────
  Widget _buildGlassIconBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildGlassActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 8, height: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeekRipple({required bool isForward}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF14B8A6), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isForward ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded,
            color: const Color(0xFF14B8A6),
            size: 30,
          ),
          const SizedBox(height: 2),
          Text(
            isForward ? '+10s' : '-10s',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedMenu() {
    return PopupMenuButton<double>(
      tooltip: 'سرعة التشغيل',
      initialValue: _playbackSpeed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Text(
          '${_playbackSpeed}x',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onSelected: (val) {
        setState(() => _playbackSpeed = val);
        if (_isPlaying) _startTicker();
        _resetControlsTimer();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 0.5, child: Text('0.5x - بطيء جداً')),
        const PopupMenuItem(value: 0.75, child: Text('0.75x - هادئ')),
        const PopupMenuItem(value: 1.0, child: Text('1.0x - عادي (افتراضي)')),
        const PopupMenuItem(value: 1.25, child: Text('1.25x - سريع قليلاً')),
        const PopupMenuItem(value: 1.5, child: Text('1.5x - سريع')),
        const PopupMenuItem(value: 2.0, child: Text('2.0x - مضاعف')),
      ],
    );
  }

  Widget _buildQualityMenu() {
    return PopupMenuButton<String>(
      tooltip: 'جودة العرض',
      initialValue: _selectedQuality,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hd_rounded, size: 14, color: Color(0xFF14B8A6)),
            const SizedBox(width: 4),
            Text(
              _selectedQuality.split(' ').first,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      onSelected: (val) {
        setState(() => _selectedQuality = val);
        _resetControlsTimer();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: '1080p FHD', child: Text('1080p FHD (أعلى وضوح)')),
        const PopupMenuItem(value: '720p HD', child: Text('720p HD (عالية الدقة)')),
        const PopupMenuItem(value: '480p SD', child: Text('480p SD (توفير البيانات)')),
        const PopupMenuItem(value: '360p Low', child: Text('360p (شبكة ضعيفة)')),
        const PopupMenuItem(value: 'تلقائي', child: Text('تلقائي (حسب سرعة النت)')),
      ],
    );
  }

  Widget _buildFallbackGraphic() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.play_circle_outline_rounded,
          size: 64,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
