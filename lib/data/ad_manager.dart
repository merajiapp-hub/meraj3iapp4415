import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// مدير الإعلانات الموحد لتطبيق مراجعي
/// يتعامل مع إعلانات البانر، الإعلانات البينية، وإعلانات المكافأة
class AdManager {
  // ── معرفات AdMob الحقيقية الخاصة بالتطبيق ─────────────────────────────────
  static const String appId = 'ca-app-pub-7381352612061383~4066069173';
  static const String realBannerAdUnitId =
      'ca-app-pub-7381352612061383/9877064981';
  static const String realInterstitialAdUnitId =
      'ca-app-pub-7381352612061383/2609517278';
  static const String realRewardedAdUnitId =
      'ca-app-pub-7381352612061383/4616019507';

  // ── معرفات الاختبار الرسمية من Google (للاختبار والتطوير لتفادي الحظر أو عدم التوفر) ──
  static const String testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // ── كائنات الإعلانات المحملة ───────────────────────────────────────────────
  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;

  static bool _isInterstitialLoading = false;
  static bool _isRewardedLoading = false;
  static int _interstitialRetryAttempts = 0;
  static int _rewardedRetryAttempts = 0;
  static const int _maxRetryAttempts = 4;

  static bool get isInterstitialReady => _interstitialAd != null;
  static bool get isRewardedReady => _rewardedAd != null;

  /// تهيئة وتلقيم الإعلانات الأولية عند بدء التطبيق
  static void init() {
    if (kIsWeb) return;
    loadInterstitialAd();
    loadRewardedAd();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  الإعلان البيني (Interstitial Ad)
  // ══════════════════════════════════════════════════════════════════════════

  static void loadInterstitialAd({bool useFallback = false}) {
    if (kIsWeb || _isInterstitialLoading || _interstitialAd != null) return;

    _isInterstitialLoading = true;
    final adUnitId = (kDebugMode && useFallback)
        ? testInterstitialAdUnitId
        : realInterstitialAdUnitId;

    debugPrint('Loading InterstitialAd with ID: $adUnitId');

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('InterstitialAd loaded successfully.');
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialRetryAttempts = 0;
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _interstitialAd = null;
          _isInterstitialLoading = false;

          // في بيئة التطوير (debug): إذا فشل الإعلان الحقيقي بسبب عدم التوفر (No Fill - كود 3)، يتم الرجوع للمعرف التجريبي
          if (kDebugMode && !useFallback && error.code == 3) {
            debugPrint('Switching to test InterstitialAd ID for debug mode.');
            loadInterstitialAd(useFallback: true);
            return;
          }

          // إعادة المحاولة بوقت تصاعدي (Exponential Backoff)
          if (_interstitialRetryAttempts < _maxRetryAttempts) {
            _interstitialRetryAttempts++;
            final delay = Duration(
              seconds: pow(2, _interstitialRetryAttempts).toInt(),
            );
            debugPrint(
              'Will retry loading InterstitialAd in ${delay.inSeconds}s (attempt $_interstitialRetryAttempts)',
            );
            Future.delayed(
              delay,
              () => loadInterstitialAd(useFallback: useFallback),
            );
          }
        },
      ),
    );
  }

  /// عرض الإعلان البيني مع إمكانية تحديد نسبة الظهور (مثلاً 0.5 تعني 50%)
  static void showInterstitialAd({
    double chance = 0.6,
    VoidCallback? onDismissed,
  }) {
    if (kIsWeb) {
      onDismissed?.call();
      return;
    }

    if (_interstitialAd == null) {
      debugPrint('InterstitialAd not ready yet. Triggering reload.');
      loadInterstitialAd();
      onDismissed?.call();
      return;
    }

    final random = Random().nextDouble();
    if (random <= chance) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('InterstitialAd showed full screen.');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('InterstitialAd dismissed.');
          ad.dispose();
          _interstitialAd = null;
          onDismissed?.call();
          // تحميل إعلان جديد فوراً ليكون جاهزاً للمرة القادمة
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('InterstitialAd failed to show: $error');
          ad.dispose();
          _interstitialAd = null;
          onDismissed?.call();
          loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
    } else {
      onDismissed?.call();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  إعلان المكافأة (Rewarded Ad)
  // ══════════════════════════════════════════════════════════════════════════

  static void loadRewardedAd({bool useFallback = false}) {
    if (kIsWeb || _isRewardedLoading || _rewardedAd != null) return;

    _isRewardedLoading = true;
    final adUnitId = (kDebugMode && useFallback)
        ? testRewardedAdUnitId
        : realRewardedAdUnitId;

    debugPrint('Loading RewardedAd with ID: $adUnitId');

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('RewardedAd loaded successfully.');
          _rewardedAd = ad;
          _isRewardedLoading = false;
          _rewardedRetryAttempts = 0;
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          _rewardedAd = null;
          _isRewardedLoading = false;

          if (kDebugMode && !useFallback && error.code == 3) {
            debugPrint('Switching to test RewardedAd ID for debug mode.');
            loadRewardedAd(useFallback: true);
            return;
          }

          if (_rewardedRetryAttempts < _maxRetryAttempts) {
            _rewardedRetryAttempts++;
            final delay = Duration(
              seconds: pow(2, _rewardedRetryAttempts).toInt(),
            );
            debugPrint(
              'Will retry loading RewardedAd in ${delay.inSeconds}s (attempt $_rewardedRetryAttempts)',
            );
            Future.delayed(
              delay,
              () => loadRewardedAd(useFallback: useFallback),
            );
          }
        },
      ),
    );
  }

  /// عرض إعلان المكافأة مع تنفيذ دالة المكافأة عند اكتماله
  static void showRewardedAd({
    required VoidCallback onRewarded,
    VoidCallback? onNotReady,
    VoidCallback? onDismissed,
  }) {
    if (kIsWeb) {
      onRewarded();
      return;
    }

    if (_rewardedAd == null) {
      debugPrint('RewardedAd not loaded yet.');
      loadRewardedAd();
      onNotReady?.call();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('RewardedAd showed full screen.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('RewardedAd dismissed.');
        ad.dispose();
        _rewardedAd = null;
        onDismissed?.call();
        // تحميل إعلان جديد للمرة القادمة
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('RewardedAd failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        onDismissed?.call();
        loadRewardedAd();
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        onRewarded();
      },
    );
  }
}
