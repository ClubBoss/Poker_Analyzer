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
  static const _resultsKey = 'smart_review_results';

  final Set<String> _ids = <String>{};
  final List<List<double>> _results = [];

  List<double>? _parseResult(String s) {
    final parts = s.split(',');
    if (parts.length != 3) return null;
    final a = double.tryParse(parts[0]);
    final e = double.tryParse(parts[1]);
    final i = double.tryParse(parts[2]);
    if (a == null || e == null || i == null) return null;
    return [a, e, i];
  }

  /// Loads stored mistake spot IDs from [SharedPreferences].
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _ids
      ..clear()
      ..addAll(prefs.getStringList(_prefsKey) ?? <String>[]);
    _results
      ..clear()
      ..addAll([for (final r in prefs.getStringList(_resultsKey) ?? <String>[]) _parseResult(r)]
          .whereType<List<double>>());
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

  Future<void> registerCompletion(
    double accuracy,
    double evPct,
    double icmPct, {
    BuildContext? context,
  }) async {
    _results.add([accuracy, evPct, icmPct]);
    while (_results.length > 3) {
      _results.removeAt(0);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _resultsKey,
        [for (final r in _results) '${r[0]},${r[1]},${r[2]}']);

    final ready = _results.length >= 3 &&
        _results.every((r) => r[0] >= 0.9 && r[1] >= 0.85 && r[2] >= 0.85);
    if (ready && context != null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Хотите попробовать более сложный уровень?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Нет')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Да')),
          ],
        ),
      );
      if (confirm == true) {
        final builder = const TrainingPackTemplateBuilder();
        final mastery = context.read<TagMasteryService>();
        final tpl = await builder.buildAdvancedPack(mastery);
        await context
            .read<TrainingSessionService>()
            .startSession(tpl, persist: false);
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
        );
      }
      _results.clear();
      await prefs.remove(_resultsKey);
      return;
    }

    final weakReady = _results.length >= 3 &&
        _results.every((r) => r[0] <= 0.7 || r[1] < 0.6 || r[2] < 0.6);
    if (weakReady && context != null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Хотите поработать над уязвимыми зонами?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Нет')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Да')),
          ],
        ),
      );
      if (confirm == true) {
        final builder = const TrainingPackTemplateBuilder();
        final mastery = context.read<TagMasteryService>();
        final tpl = await builder.buildWeaknessPack(mastery);
        await context
            .read<TrainingSessionService>()
            .startSession(tpl, persist: false);
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
        );
      }
      _results.clear();
      await prefs.remove(_resultsKey);
    }
  }
}
