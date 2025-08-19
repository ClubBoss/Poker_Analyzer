import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

const String _cashIsolationRaisesStub = '''
{"kind":"l1_core_call_vs_price","hand":"AhKc","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadCashIsolationRaisesStub() {
  final r = SpotImporter.parse(_cashIsolationRaisesStub, format: 'jsonl');
  return r.spots;
}
