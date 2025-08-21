import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

const String _mttDay2BaggingAndReentryEvStub = '''
{"kind":"l1_core_call_vs_price","hand":"AhKc","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadMttDay2BaggingAndReentryEvStub() {
  final r = SpotImporter.parse(
    _mttDay2BaggingAndReentryEvStub,
    format: 'jsonl',
  );
  return r.spots;
}
