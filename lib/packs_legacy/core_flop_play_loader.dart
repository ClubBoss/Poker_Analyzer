import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

// Stub pack loader for the core_flop_play module.
const String _coreFlopPlayStub = '''
{"kind":"l1_core_call_vs_price","hand":"AsKd","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadCoreFlopPlayStub() {
  final r = SpotImporter.parse(_coreFlopPlayStub, format: 'jsonl');
  return r.spots;
}
