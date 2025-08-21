import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

/// Stub loader for the `online_economics_rakeback_promos` curriculum module.
///
/// The embedded spot acts as a canonical guard, ensuring the loader
/// parses correctly during early development.
const String _onlineEconomicsRakebackPromosStub = '''
{"kind":"l1_core_call_vs_price","hand":"AhKc","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadOnlineEconomicsRakebackPromosStub() {
  final r = SpotImporter.parse(
    _onlineEconomicsRakebackPromosStub,
    format: 'jsonl',
  );
  return r.spots;
}
