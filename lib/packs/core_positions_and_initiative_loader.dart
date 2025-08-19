import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

/// Stub loader for the `core_positions_and_initiative` curriculum module.
///
/// The embedded spot acts as a canonical guard, ensuring the loader
/// parses correctly during early development.
const String _corePositionsAndInitiativeStub = '''
{"kind":"l1_core_call_vs_price","hand":"AhKc","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadCorePositionsAndInitiativeStub() {
  final r = SpotImporter.parse(_corePositionsAndInitiativeStub, format: 'jsonl');
  return r.spots;
}
