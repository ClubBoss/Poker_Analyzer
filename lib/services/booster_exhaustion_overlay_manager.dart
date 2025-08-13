import 'dart:async';
import 'package:flutter/material.dart';

import '../main.dart';
import 'theory_injection_horizon_service.dart';

/// Warns user about booster fatigue if too many are launched in a short time.
class BoosterExhaustionOverlayManager {
  final int maxCount;
  final Duration window;
  final Duration suppression;

  BoosterExhaustionOverlayManager({
    this.maxCount = 4,
    this.window = const Duration(hours: 2),
    this.suppression = const Duration(hours: 1),
  });

  static final BoosterExhaustionOverlayManager instance =
      BoosterExhaustionOverlayManager();

  final List<DateTime> _history = [];
  DateTime? _suppressedUntil;
  StreamSubscription<String>? _sub;
  bool _dialogOpen = false;

  Future<void> start() async {
    _sub = TheoryInjectionHorizonService.instance.injections.listen(_onInject);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
  }

  void _onInject(String type) {
    final now = DateTime.now();
    _history.add(now);
    _history.removeWhere((t) => now.difference(t) > window);
    if (_shouldWarn()) {
      _show();
    }
  }

  bool _shouldWarn() {
    if (_dialogOpen) return false;
    if (_suppressedUntil != null &&
        DateTime.now().isBefore(_suppressedUntil!)) {
      return false;
    }
    return _history.length >= maxCount;
  }

  Future<void> _show() async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    _dialogOpen = true;
    await showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('\uD83D\uDCDA Хороший прогресс!'),
        content: const Text('Сделай перерыв, чтобы закрепить материал.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _suppressedUntil = DateTime.now().add(suppression);
              _history.clear();
            },
            child: const Text('Напомнить позже'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Ок'),
          ),
        ],
      ),
    );
    _dialogOpen = false;
    _history.clear();
  }
}
