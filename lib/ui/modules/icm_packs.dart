import '../session_player/models.dart';
import '../../services/spot_importer.dart';

/// JSONL starter pack for ICM L4 SB jam vs fold drills.
const String icmL4SbV1Jsonl = '''
{"kind":"l4_icm_sb_jam_vs_fold","hand":"AhKc","pos":"SB","stack":"8bb","action":"jam"}
{"kind":"l4_icm_sb_jam_vs_fold","hand":"QdJd","pos":"SB","stack":"9bb","action":"fold"}
{"kind":"l4_icm_sb_jam_vs_fold","hand":"Ts9s","pos":"SB","stack":"10bb","action":"jam"}
{"kind":"l4_icm_sb_jam_vs_fold","hand":"7h7c","pos":"SB","stack":"11bb","action":"jam"}
{"kind":"l4_icm_sb_jam_vs_fold","hand":"Ad5d","pos":"SB","stack":"12bb","action":"fold"}
{"kind":"l4_icm_sb_jam_vs_fold","hand":"KcQh","pos":"SB","stack":"13bb","action":"jam"}
{"kind":"l4_icm_sb_jam_vs_fold","hand":"Jh8h","pos":"SB","stack":"14bb","action":"fold"}
{"kind":"l4_icm_sb_jam_vs_fold","hand":"9c9d","pos":"SB","stack":"15bb","action":"jam"}
{"kind":"l4_icm_sb_jam_vs_fold","hand":"5s4s","pos":"SB","stack":"16bb","action":"fold","vsPos":""}
{"kind":"l4_icm_sb_jam_vs_fold","hand":"QcTd","pos":"SB","stack":"17bb","action":"jam","vsPos":""}
{"kind":"l4_icm_sb_jam_vs_fold","hand":"8d6d","pos":"SB","stack":"18bb","action":"fold"}
{"kind":"l4_icm_sb_jam_vs_fold","hand":"As2s","pos":"SB","stack":"20bb","action":"jam"}
''';

/// Parses [icmL4SbV1Jsonl] and returns its spots.
List<UiSpot> loadIcmL4SbV1() {
  final r = SpotImporter.parse(icmL4SbV1Jsonl, format: 'jsonl');
  return r.spots;
}

