import '../session_player/models.dart';
import '../../services/spot_importer.dart';
import 'icm_packs.dart';
import 'icm_bb_packs.dart';

/// JSONL for ICM L4 Mix v1: SB + BB concatenated (newline-separated).
const String icmL4MixV1Jsonl =
    '''
$icmL4SbV1Jsonl
$icmL4BbV1Jsonl
''';

/// Parses the mixed JSONL and returns all spots.
List<UiSpot> loadIcmL4MixV1() {
  final r = SpotImporter.parse(icmL4MixV1Jsonl, format: 'jsonl');
  return r.spots;
}
