import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

const String _coreBankrollManagementStub = '''
{"kind":"l1_core_call_vs_price","hand":"AhKc","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadCoreBankrollManagementStub() {
  final r = SpotImporter.parse(_coreBankrollManagementStub, format: 'jsonl');
  return r.spots;
}
