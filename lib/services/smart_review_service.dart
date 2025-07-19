import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/v2/training_pack_spot.dart';
import 'template_storage_service.dart';
import 'training_pack_template_builder.dart';
import 'training_session_service.dart';
import 'tag_mastery_service.dart';
import '../screens/training_session_screen.dart';

/// Stores IDs of spots where the user made a mistake for future review.
class SmartReviewService {
  SmartReviewService._();

  /// Singleton instance.
  static final SmartReviewService instance = SmartReviewService._();

  static const _prefsKey = 'smart_review_spots';

  final Set<String> _ids = <String>{};

  /// Loads stored mistake spot IDs from [SharedPreferences].
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _ids
      ..clear()
      ..addAll(prefs.getStringList(_prefsKey) ?? <String>[]);
  }

  /// Records a mistake for the given [spot].
  ///
  /// Only the spot ID is persisted to avoid storing duplicate data.
  Future<void> recordMistake(TrainingPackSpot spot) async {
    if (_ids.contains(spot.id)) return;
    _ids.add(spot.id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _ids.toList());
  }

  /// Returns the list of spots corresponding to recorded mistakes.
  Future<List<TrainingPackSpot>> getMistakeSpots(
    TemplateStorageService templates, {
    BuildContext? context,
  }) async {
    if (_ids.isEmpty) return <TrainingPackSpot>[];
    final Map<String, TrainingPackSpot> map = {};
    for (final tpl in templates.templates) {
      for (final s in tpl.spots) {
        if (_ids.contains(s.id) && !map.containsKey(s.id)) {
          map[s.id] = TrainingPackSpot.fromJson(s.toJson());
        }
      }
    }
    final result = <TrainingPackSpot>[];
    for (final id in _ids) {
      final spot = map[id];
      if (spot != null) result.add(spot);
    }

    if (context != null && result.length > 5) {
      final builder = const TrainingPackTemplateBuilder();
      final mastery = context.read<TagMasteryService>();
      final tpl = await builder.buildSimplifiedPack(result, mastery);
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Мы подобрали для вас упрощённую тренировку'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      await context
          .read<TrainingSessionService>()
          .startSession(tpl, persist: false);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
      );
      await clearMistakes();
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('🎯 Отлично! Ошибки проработаны'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return [];
    }

    return result;
  }

  /// Clears all stored mistakes.
  Future<void> clearMistakes() async {
    _ids.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// Returns true if there are recorded mistakes.
  bool hasMistakes() => _ids.isNotEmpty;

  /// Returns true if a mistake for [spotId] is recorded.
  bool hasMistake(String spotId) => _ids.contains(spotId);
}
