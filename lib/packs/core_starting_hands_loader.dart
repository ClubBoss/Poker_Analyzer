import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

const String _coreStartingHandsStub = '''
{"kind":"l1_core_call_vs_price","hand":"AsKd","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadCoreStartingHandsStub() {
  final r = SpotImporter.parse(_coreStartingHandsStub, format: 'jsonl');
  return r.spots;
}
