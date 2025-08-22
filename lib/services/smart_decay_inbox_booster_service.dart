import '../models/smart_inbox_item.dart';
import 'decay_tag_retention_tracker_service.dart';

/// Surfaces booster inbox items for highly decayed tags.
class SmartDecayInboxBoosterService {
  final DecayTagRetentionTrackerService retention;

  SmartDecayInboxBoosterService({DecayTagRetentionTrackerService? retention})
    : retention = retention ?? const DecayTagRetentionTrackerService();

  /// Returns [limit] top decayed tags as inbox booster items ordered by severity.
  Future<List<SmartInboxItem>> getItems({int limit = 5}) async {
    final entries = await retention.getMostDecayedTags(limit);
    return [
      for (final e in entries)
        SmartInboxItem(
          type: 'booster',
          tag: e.key,
          source: 'decayRecovery',
          urgency: e.value,
        ),
    ];
  }
}
