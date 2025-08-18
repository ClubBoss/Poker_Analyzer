import '../session_player/models.dart';
import '../../services/spot_importer.dart';

/// JSONL starter pack for cash L3 drills.
const String cashL3V1Jsonl = '''
{"kind":"l3_flop_jam_vs_raise","hand":"AhKh","pos":"BTN","stack":"30bb","action":"jam","vsPos":"SB"}
{"kind":"l3_flop_jam_vs_raise","hand":"QdQs","pos":"SB","stack":"35bb","action":"jam","vsPos":"BTN"}
{"kind":"l3_flop_jam_vs_raise","hand":"JcTc","pos":"BB","stack":"25bb","action":"fold"}
{"kind":"l3_flop_jam_vs_raise","hand":"9h8h","pos":"BTN","stack":"20bb","action":"fold","vsPos":"BB"}
{"kind":"l3_turn_jam_vs_raise","hand":"AsQs","pos":"SB","stack":"40bb","action":"jam","vsPos":"BTN"}
{"kind":"l3_turn_jam_vs_raise","hand":"KdQd","pos":"BTN","stack":"32bb","action":"fold","vsPos":"SB"}
{"kind":"l3_turn_jam_vs_raise","hand":"7s7d","pos":"BB","stack":"28bb","action":"jam"}
{"kind":"l3_turn_jam_vs_raise","hand":"Jh9h","pos":"SB","stack":"22bb","action":"fold"}
{"kind":"l3_river_jam_vs_raise","hand":"AcJc","pos":"BTN","stack":"24bb","action":"jam","vsPos":"BB"}
{"kind":"l3_river_jam_vs_raise","hand":"Td9d","pos":"BB","stack":"30bb","action":"fold","vsPos":"BTN"}
{"kind":"l3_river_jam_vs_raise","hand":"QhJh","pos":"SB","stack":"27bb","action":"jam"}
{"kind":"l3_river_jam_vs_raise","hand":"8c7c","pos":"BTN","stack":"36bb","action":"fold"}
''';

/// Parses [cashL3V1Jsonl] and returns its spots.
List<UiSpot> loadCashL3V1() {
  final r = SpotImporter.parse(cashL3V1Jsonl, format: 'jsonl');
  return r.spots;
}
