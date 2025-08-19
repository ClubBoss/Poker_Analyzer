import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

// Stub pack loader for the core_board_textures module.
const String _coreBoardTexturesStub = '''
{"kind":"l1_core_call_vs_price","hand":"AhKc","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadCoreBoardTexturesStub() {
  final r = SpotImporter.parse(_coreBoardTexturesStub, format: 'jsonl');
  return r.spots;
}
