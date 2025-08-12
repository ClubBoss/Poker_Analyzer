import 'package:collection/collection.dart';

import '../models/v2/training_pack_spot.dart';
import 'spaced_review_service.dart';

class SRQueueItem {
  final TrainingPackSpot spot;
  final String packId;
  SRQueueItem({required this.spot, required this.packId});
}

List<SRQueueItem> buildSrQueue(
  SpacedReviewService service,
  Set<String> baseSpotIds, {
  DateTime? now,
  int limit = 50,
}) {
  final ids = service.dueSpotIds(now ?? DateTime.now(), limit: limit);
  final res = <SRQueueItem>[];
  for (final id in ids) {
    if (baseSpotIds.contains(id)) continue;
    final packId = service.packIdForSpot(id);
    if (packId == null) continue;
    final tpl = service.templates.templates.firstWhereOrNull((t) => t.id == packId);
    final s = tpl?.spots.firstWhereOrNull((s) => s.id == id);
    if (s != null) {
      res.add(
        SRQueueItem(
          spot: TrainingPackSpot.fromJson(s.toJson()),
          packId: packId,
        ),
      );
    }
  }
  return res;
}
