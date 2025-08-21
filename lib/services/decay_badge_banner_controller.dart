import 'package:flutter/material.dart';

import '../main.dart';
import 'decay_streak_badge_notifier.dart';
import '../widgets/decay_badge_banner.dart';

/// Shows a temporary banner when a new decay streak milestone is reached.
class DecayBadgeBannerController with WidgetsBindingObserver {
  final DecayStreakBadgeNotifier notifier;

  DecayBadgeBannerController({DecayStreakBadgeNotifier? notifier})
    : notifier = notifier ?? DecayStreakBadgeNotifier();

  bool _shown = false;

  /// Begin listening for app resume events.
  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    final ctx = navigatorKey.currentContext;
    if (ctx != null) await maybeShowStreakBadgeBanner(ctx);
  }

  /// Stop listening for lifecycle events.
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        // ignore: discarded_futures
        maybeShowStreakBadgeBanner(ctx);
      }
    }
  }

  /// Checks for a badge and displays a banner if earned.
  Future<void> maybeShowStreakBadgeBanner(BuildContext context) async {
    if (_shown) return;
    final badge = await notifier.checkForBadge();
    if (badge == null) return;
    _shown = true;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(
      DecayBadgeBanner(
        milestone: badge.milestone,
        onClose: messenger.hideCurrentMaterialBanner,
      ),
    );
    Future.delayed(const Duration(seconds: 4), () {
      messenger.hideCurrentMaterialBanner();
    });
  }

  /// Resets session state for testing.
  @visibleForTesting
  void resetForTest() => _shown = false;
}
