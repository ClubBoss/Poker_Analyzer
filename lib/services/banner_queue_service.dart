import 'package:flutter/material.dart';

import '../main.dart';

/// Queues [MaterialBanner] widgets to show one at a time.
class BannerQueueService {
  BannerQueueService._();
  static final BannerQueueService instance = BannerQueueService._();

  final List<MaterialBanner> _queue = [];
  bool _isShowing = false;

  /// Adds [banner] to the queue and displays it when possible.
  void queue(MaterialBanner banner) {
    _queue.add(banner);
    _processQueue();
  }

  /// Dismisses the current banner and shows the next one if available.
  void dismissCurrent() {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).clearMaterialBanners();
    }
    _isShowing = false;
    _processQueue();
  }

  void _processQueue() {
    if (_isShowing || _queue.isEmpty) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    final messenger = ScaffoldMessenger.of(ctx);
    final banner = _queue.removeAt(0);
    _isShowing = true;
    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(banner);
    Future.delayed(const Duration(seconds: 3), dismissCurrent);
  }
}
