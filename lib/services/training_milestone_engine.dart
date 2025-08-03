import 'package:collection/collection.dart';
import 'package:poker_analyzer/services/preferences_service.dart';

class MilestoneResult {
  final bool triggered;
  final int? milestoneValue;
  final String message;

  const MilestoneResult({
    required this.triggered,
    this.milestoneValue,
    this.message = '',
  });
}

class TrainingMilestoneEngine {
  TrainingMilestoneEngine._();
  static final instance = TrainingMilestoneEngine._();

  static const List<int> milestones = [10, 30, 50, 100, 200];
  static const _prefsKey = 'training_milestones_triggered';

  Set<int>? _triggered;

  Future<Set<int>> _load() async {
    if (_triggered != null) return _triggered!;
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getStringList(_prefsKey);
    _triggered = raw?.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toSet() ?? {};
    return _triggered!;
  }

  Future<void> _save() async {
    if (_triggered == null) return;
    final prefs = await PreferencesService.getInstance();
    await prefs.setStringList(
      _prefsKey,
      _triggered!.map((e) => e.toString()).toList(),
    );
  }

  Future<MilestoneResult> checkAndTrigger({required int completedPacks}) async {
    final triggered = await _load();
    final milestone = milestones.firstWhereOrNull(
      (m) => completedPacks >= m && !triggered.contains(m),
    );
    if (milestone != null) {
      triggered.add(milestone);
      await _save();
      final msg = '🎉 $milestone паков — отличное начало!';
      return MilestoneResult(
        triggered: true,
        milestoneValue: milestone,
        message: msg,
      );
    }
    return const MilestoneResult(triggered: false);
  }
}
