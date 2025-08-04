import '../models/v2/training_pack_template_v2.dart';

/// Simple in-memory store for the most recently generated pack.
class RecentPackStore {
  RecentPackStore();

  static final RecentPackStore instance = RecentPackStore();

  TrainingPackTemplateV2? _pack;
  TrainingPackTemplateV2? get last => _pack;

  /// Saves [pack] as the most recently generated pack.
  Future<void> save(TrainingPackTemplateV2 pack) async {
    _pack = pack;
  }
}
