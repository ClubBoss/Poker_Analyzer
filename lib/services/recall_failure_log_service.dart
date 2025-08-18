import '../models/recall_failure_spotting.dart';

/// Provides access to recall failure spottings used for hotspot drilldowns.
class RecallFailureLogService {
  RecallFailureLogService._();

  static final RecallFailureLogService instance = RecallFailureLogService._();

  /// Returns logged spottings for a hotspot identified by [mode] and [id].
  Future<List<RecallFailureSpotting>> getSpottingsForHotspot(
    String mode,
    String id,
  ) async {
    // Placeholder implementation.
    return [];
  }
}
