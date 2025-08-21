import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

// Stub pack loader for the core_flop_fundamentals module.
const String _coreFlopFundamentalsStub = '''
{"kind":"l1_core_call_vs_price","hand":"AsKd","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadCoreFlopFundamentalsStub() {
  final r = SpotImporter.parse(_coreFlopFundamentalsStub, format: 'jsonl');
  return r.spots;
}
