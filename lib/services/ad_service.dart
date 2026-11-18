import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'subscription_service.dart';
import 'ads/ad_web_view.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isMobileAdsInitialized = false;

  Future<void> initMobileAds() async {
    if (kIsWeb) return;
    if (_isMobileAdsInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isMobileAdsInitialized = true;
    } catch (e) {
      debugPrint('[AdService] MobileAds init failed: $e');
    }
  }
}

/// ودجت موحد لعرض الإعلانات يفرق تلقائياً بين الويب والهاتف ويمنع الإعلانات لمشتركي Pro
class SmartAdBanner extends StatefulWidget {
  final String slotType; // 'header', 'footer', 'in_content'

  const SmartAdBanner({
    super.key,
    this.slotType = 'footer',
  });

  @override
  State<SmartAdBanner> createState() => _SmartAdBannerState();
}

class _SmartAdBannerState extends State<SmartAdBanner> {
  final _service = SubscriptionService();
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      AdService().initMobileAds().then((_) => _loadMobileBanner());
    }
  }

  void _loadMobileBanner() {
    if (kIsWeb) return;
    final auth = context.read<AuthProvider>();
    // منع تحميل الإعلانات نهائياً لمشتركي Pro
    if (auth.isPro) return;

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Ad Unit ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isBannerLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('[AdMob] Failed to load banner: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // 1. حساب Pro لا يرى أي إعلانات نهائياً
    if (auth.isPro) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<Map<String, dynamic>>(
      stream: _service.streamAdSettings(),
      builder: (context, snapshot) {
        final settings = snapshot.data ?? {};

        // 2. فحص إعدادات المنصة المحددة
        if (kIsWeb) {
          final webEnabled = settings['webAdsEnabled'] != false;
          if (!webEnabled) return const SizedBox.shrink();

          final pubId = settings['adSensePublisherId']?.toString() ?? 'ca-pub-7381352612061383';
          final slotId = settings['adSenseSlotId']?.toString() ?? '2865554530';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: buildAdSensePlatformView(
              publisherId: pubId.startsWith('ca-') ? pubId : 'ca-$pubId',
              slotId: slotId,
              width: double.infinity,
              height: 90,
            ),
          );
        } else {
          final mobileEnabled = settings['mobileAdsEnabled'] != false;
          if (!mobileEnabled) return const SizedBox.shrink();
          if (!_isBannerLoaded || _bannerAd == null) {
            return const SizedBox.shrink();
          }
          return Container(
            alignment: Alignment.center,
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          );
        }
      },
    );
  }

  Widget _buildWebAdSensePlaceholder() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ads_click_rounded,
                size: 16, color: isDark ? Colors.white38 : Colors.grey),
            const SizedBox(width: 8),
            Text(
              'مساحة إعلانية مدعومة من Google AdSense',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
