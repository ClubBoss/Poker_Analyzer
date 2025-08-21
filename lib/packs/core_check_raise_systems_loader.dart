import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

// Stub pack loader for the core_check_raise_systems module.
const String _coreCheckRaiseSystemsStub = '''
{"kind":"l1_core_call_vs_price","hand":"AsKd","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadCoreCheckRaiseSystemsStub() {
  final r = SpotImporter.parse(_coreCheckRaiseSystemsStub, format: 'jsonl');
  return r.spots;
}
