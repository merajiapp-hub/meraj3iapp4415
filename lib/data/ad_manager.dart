import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  // ── معرفات الاختبار الرسمية من Google (تُستخدم كبديل فوري في حال لم تتفعل الوحدات بعد) ──
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

  static final List<Function(RewardedAd?)> _rewardedWaiters = [];

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
    final adUnitId = useFallback ? testInterstitialAdUnitId : realInterstitialAdUnitId;

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

          // إذا فشلت الوحدة الحقيقية بسبب عدم توفر الإعلانات (كود 3 No-Fill) أو قيد التفعيل، نستخدم وحدة الاختبار فوراً
          if (!useFallback && (error.code == 3 || error.code == 0)) {
            debugPrint('Switching to test InterstitialAd ID to guarantee ad display.');
            loadInterstitialAd(useFallback: true);
            return;
          }

          // إعادة المحاولة بوقت تصاعدي
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

  /// عرض الإعلان البيني مع إمكانية تحديد نسبة الظهور
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
    final adUnitId = useFallback ? testRewardedAdUnitId : realRewardedAdUnitId;

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

          // إخطار كل المنتظرين بتحميل الإعلان
          final waiters = List<Function(RewardedAd?)>.from(_rewardedWaiters);
          _rewardedWaiters.clear();
          for (final waiter in waiters) {
            waiter(ad);
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          _rewardedAd = null;
          _isRewardedLoading = false;

          // إذا فشلت الوحدة الحقيقية (كود 3 No-Fill)، نستخدم فوراً وحدة الاختبار المضمونة
          if (!useFallback && (error.code == 3 || error.code == 0)) {
            debugPrint('Switching to test RewardedAd ID to guarantee ad display.');
            loadRewardedAd(useFallback: true);
            return;
          }

          // إخطار المنتظرين بالفشل فوراً حتى لا يبقى مؤشر التحميل معلقاً
          if (_rewardedWaiters.isNotEmpty) {
            final waiters = List<Function(RewardedAd?)>.from(_rewardedWaiters);
            _rewardedWaiters.clear();
            for (final waiter in waiters) {
              waiter(null);
            }
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

  /// عرض إعلان المكافأة مع التحقق من انتهاء المشاهدة الفعلية
  static void showRewardedAd({
    required VoidCallback onRewarded,
    VoidCallback? onNotReady,
    VoidCallback? onDismissed,
  }) {
    if (kIsWeb) {
      onNotReady?.call();
      return;
    }

    if (_rewardedAd == null) {
      debugPrint('RewardedAd not loaded yet.');
      loadRewardedAd();
      onNotReady?.call();
      return;
    }

    bool userEarnedReward = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('RewardedAd showed full screen.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('RewardedAd dismissed.');
        ad.dispose();
        _rewardedAd = null;
        if (userEarnedReward) {
          onRewarded();
        }
        onDismissed?.call();
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
        userEarnedReward = true;
      },
    );
  }

  /// عرض إعلان المكافأة مع مؤشر تحميل ذكي يبحث عن الإعلان ويفتحه
  static Future<void> showRewardedAdWithLoader(
    BuildContext context, {
    required VoidCallback onRewarded,
    VoidCallback? onDismissed,
  }) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('مشاهدة الإعلانات لكسب النقاط متاحة حصرياً عبر تطبيق الهاتف.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // إذا كان الإعلان جاهزاً بالفعل، نعرضه فوراً
    if (_rewardedAd != null) {
      showRewardedAd(
        onRewarded: onRewarded,
        onDismissed: onDismissed,
      );
      return;
    }

    // إذا لم يكن جاهزاً، نظهر مؤشر انتظار ونحاول جلبه فوراً
    bool dialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D7A66)),
              ),
              SizedBox(height: 16),
              Text(
                'جاري البحث عن إعلان وتجهيزه...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => dialogOpen = false);

    Timer? timeoutTimer;
    void closeDialog() {
      timeoutTimer?.cancel();
      if (dialogOpen && Navigator.canPop(context)) {
        Navigator.pop(context);
        dialogOpen = false;
      }
    }

    timeoutTimer = Timer(const Duration(seconds: 8), () {
      closeDialog();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر العثور على إعلان حالياً، يرجى المحاولة بعد قليل.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    _rewardedWaiters.add((ad) {
      closeDialog();
      if (ad != null && context.mounted) {
        showRewardedAd(
          onRewarded: onRewarded,
          onDismissed: onDismissed,
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر العثور على إعلان حالياً، يرجى المحاولة لاحقاً.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    loadRewardedAd();
  }
}
