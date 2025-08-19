import '../session_player/models.dart';
import '../../services/spot_importer.dart';

/// JSONL starter pack for ICM L4 BB jam vs fold drills.
const String icmL4BbV1Jsonl = '''
{"kind":"l4_icm_bb_jam_vs_fold","hand":"AhKc","pos":"BB","stack":"8bb","action":"jam"}
{"kind":"l4_icm_bb_jam_vs_fold","hand":"QdJd","pos":"BB","stack":"9bb","action":"fold"}
{"kind":"l4_icm_bb_jam_vs_fold","hand":"Ts9s","pos":"BB","stack":"10bb","action":"jam"}
{"kind":"l4_icm_bb_jam_vs_fold","hand":"7h7c","pos":"BB","stack":"11bb","action":"jam"}
{"kind":"l4_icm_bb_jam_vs_fold","hand":"Ad5d","pos":"BB","stack":"12bb","action":"fold"}
{"kind":"l4_icm_bb_jam_vs_fold","hand":"KcQh","pos":"BB","stack":"13bb","action":"jam"}
{"kind":"l4_icm_bb_jam_vs_fold","hand":"Jh8h","pos":"BB","stack":"14bb","action":"fold"}
{"kind":"l4_icm_bb_jam_vs_fold","hand":"9c9d","pos":"BB","stack":"15bb","action":"jam"}
{"kind":"l4_icm_bb_jam_vs_fold","hand":"5s4s","pos":"BB","stack":"16bb","action":"fold"}
{"kind":"l4_icm_bb_jam_vs_fold","hand":"QcTd","pos":"BB","stack":"17bb","action":"jam"}
{"kind":"l4_icm_bb_jam_vs_fold","hand":"8d6d","pos":"BB","stack":"18bb","action":"fold"}
{"kind":"l4_icm_bb_jam_vs_fold","hand":"As2s","pos":"BB","stack":"20bb","action":"jam"}
''';

/// Parses [icmL4BbV1Jsonl] and returns its spots.
List<UiSpot> loadIcmL4BbV1() {
  final r = SpotImporter.parse(icmL4BbV1Jsonl, format: 'jsonl');
  return r.spots;
}
