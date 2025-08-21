import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

const String _cashL3V1Stub = '''
{"kind":"l1_core_call_vs_price","hand":"AhKc","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadCashL3V1Stub() {
  final r = SpotImporter.parse(_cashL3V1Stub, format: 'jsonl');
  return r.spots;
}
