import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

// Stub pack loader for the core_river_fundamentals module.
const String _coreRiverFundamentalsStub = '''
{"kind":"l1_core_call_vs_price","hand":"AsKd","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadCoreRiverFundamentalsStub() {
  final r = SpotImporter.parse(_coreRiverFundamentalsStub, format: 'jsonl');
  return r.spots;
}
