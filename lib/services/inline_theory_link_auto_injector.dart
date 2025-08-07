import '../models/inline_theory_entry.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/training_pack_model.dart';
import '../models/autogen_status.dart';
import 'autogen_status_dashboard_service.dart';

/// Injects references to [InlineTheoryEntry] into [TrainingPackSpot]s based on
/// matching tags.
class InlineTheoryLinkAutoInjector {
  const InlineTheoryLinkAutoInjector();

  /// Attaches theory links to all spots within [model] using [theoryIndex].
  ///
  /// Returns the mutated [model] for convenience and logs the number of
  /// injected links.
  TrainingPackModel injectLinks(
    TrainingPackModel model,
    Map<String, InlineTheoryEntry> theoryIndex,
  ) {
    final status = AutogenStatusDashboardService.instance;
    status.update(
      'InlineTheoryLinkAutoInjector',
      const AutogenStatus(
        isRunning: true,
        currentStage: 'inject',
        progress: 0,
      ),
    );
    try {
      final count = _injectAll(model.spots, theoryIndex, status);
      if (count > 0) {
        print('InlineTheoryLinkAutoInjector: injected $count links');
      }
      status.update(
        'InlineTheoryLinkAutoInjector',
        const AutogenStatus(
          isRunning: false,
          currentStage: 'complete',
          progress: 1,
        ),
      );
      return model;
    } catch (e) {
      status.update(
        'InlineTheoryLinkAutoInjector',
        AutogenStatus(
          isRunning: false,
          currentStage: 'error',
          progress: 0,
          lastError: e.toString(),
        ),
      );
      rethrow;
    }
  }

  /// Convenience method to inject links into a list of [spots].
  void injectAll(
    List<TrainingPackSpot> spots,
    Map<String, InlineTheoryEntry> theoryIndex,
  ) {
    final status = AutogenStatusDashboardService.instance;
    status.update(
      'InlineTheoryLinkAutoInjector',
      const AutogenStatus(
        isRunning: true,
        currentStage: 'inject',
        progress: 0,
      ),
    );
    try {
      final count = _injectAll(spots, theoryIndex, status);
      if (count > 0) {
        print('InlineTheoryLinkAutoInjector: injected $count links');
      }
      status.update(
        'InlineTheoryLinkAutoInjector',
        const AutogenStatus(
          isRunning: false,
          currentStage: 'complete',
          progress: 1,
        ),
      );
    } catch (e) {
      status.update(
        'InlineTheoryLinkAutoInjector',
        AutogenStatus(
          isRunning: false,
          currentStage: 'error',
          progress: 0,
          lastError: e.toString(),
        ),
      );
      rethrow;
    }
  }

  int _injectAll(
    List<TrainingPackSpot> spots,
    Map<String, InlineTheoryEntry> theoryIndex,
    AutogenStatusDashboardService status,
  ) {
    final used = <String>{};
    var injected = 0;
    for (var i = 0; i < spots.length; i++) {
      final spot = spots[i];
      if (spot.inlineTheory != null) {
        final id = spot.inlineTheory!.id ?? spot.inlineTheory!.tag;
        used.add(id);
        continue;
      }
      for (final t in spot.tags) {
        final entry = _findEntry(t, theoryIndex);
        if (entry == null) continue;
        final id = entry.id ?? entry.tag;
        if (used.contains(id)) continue;
        spot.inlineTheory = entry;
        spot.meta['theory'] = {
          'tag': entry.tag,
          'id': id,
          if (entry.title != null) 'title': entry.title,
        };
        used.add(id);
        injected++;
        break;
      }
      status.update(
        'InlineTheoryLinkAutoInjector',
        AutogenStatus(
          isRunning: true,
          currentStage: 'inject',
          progress: (i + 1) / spots.length,
        ),
      );
    }
    return injected;
  }

  InlineTheoryEntry? _findEntry(
    String tag,
    Map<String, InlineTheoryEntry> index,
  ) {
    // Exact match first
    if (index.containsKey(tag)) return index[tag];

    final tagLower = tag.toLowerCase();
    for (final e in index.entries) {
      final keyLower = e.key.toLowerCase();
      if (tagLower == keyLower) return e.value;
    }

    // Fuzzy match: check if one tag contains the other.
    for (final e in index.entries) {
      final keyLower = e.key.toLowerCase();
      if (tagLower.contains(keyLower) || keyLower.contains(tagLower)) {
        return e.value;
      }
    }
    return null;
  }
}
