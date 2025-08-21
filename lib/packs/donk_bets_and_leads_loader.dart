import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

/// Stub loader for the `donk_bets_and_leads` curriculum module.
///
/// The embedded spot acts as a canonical guard, ensuring the loader
/// parses correctly during early development.
const String _donkBetsAndLeadsStub = '''
{"kind":"l1_core_call_vs_price","hand":"AhKc","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadDonkBetsAndLeadsStub() {
  final r = SpotImporter.parse(_donkBetsAndLeadsStub, format: 'jsonl');
  return r.spots;
}
