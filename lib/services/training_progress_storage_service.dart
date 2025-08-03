import 'package:shared_preferences/shared_preferences.dart';

/// Handles persistence for training progress data.
class TrainingProgressStorageService {
  const TrainingProgressStorageService();

  String _key(String packId) => 'pack_progress_' + packId;

  Future<Set<String>> loadCompletedSpotIds(String packId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key(packId));
    return list?.toSet() ?? {};
  }

  Future<void> saveCompletedSpotIds(String packId, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(packId), ids.toList());
  }
}
