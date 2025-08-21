import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

/// Stub loader for the `math_pot_odds_equity` curriculum module.
///
/// The embedded spot acts as a canonical guard, ensuring the loader
/// parses correctly during early development.
const String _mathPotOddsEquityStub = '''
{"kind":"l1_core_call_vs_price","hand":"AcKd","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadMathPotOddsEquityStub() {
  final r = SpotImporter.parse(_mathPotOddsEquityStub, format: 'jsonl');
  return r.spots;
}
