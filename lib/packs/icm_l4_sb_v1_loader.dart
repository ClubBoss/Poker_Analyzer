import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

const String _icmL4SbV1Stub = '''
{"kind":"l1_core_call_vs_price","hand":"AhKc","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadIcmL4SbV1Stub() {
  final r = SpotImporter.parse(_icmL4SbV1Stub, format: 'jsonl');
  return r.spots;
}
