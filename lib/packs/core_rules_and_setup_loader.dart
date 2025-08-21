import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

const String _coreRulesAndSetupStub = '''
{"kind":"l1_core_call_vs_price","hand":"AhKd","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadCoreRulesAndSetupStub() {
  final r = SpotImporter.parse(_coreRulesAndSetupStub, format: 'jsonl');
  return r.spots;
}
