import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

/// Stub loader for the `review_workflow_and_study_routines` curriculum module.
///
/// The embedded spot acts as a canonical guard, ensuring the loader
/// parses correctly during early development.
const String _reviewWorkflowAndStudyRoutinesStub = '''
{"kind":"l1_core_call_vs_price","hand":"AhKc","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadReviewWorkflowAndStudyRoutinesStub() {
  final r = SpotImporter.parse(
    _reviewWorkflowAndStudyRoutinesStub,
    format: 'jsonl',
  );
  return r.spots;
}
