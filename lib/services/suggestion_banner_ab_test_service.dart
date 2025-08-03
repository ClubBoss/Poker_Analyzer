import 'dart:math';
import 'package:poker_analyzer/services/preferences_service.dart';

import 'user_action_logger.dart';

/// Possible variants for the suggestion banner A/B test.
enum SuggestionBannerVariant { control, layoutA, layoutB, aggressiveText }

/// Service that assigns the user to a banner variant and exposes it.
class SuggestionBannerABTestService {
  SuggestionBannerABTestService._();

  /// Singleton instance.
  static final SuggestionBannerABTestService instance =
      SuggestionBannerABTestService._();

  static const _prefsKey = 'suggestion_banner_variant';
  final Random _rand = Random();

  SuggestionBannerVariant? _variant;
  bool _initialized = false;

  /// Initialize the service. Must be called once on startup.
  Future<void> init() async {
    if (_initialized) return;
    final prefs = await PreferencesService.getInstance();

    // QA override via query parameter (?variant=layoutB)
    final override = Uri.base.queryParameters['variant'];
    if (override != null) {
      _variant = _parseVariant(override);
    }

    final stored = prefs.getString(_prefsKey);
    if (_variant == null && stored != null) {
      _variant = _parseVariant(stored);
    }

    _variant ??= SuggestionBannerVariant
        .values[_rand.nextInt(SuggestionBannerVariant.values.length)];

    await prefs.setString(_prefsKey, _variant!.name);
    _initialized = true;

    await UserActionLogger.instance.logEvent({
      'event': 'ab_test.variant_suggestion_banner',
      'variant': _variant!.name,
    });
  }

  /// Returns the assigned variant. [init] must be called first.
  SuggestionBannerVariant getVariant() {
    if (!_initialized || _variant == null) {
      throw StateError('SuggestionBannerABTestService not initialized');
    }
    return _variant!;
  }

  SuggestionBannerVariant _parseVariant(String value) {
    try {
      return SuggestionBannerVariant.values.byName(value);
    } catch (_) {
      return SuggestionBannerVariant.control;
    }
  }
}
