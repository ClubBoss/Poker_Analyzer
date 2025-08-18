import '../models/theory_lesson_cluster.dart';
import '../models/theory_mini_lesson_node.dart';
import 'theory_cluster_id_hasher.dart';

/// Serializes and deserializes [TheoryLessonCluster] objects.
class TheoryLessonClusterSerializer {
  const TheoryLessonClusterSerializer();

  /// Converts [cluster] into a JSON-friendly map.
  Map<String, dynamic> toJson(
    TheoryLessonCluster cluster, {
    String? clusterId,
  }) {
    return {
      'clusterId': clusterId ?? TheoryClusterIdHasher.hash(cluster),
      'lessons': [for (final l in cluster.lessons) l.toJson()],
      'sharedTags': cluster.sharedTags.toList(),
      if (cluster.autoTags.isNotEmpty)
        'autoTags': List<String>.from(cluster.autoTags),
    };
  }

  /// Reconstructs a [TheoryLessonCluster] and its id from [json].
  ({TheoryLessonCluster cluster, String clusterId}) fromJson(Map json) {
    final lessonsJson = json['lessons'] as List? ?? [];
    final lessons = <TheoryMiniLessonNode>[
      for (final l in lessonsJson)
        if (l is Map)
          TheoryMiniLessonNode.fromJson(Map<String, dynamic>.from(l)),
    ];

    final rawTags = json['sharedTags'] ?? json['tags'];
    final sharedTags = <String>{
      for (final t in (rawTags as List? ?? [])) t.toString(),
    };

    final autoTags = <String>[
      for (final t in (json['autoTags'] as List? ?? [])) t.toString(),
    ];

    final cluster = TheoryLessonCluster(
      lessons: lessons,
      tags: sharedTags,
      autoTags: autoTags,
    );

    final clusterId =
        json['clusterId']?.toString() ?? TheoryClusterIdHasher.hash(cluster);

    return (cluster: cluster, clusterId: clusterId);
  }
}
