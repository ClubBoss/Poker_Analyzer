// ASCII-only; pure Dart (no Flutter deps)

import 'package:poker_analyzer/live/live_mode.dart';
import 'live_ui_maps.dart';
import 'live_module_utils.dart';

/// Returns badges for a given module in the context of the provided [mode].
///
/// Rules:
/// - If [mode] is [TrainingMode.live] and `moduleId` starts with "live_",
///   "cash_" or "mtt_", include a single "Live" badge.
/// - Otherwise return an empty list.
///
/// The returned list contains at most a single "Live" entry (no duplicates).
List<String> liveBadgesForModule({
  required String moduleId,
  required TrainingMode mode,
}) {
  final bool isLiveMode = mode == TrainingMode.live;
  if (!isLiveMode) return const <String>[];

  final bool eligible =
      isLiveModuleId(moduleId) || isPracticeModuleId(moduleId);
  return eligible ? const <String>[kLiveBadgeText] : const <String>[];
}
