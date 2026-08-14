import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import 'dart:math';

class AdManager {
  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;
  
  static final String interstitialAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-7381352612061383/2609517278'
      : 'ca-app-pub-7381352612061383/2609517278';

  static final String rewardedAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-7381352612061383/4616019507'
      : 'ca-app-pub-7381352612061383/4616019507';

  // تحميل الإعلان البيني
  static void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('InterstitialAd loaded.');
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  // عرض الإعلان البيني باحتمالية معينة لكي لا يكون مملاً (مثلاً 30%)
  static void showInterstitialAd({double chance = 0.3}) {
    if (_interstitialAd == null) return;
    
    final random = Random().nextDouble();
    if (random <= chance) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {},
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd(); // تحميل واحد جديد للمرة القادمة
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
    }
  }

  // تحميل إعلان بمكافأة
  static void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('RewardedAd loaded.');
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  // عرض إعلان المكافأة وتطبيق المكافأة
  static void showRewardedAd(Function onRewarded) {
    if (_rewardedAd == null) {
      debugPrint('Warning: attempt to show rewarded before loaded.');
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {},
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // تحميل واحد جديد
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
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
