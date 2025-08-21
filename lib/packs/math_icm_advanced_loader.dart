import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

/// Stub loader for the `math_icm_advanced` curriculum module.
///
/// The embedded spot acts as a canonical guard, ensuring the loader
/// parses correctly during early development.
const String _mathIcmAdvancedStub = '''
{"kind":"l1_core_call_vs_price","hand":"AhKd","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadMathIcmAdvancedStub() {
  final r = SpotImporter.parse(_mathIcmAdvancedStub, format: 'jsonl');
  return r.spots;
}
