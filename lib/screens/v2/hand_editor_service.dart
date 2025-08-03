import '../../models/v2/training_pack_spot.dart';
import '../../helpers/training_pack_storage.dart';

/// Handles persistence for the hand editor.
class HandEditorService {
  /// Saves the updated [spot] into existing templates.
  Future<void> saveSpot(TrainingPackSpot spot) async {
    final templates = await TrainingPackStorage.load();
    for (final t in templates) {
      for (var i = 0; i < t.spots.length; i++) {
        if (t.spots[i].id == spot.id) {
          t.spots[i] = spot;
          break;
        }
      }
    }
    await TrainingPackStorage.save(templates);
  }
}
