import '../session_player/models.dart';
import '../../services/spot_importer.dart';

/// JSONL starter pack for ICM L4 Bubble jam vs fold drills.
const String icmL4BubbleV1Jsonl = '''
{"kind":"l4_icm_bubble_jam_vs_fold","hand":"AhKc","pos":"SB","stack":"9bb","action":"jam"}
{"kind":"l4_icm_bubble_jam_vs_fold","hand":"QdJd","pos":"BB","stack":"10bb","action":"fold"}
{"kind":"l4_icm_bubble_jam_vs_fold","hand":"Ts9s","pos":"SB","stack":"8bb","action":"jam"}
{"kind":"l4_icm_bubble_jam_vs_fold","hand":"7h7c","pos":"BB","stack":"12bb","action":"jam"}
{"kind":"l4_icm_bubble_jam_vs_fold","hand":"Ad5d","pos":"SB","stack":"11bb","action":"fold"}
{"kind":"l4_icm_bubble_jam_vs_fold","hand":"KcQh","pos":"BB","stack":"13bb","action":"jam"}
{"kind":"l4_icm_bubble_jam_vs_fold","hand":"Jh8h","pos":"SB","stack":"14bb","action":"fold"}
{"kind":"l4_icm_bubble_jam_vs_fold","hand":"9c9d","pos":"BB","stack":"15bb","action":"jam"}
{"kind":"l4_icm_bubble_jam_vs_fold","hand":"5s4s","pos":"SB","stack":"16bb","action":"fold"}
{"kind":"l4_icm_bubble_jam_vs_fold","hand":"QcTd","pos":"BB","stack":"17bb","action":"jam"}
{"kind":"l4_icm_bubble_jam_vs_fold","hand":"8d6d","pos":"SB","stack":"18bb","action":"fold"}
{"kind":"l4_icm_bubble_jam_vs_fold","hand":"As2s","pos":"BB","stack":"20bb","action":"jam"}
''';

List<UiSpot> loadIcmL4BubbleV1() {
  final r = SpotImporter.parse(icmL4BubbleV1Jsonl, format: 'jsonl');
  return r.spots;
}
