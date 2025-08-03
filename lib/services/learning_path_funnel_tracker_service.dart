import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';


import 'analytics_service.dart';

class LearningPathFunnelTrackerService {
  LearningPathFunnelTrackerService._();

  static final instance = LearningPathFunnelTrackerService._();

  Future<void> logLockedView(
    String packId, {
    double? accuracy,
    int? handsCompleted,
    double? requiredAccuracy,
    int? minHands,
  }) async {
    final prefs = await PreferencesService.getInstance();
    final key = 'locked_pack_viewed_' + packId;
    if (prefs.getBool(key) == true) return;
    await prefs.setBool(key, true);
    unawaited(
      AnalyticsService.instance.logEvent('locked_pack_view', {
        'pack_id': packId,
        'accuracy': accuracy,
        'hands_completed': handsCompleted,
        'required_accuracy': requiredAccuracy,
        'min_hands': minHands,
      }),
    );
  }

  Future<void> logCtaTap(
    String packId, {
    String? ctaType,
    double? accuracy,
    int? handsCompleted,
    double? requiredAccuracy,
    int? minHands,
  }) async {
    final prefs = await PreferencesService.getInstance();
    final key = 'cta_tapped_' + packId;
    if (prefs.getBool(key) == true) return;
    await prefs.setBool(key, true);
    unawaited(
      AnalyticsService.instance.logEvent('locked_pack_cta_tap', {
        'pack_id': packId,
        'cta_type': ctaType,
        'accuracy': accuracy,
        'hands_completed': handsCompleted,
        'required_accuracy': requiredAccuracy,
        'min_hands': minHands,
      }),
    );
  }

  Future<void> logUnlock(
    String packId, {
    double? accuracy,
    int? handsCompleted,
    double? requiredAccuracy,
    int? minHands,
  }) async {
    final prefs = await PreferencesService.getInstance();
    final key = 'unlock_logged_' + packId;
    if (prefs.getBool(key) == true) return;
    await prefs.setBool(key, true);
    unawaited(
      AnalyticsService.instance.logEvent('locked_pack_unlocked', {
        'pack_id': packId,
        'accuracy': accuracy,
        'hands_completed': handsCompleted,
        'required_accuracy': requiredAccuracy,
        'min_hands': minHands,
      }),
    );
    final ctaKey = 'cta_tapped_' + packId;
    if (prefs.getBool(ctaKey) == true) {
      await logFunnelComplete(
        packId,
        accuracy: accuracy,
        handsCompleted: handsCompleted,
        requiredAccuracy: requiredAccuracy,
        minHands: minHands,
      );
      await prefs.remove(ctaKey);
    }
  }

  Future<void> logFunnelComplete(
    String packId, {
    double? accuracy,
    int? handsCompleted,
    double? requiredAccuracy,
    int? minHands,
  }) async {
    final prefs = await PreferencesService.getInstance();
    final key = 'unlock_funnel_complete_' + packId;
    if (prefs.getBool(key) == true) return;
    await prefs.setBool(key, true);
    unawaited(
      AnalyticsService.instance.logEvent('unlock_funnel_complete', {
        'pack_id': packId,
        'accuracy': accuracy,
        'hands_completed': handsCompleted,
        'required_accuracy': requiredAccuracy,
        'min_hands': minHands,
      }),
    );
  }
}

