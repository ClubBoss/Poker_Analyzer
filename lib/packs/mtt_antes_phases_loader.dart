import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

const String _mttAntesPhasesStub = '''
{"kind":"l1_core_call_vs_price","hand":"AhKc","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadMttAntesPhasesStub() {
  final r = SpotImporter.parse(_mttAntesPhasesStub, format: 'jsonl');
  return r.spots;
}
