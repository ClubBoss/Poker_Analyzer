import 'package:shared_preferences/shared_preferences.dart';

/// Persists the last visited block within a theory track.
class TheoryTrackResumeService {
  TheoryTrackResumeService._();
  static final instance = TheoryTrackResumeService._();

  static const _keyPrefix = 'theory_track_last_block_';

  Future<void> saveLastVisitedBlock(String trackId, String blockId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$trackId', blockId);
  }

  Future<String?> getLastVisitedBlock(String trackId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_keyPrefix$trackId');
  }
}

