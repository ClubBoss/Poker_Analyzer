import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

// Stub pack loader for the core_river_play module.
const String _coreRiverPlayStub = '''
{"kind":"l1_core_call_vs_price","hand":"AsKd","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadCoreRiverPlayStub() {
  final r = SpotImporter.parse(_coreRiverPlayStub, format: 'jsonl');
  return r.spots;
}
