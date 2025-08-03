
/// Persists the last visited block within a theory track.
class TheoryTrackResumeService {
  TheoryTrackResumeService._();
  static final instance = TheoryTrackResumeService._();

  static const _keyPrefix = 'theory_track_last_block_';
  static const _trackKey = 'theory_track_last_id';

  Future<void> saveLastVisitedBlock(String trackId, String blockId) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setString('$_keyPrefix$trackId', blockId);
    await prefs.setString(_trackKey, trackId);
  }

  Future<String?> getLastVisitedBlock(String trackId) async {
    final prefs = await PreferencesService.getInstance();
    return prefs.getString('$_keyPrefix$trackId');
  }

  Future<String?> getLastVisitedTrackId() async {
    final prefs = await PreferencesService.getInstance();
    return prefs.getString(_trackKey);
  }
}

