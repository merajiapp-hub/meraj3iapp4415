import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../data/ad_manager.dart';

/// ويدجت إعلان بانر ذكي ومتكيف مع حجم الشاشة
class BannerAdWidget extends StatefulWidget {
  final EdgeInsetsGeometry? margin;

  const BannerAdWidget({
    super.key,
    this.margin,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  int _retryAttempts = 0;
  static const int _maxRetryAttempts = 4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoaded && !_isLoading && _bannerAd == null) {
      _loadAd();
    }
  }

  Future<void> _loadAd({bool useFallback = false}) async {
    if (kIsWeb || !mounted || _isLoading) return;

    _isLoading = true;

    // الحصول على العرض المناسب للشاشة للإعلان المتكيف
    final width = MediaQuery.of(context).size.width.truncate();
    AdSize? size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    size ??= AdSize.banner; // كبديل قياسي 320x50 إذا تعذر تحديد الحجم المتكيف

    final adUnitId = useFallback
        ? AdManager.testBannerAdUnitId
        : AdManager.realBannerAdUnitId;

    debugPrint('Loading BannerAd with ID: $adUnitId');

    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('BannerAd loaded successfully.');
          if (mounted) {
            setState(() {
              _isLoaded = true;
              _isLoading = false;
              _retryAttempts = 0;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
          _bannerAd = null;
          if (!mounted) return;

          setState(() {
            _isLoaded = false;
            _isLoading = false;
          });

          // إذا فشل الإعلان الحقيقي بسبب عدم توفر الإعلانات أو قيد التفعيل (كود 3 No-Fill)، نستخدم المعرف البديل فوراً
          if (!useFallback && (err.code == 3 || err.code == 0)) {
            debugPrint('Switching to test BannerAd ID to guarantee ad display.');
            _loadAd(useFallback: true);
            return;
          }

          // إعادة المحاولة التلقائية بوقت تصاعدي
          if (_retryAttempts < _maxRetryAttempts) {
            _retryAttempts++;
            final delay = Duration(seconds: pow(2, _retryAttempts).toInt());
            debugPrint('Will retry loading BannerAd in ${delay.inSeconds}s (attempt $_retryAttempts)');
            Future.delayed(delay, () {
              if (mounted) _loadAd(useFallback: useFallback);
            });
          }
        },
      ),
    );

    try {
      await _bannerAd!.load();
    } catch (e) {
      debugPrint('Error triggering BannerAd load: $e');
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();

    if (_isLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    return const SizedBox.shrink();
  }
}
