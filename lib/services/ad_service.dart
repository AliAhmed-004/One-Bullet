import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service for managing Google AdMob ads.
///
/// Shows interstitial ads after:
/// - Every 3 deaths, OR
/// - A good gameplay (surviving 1 minute 30 seconds)
///
/// Also provides rewarded ads for the "Continue" feature.
class AdService {
  // ===== Interstitial Ads =====
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialLoaded = false;

  // ===== Rewarded Ads =====
  static RewardedAd? _rewardedAd;
  static bool _isRewardedLoaded = false;

  /// Tracks if the user earned the reward in the current ad session.
  static bool _pendingReward = false;

  /// Stored callbacks for the current rewarded ad session.
  static VoidCallback? _onRewardEarnedCallback;
  static VoidCallback? _onAdDismissedWithoutRewardCallback;

  /// Number of deaths since last ad was shown.
  static int _deathCount = 0;

  /// Deaths required before showing an ad.
  static const int _deathsBeforeAd = 3;

  /// Survival time (in seconds) that counts as a "good run" and triggers an ad.
  static const int _goodRunThresholdSeconds = 45; // 1 minute 30 seconds

  /// Whether to force test ads (ignoring release mode). Useful for testing on
  /// release builds or when test ads aren't showing properly.
  static bool get forceTestAds =>
      const bool.fromEnvironment("FORCE_TEST_ADS", defaultValue: false);

  /// Test Ad Unit IDs (use these during development).
  static String get _interstitialAdUnitId {
    if (Platform.isAndroid) {
      if (forceTestAds) {
        // Android test interstitial ad unit ID
        return 'ca-app-pub-3940256099942544/1033173712';
      }

      return kDebugMode
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-4588211425588192/7743120305';
    } else if (Platform.isIOS) {
      // iOS test interstitial ad unit ID
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    throw UnsupportedError('Unsupported platform for ads');
  }

  /// Rewarded Ad Unit IDs (test IDs during development).
  static String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      // Force test ads if the flag is set, regardless of build mode
      if (forceTestAds) {
        // Android test rewarded ad unit ID
        return 'ca-app-pub-3940256099942544/5224354917';
      }

      return kDebugMode
          ? 'ca-app-pub-3940256099942544/5224354917' // Test ID for debug builds
          : 'ca-app-pub-4588211425588192/6790691784'; // Real ID for release builds
    } else if (Platform.isIOS) {
      // iOS test rewarded ad unit ID
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    throw UnsupportedError('Unsupported platform for ads');
  }

  /// Initializes the Mobile Ads SDK.
  static Future<void> init() async {
    // Dispose any existing ads first (important for hot restart)
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialLoaded = false;

    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedLoaded = false;

    // Reset state
    _pendingReward = false;
    _onRewardEarnedCallback = null;
    _onAdDismissedWithoutRewardCallback = null;
    _deathCount = 0;

    if (Platform.isAndroid || Platform.isIOS) {
      await MobileAds.instance.initialize();
      log('AdService: Mobile Ads SDK initialized');
    } else {
      log('AdService: Mobile Ads SDK not initialized - unsupported platform');
    }

    // Start loading ads immediately
    _loadInterstitialAd();
    _loadRewardedAd();

    log('AdService: Mobile Ads SDK initialized');
  }

  // Configures ad request settings (e.g., content rating, child-directed treatment).
  static void setupAds() {
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        maxAdContentRating: MaxAdContentRating.t,

        // NOT a kids app
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,

        // Optional: keep yes for GDPR safety
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.yes,
      ),
    );
  }

  /// Loads an interstitial ad.
  static void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoaded = true;

          // Set up callbacks for when ad is closed
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  _isInterstitialLoaded = false;
                  // Preload the next ad
                  _loadInterstitialAd();
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  if (kDebugMode) {
                    print('AdService: Failed to show ad: $error');
                  }
                  ad.dispose();
                  _isInterstitialLoaded = false;
                  _loadInterstitialAd();
                },
              );

          if (kDebugMode) {
            print('AdService: Interstitial ad loaded');
          }
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            print('AdService: Failed to load interstitial: $error');
          }
          _isInterstitialLoaded = false;

          // Retry loading after a delay
          Future.delayed(const Duration(seconds: 30), _loadInterstitialAd);
        },
      ),
    );
  }

  /// Loads a rewarded ad.
  static void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoaded = true;

          if (kDebugMode) {
            print('AdService: Rewarded ad loaded');
          }
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            print('AdService: Failed to load rewarded ad: $error');
          }
          _isRewardedLoaded = false;

          // Retry loading after a delay
          Future.delayed(const Duration(seconds: 30), _loadRewardedAd);
        },
      ),
    );
  }

  /// Returns true if a rewarded ad is ready to be shown.
  static bool get isRewardedAdReady => _isRewardedLoaded && _rewardedAd != null;

  /// Shows a rewarded ad for the "Continue" feature.
  ///
  /// [onRewardEarned] is called AFTER the ad is closed AND the user earned the reward.
  /// [onAdDismissedWithoutReward] is called if the ad closes without the user earning the reward.
  static void showRewardedAd({
    required VoidCallback onRewardEarned,
    VoidCallback? onAdDismissedWithoutReward,
  }) {
    if (kDebugMode) {
      print('AdService: showRewardedAd() called');
      print('AdService: isRewardedAdReady=$isRewardedAdReady');
      print('AdService: _rewardedAd=$_rewardedAd');
    }

    if (!isRewardedAdReady) {
      if (kDebugMode) {
        print('AdService: No rewarded ad loaded - calling dismissed callback');
      }
      onAdDismissedWithoutReward?.call();
      return;
    }

    // Reset pending reward flag and store callbacks
    _pendingReward = false;
    _onRewardEarnedCallback = onRewardEarned;
    _onAdDismissedWithoutRewardCallback = onAdDismissedWithoutReward;

    if (kDebugMode) {
      print(
        'AdService: Callbacks stored, setting up fullScreenContentCallback',
      );
    }

    // Set up callbacks
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        if (kDebugMode) {
          print('AdService: onAdShowedFullScreenContent - ad is now visible');
        }
        // Optimistically set pending reward to true when ad starts showing.
        // This handles cases where onUserEarnedReward fires after onAdDismissed
        // or doesn't fire at all with test ads. The reward will be revoked if
        // the user explicitly skips or the ad fails.
        _pendingReward = true;
        if (kDebugMode) {
          print('AdService: _pendingReward set to true (optimistic)');
        }
      },
      onAdDismissedFullScreenContent: (ad) {
        if (kDebugMode) {
          print('AdService: onAdDismissedFullScreenContent called');
          print('AdService: _pendingReward=$_pendingReward');
        }
        ad.dispose();
        _isRewardedLoaded = false;
        // Preload the next rewarded ad
        _loadRewardedAd();

        // Now that ad is fully closed, check if reward was earned
        final earnedCallback = _onRewardEarnedCallback;
        final dismissedCallback = _onAdDismissedWithoutRewardCallback;

        // Clear stored callbacks
        _onRewardEarnedCallback = null;
        _onAdDismissedWithoutRewardCallback = null;

        if (_pendingReward) {
          if (kDebugMode) {
            print('AdService: Reward was earned! Calling earnedCallback');
          }
          _pendingReward = false;
          // Small delay to ensure UI transition is smooth
          Future.delayed(const Duration(milliseconds: 100), () {
            if (kDebugMode) {
              print('AdService: Executing earnedCallback after delay');
            }
            earnedCallback?.call();
          });
        } else {
          if (kDebugMode) {
            print('AdService: No reward earned, calling dismissedCallback');
          }
          dismissedCallback?.call();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (kDebugMode) {
          print('AdService: onAdFailedToShowFullScreenContent: $error');
        }
        ad.dispose();
        _isRewardedLoaded = false;
        _loadRewardedAd();

        final dismissedCallback = _onAdDismissedWithoutRewardCallback;
        _onRewardEarnedCallback = null;
        _onAdDismissedWithoutRewardCallback = null;
        dismissedCallback?.call();
      },
    );

    if (kDebugMode) {
      print('AdService: About to call _rewardedAd!.show()');
    }

    // Show the ad with reward callback
    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        if (kDebugMode) {
          print('========================================');
          print('AdService: onUserEarnedReward CALLED!');
          print('AdService: reward.amount=${reward.amount}');
          print('AdService: reward.type=${reward.type}');
          print('========================================');
        }
        // Confirm that reward was earned. This is redundant with the optimistic
        // approach in onAdShowedFullScreenContent, but kept for correctness
        // when the callback does fire properly.
        _pendingReward = true;
        if (kDebugMode) {
          print('AdService: _pendingReward confirmed as $_pendingReward');
        }
      },
    );

    if (kDebugMode) {
      print('AdService: _rewardedAd!.show() has been called');
    }
  }

  /// Called when the player dies. Returns true if an ad will be shown.
  ///
  /// [survivalTimeSeconds] - How long the player survived in this run.
  static bool onPlayerDeath(int survivalTimeSeconds) {
    _deathCount++;

    final bool hadGoodRun = survivalTimeSeconds >= _goodRunThresholdSeconds;
    final bool reachedDeathThreshold = _deathCount >= _deathsBeforeAd;

    if (hadGoodRun || reachedDeathThreshold) {
      // Reset death count when showing an ad
      _deathCount = 0;
      return _showInterstitialAd();
    }

    return false;
  }

  /// Shows the interstitial ad if one is loaded.
  /// Returns true if an ad was shown.
  static bool _showInterstitialAd() {
    if (_isInterstitialLoaded && _interstitialAd != null) {
      _interstitialAd!.show();
      if (kDebugMode) {
        print('AdService: Showing interstitial ad');
      }
      return true;
    } else {
      if (kDebugMode) {
        print('AdService: No ad loaded to show');
      }
      // Try to load one for next time
      _loadInterstitialAd();
      return false;
    }
  }

  /// Resets the death counter (e.g., when returning to main menu).
  static void resetDeathCount() {
    _deathCount = 0;
  }

  /// Disposes of any loaded ads.
  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialLoaded = false;

    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedLoaded = false;
  }
}
