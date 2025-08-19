// Placeholder pack for core_pot_odds_equity.
import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

const String _corePotOddsEquityStub = '''
{"kind":"l1_core_call_vs_price","hand":"AhKc","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadCorePotOddsEquityStub() {
  final r = SpotImporter.parse(_corePotOddsEquityStub, format: 'jsonl');
  return r.spots;
}
