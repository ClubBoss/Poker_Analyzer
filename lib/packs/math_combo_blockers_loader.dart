import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

/// Stub loader for the `math_combo_blockers` curriculum module.
///
/// The embedded spot acts as a canonical guard, ensuring the loader
/// parses correctly during early development.
const String _mathComboBlockersStub = '''
{"kind":"l1_core_call_vs_price","hand":"AcKd","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadMathComboBlockersStub() {
  final r = SpotImporter.parse(_mathComboBlockersStub, format: 'jsonl');
  return r.spots;
}
