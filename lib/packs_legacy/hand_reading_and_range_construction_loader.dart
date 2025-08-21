import '../ui/session_player/models.dart';
import '../services/spot_importer.dart';

/// Stub loader for the `hand_reading_and_range_construction` curriculum module.
///
/// The embedded spot acts as a canonical guard, ensuring the loader
/// parses correctly during early development.
const String _handReadingAndRangeConstructionStub = '''
{"kind":"l1_core_call_vs_price","hand":"AhKc","pos":"BB","stack":"10bb","action":"call"}
''';

List<UiSpot> loadHandReadingAndRangeConstructionStub() {
  final r = SpotImporter.parse(
    _handReadingAndRangeConstructionStub,
    format: 'jsonl',
  );
  return r.spots;
}
