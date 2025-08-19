import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

// Stub loader for the HU Turn Play module.

const String _huTurnPlayStub = '''
{"kind":"l1_core_call_vs_price","hand":"AhKc","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadHuTurnPlayStub() {
  final r = SpotImporter.parse(_huTurnPlayStub, format: 'jsonl');
  return r.spots;
}
