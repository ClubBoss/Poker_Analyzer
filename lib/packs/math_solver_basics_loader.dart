import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

/// Stub loader for the `math_solver_basics` curriculum module.
///
/// The embedded spot acts as a canonical guard, ensuring the loader
/// parses correctly during early development.
const String _mathSolverBasicsStub = '''
{"kind":"l1_core_call_vs_price","hand":"AhKd","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadMathSolverBasicsStub() {
  final r = SpotImporter.parse(_mathSolverBasicsStub, format: 'jsonl');
  return r.spots;
}
