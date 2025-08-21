import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

/// Stub loader for the `hu_preflop_strategy` curriculum module.
///
/// The embedded spot acts as a canonical guard, ensuring the loader
/// parses correctly during early development.
const String _huPreflopStrategyStub = '''
{"kind":"l1_core_call_vs_price","hand":"AdKc","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadHuPreflopStrategyStub() {
  final r = SpotImporter.parse(_huPreflopStrategyStub, format: 'jsonl');
  return r.spots;
}
