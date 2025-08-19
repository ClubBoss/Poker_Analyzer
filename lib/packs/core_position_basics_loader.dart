// Placeholder pack for core_position_basics.
import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

const String _corePositionBasicsStub = '''
{"kind":"l1_core_call_vs_price","hand":"AhKc","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadCorePositionBasicsStub() {
  final r = SpotImporter.parse(_corePositionBasicsStub, format: 'jsonl');
  return r.spots;
}
