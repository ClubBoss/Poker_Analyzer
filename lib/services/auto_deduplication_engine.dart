import 'dart:io';
import '../models/training_pack_model.dart';
import '../models/v2/training_pack_spot.dart';
import 'pack_fingerprint_comparer_service.dart';
import 'training_pack_library_service.dart';
import 'spot_fingerprint_generator.dart';
import '../utils/app_logger.dart';
import 'autogen_pipeline_debug_stats_service.dart';
import 'autogen_pipeline_event_logger_service.dart';

class AutoDeduplicationReport {
  final List<PackSimilarityResult> duplicates;
  final Map<String, List<String>> mergeSuggestions;

  const AutoDeduplicationReport({
    required this.duplicates,
    required this.mergeSuggestions,
  });
}

/// Keeps track of spot fingerprints to automatically skip duplicates.
class AutoDeduplicationEngine {
  final SpotFingerprintGenerator _fingerprint;
  final Set<String> _seen = <String>{};
  final IOSink _log;
  int _skipped = 0;
  final TrainingPackLibraryService _library;
  final PackFingerprintComparerService _comparer;

  AutoDeduplicationEngine({
    SpotFingerprintGenerator? fingerprint,
    IOSink? log,
    TrainingPackLibraryService? library,
    PackFingerprintComparerService? comparer,
  }) : _fingerprint = fingerprint ?? const SpotFingerprintGenerator(),
       _log =
           log ??
           File('skipped_duplicates.log').openWrite(mode: FileMode.append),
       _library = library ?? TrainingPackLibraryService(),
       _comparer = comparer ?? const PackFingerprintComparerService();

  /// Registers existing spots so future checks can detect duplicates.
  void addExisting(Iterable<TrainingPackSpot> spots) {
    for (final s in spots) {
      _seen.add(_fingerprint.generate(s));
    }
  }

  /// Returns `true` if [spot] is a duplicate and logs the skip.
  bool isDuplicate(TrainingPackSpot spot, {String? source}) {
    final fp = _fingerprint.generate(spot);
    if (_seen.contains(fp)) {
      _skipped++;
      AutogenPipelineDebugStatsService.incrementDeduplicated();
      AutogenPipelineEventLoggerService.log(
        'deduplicated',
        'Skipped duplicate ${spot.id} from ${source ?? 'unknown'}',
      );
      _log.writeln('Skipped duplicate from ${source ?? 'unknown'}: ${spot.id}');
      return true;
    }
    _seen.add(fp);
    return false;
  }

  /// Deduplicates [spots] and returns a new list containing only unique items.
  ///
  /// Duplicates are detected via a fingerprint based on hero hand, board,
  /// position and action. When [keepHighestWeight] is `true`, the spot with the
  /// largest `meta['weight']` value is preserved. Otherwise the first occurrence
  /// is kept. All decisions are logged for debugging purposes.
  List<TrainingPackSpot> deduplicateSpots(
    List<TrainingPackSpot> spots, {
    bool keepHighestWeight = false,
    String? source,
    bool logLists = false,
  }) {
    final unique = <String, TrainingPackSpot>{};
    for (final spot in spots) {
      final fp = _fingerprint.generate(spot);
      final existing = unique[fp];
      if (_seen.contains(fp) && existing == null) {
        _skipped++;
        AutogenPipelineDebugStatsService.incrementDeduplicated();
        AutogenPipelineEventLoggerService.log(
          'deduplicated',
          'Dropped ${spot.id} from ${source ?? 'memory'}',
        );
        _log.writeln('dropped ${spot.id} from ${source ?? 'memory'}');
        continue;
      }

      if (existing == null) {
        unique[fp] = spot;
        _log.writeln('kept ${spot.id}');
        continue;
      }

      // Duplicate within the same batch.
      final wExisting = (existing.meta['weight'] as num?)?.toDouble() ?? 0.0;
      final wNew = (spot.meta['weight'] as num?)?.toDouble() ?? 0.0;
      if (keepHighestWeight && wNew > wExisting) {
        _log.writeln('dropped ${existing.id} replaced by ${spot.id}');
        unique[fp] = spot;
      } else {
        _log.writeln('dropped ${spot.id} duplicate of ${existing.id}');
      }
      _skipped++;
      AutogenPipelineDebugStatsService.incrementDeduplicated();
      AutogenPipelineEventLoggerService.log(
        'deduplicated',
        'Dropped ${spot.id} duplicate of ${existing.id}',
      );
    }

    _seen.addAll(unique.keys);
    if (logLists) {
      final originalIds = spots.map((s) => s.id).join(',');
      final filteredIds = unique.values.map((s) => s.id).join(',');
      _log.writeln('original: [$originalIds]');
      _log.writeln('filtered: [$filteredIds]');
    }
    final removed = spots.length - unique.length;
    _log.writeln(
      'Removed $removed duplicate${removed == 1 ? '' : 's'} from ${source ?? 'batch'}',
    );
    return unique.values.toList();
  }

  /// Deduplicates [original] by removing spots with matching fingerprints.
  ///
  /// Convenience wrapper around [deduplicateSpots] for [TrainingPackModel].
  TrainingPackModel deduplicatePack(
    TrainingPackModel original, {
    bool keepHighestWeight = false,
  }) {
    final unique = deduplicateSpots(
      original.spots,
      keepHighestWeight: keepHighestWeight,
      source: original.id,
    );
    return TrainingPackModel(
      id: original.id,
      title: original.title,
      spots: unique,
      tags: List<String>.from(original.tags),
      metadata: Map<String, dynamic>.from(original.metadata),
    );
  }

  int get skippedCount => _skipped;

  /// Closes the underlying log sink.
  Future<void> dispose() => _log.close();

  /// Deduplicates [input] training packs by removing those deemed duplicates.
  ///
  /// Packs are compared using [_comparer]. When two packs have a similarity of
  /// 0.9 or higher, one will be dropped according to the following rules:
  ///
  /// * If only one pack is auto generated, that pack is removed.
  /// * If both are auto generated, the newer pack (by `createdAt` or `id` as a
  ///   fallback) is removed.
  ///
  /// A debug log entry is emitted for every removed pack.
  List<TrainingPackModel> deduplicate(List<TrainingPackModel> input) {
    final dups = _comparer.findDuplicates(input, threshold: 0.9);
    final toRemove = <String>{};

    for (final r in dups) {
      final a = r.a;
      final b = r.b;
      final autoA = _isAutoGenerated(a);
      final autoB = _isAutoGenerated(b);
      if (!autoA && !autoB) continue;

      TrainingPackModel remove;
      TrainingPackModel keep;
      if (autoA && !autoB) {
        remove = a;
        keep = b;
      } else if (autoB && !autoA) {
        remove = b;
        keep = a;
      } else {
        final ca = _createdAt(a);
        final cb = _createdAt(b);
        if (ca != null && cb != null) {
          if (ca.isAfter(cb)) {
            remove = a;
            keep = b;
          } else {
            remove = b;
            keep = a;
          }
        } else if (ca != null || cb != null) {
          // Treat missing date as older.
          if (ca == null) {
            remove = b;
            keep = a;
          } else {
            remove = a;
            keep = b;
          }
        } else {
          // Fallback to id comparison for determinism.
          if (a.id.compareTo(b.id) > 0) {
            remove = a;
            keep = b;
          } else {
            remove = b;
            keep = a;
          }
        }
      }

      if (toRemove.add(remove.id)) {
        AppLogger.log(
          'AutoDeduplicationEngine: dropped ${remove.id} duplicate of ${keep.id} (sim=${r.similarity.toStringAsFixed(2)})',
        );
      }
    }

    return [
      for (final p in input)
        if (!toRemove.contains(p.id)) p,
    ];
  }

  bool _isAutoGenerated(TrainingPackModel pack) {
    final metaFlag = pack.metadata['autoGenerated'];
    if (metaFlag is bool && metaFlag) return true;
    return pack.tags.contains('autoGenerated');
  }

  DateTime? _createdAt(TrainingPackModel pack) {
    final v = pack.metadata['createdAt'];
    if (v is DateTime) return v;
    if (v is String) {
      return DateTime.tryParse(v);
    }
    return null;
  }

  /// Scans the training pack library and reports near-duplicate packs.
  Future<AutoDeduplicationReport> run({double threshold = 0.8}) async {
    final packs = await _library.getAllPacks();
    final duplicates = _comparer.findDuplicates(packs, threshold: threshold);

    final graph = <String, Set<String>>{};
    for (final r in duplicates) {
      graph.putIfAbsent(r.a.id, () => <String>{}).add(r.b.id);
      graph.putIfAbsent(r.b.id, () => <String>{}).add(r.a.id);
    }

    final mergeSuggestions = <String, List<String>>{};
    final visited = <String>{};
    final packMap = {for (final p in packs) p.id: p};

    for (final id in graph.keys) {
      if (visited.contains(id)) continue;
      final stack = <String>[id];
      final group = <String>{};
      while (stack.isNotEmpty) {
        final current = stack.removeLast();
        if (!visited.add(current)) continue;
        group.add(current);
        for (final n in graph[current] ?? const <String>{}) {
          if (!visited.contains(n)) stack.add(n);
        }
      }
      if (group.length < 2) continue;
      final groupPacks = [for (final gid in group) packMap[gid]!];
      groupPacks.sort((a, b) => b.spots.length.compareTo(a.spots.length));
      final base = groupPacks.first;
      mergeSuggestions[base.id] = [for (final p in groupPacks.skip(1)) p.id];
    }

    return AutoDeduplicationReport(
      duplicates: duplicates,
      mergeSuggestions: mergeSuggestions,
    );
  }
}
