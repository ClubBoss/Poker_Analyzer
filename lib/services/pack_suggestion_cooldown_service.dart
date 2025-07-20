import 'suggestion_cooldown_manager.dart';

@Deprecated('Use SuggestionCooldownManager instead.')
class PackSuggestionCooldownService {
  static bool debugLogging = false;

  static Future<void> markAsSuggested(String packId) async {
    SuggestionCooldownManager.debugLogging = debugLogging;
    await SuggestionCooldownManager.markSuggested(packId);
  }

  static Future<bool> isRecentlySuggested(
    String packId, {
    Duration cooldown = const Duration(days: 7),
  }) async {
    SuggestionCooldownManager.debugLogging = debugLogging;
    return SuggestionCooldownManager.isUnderCooldown(
      packId,
      cooldown: cooldown,
    );
  }
}
