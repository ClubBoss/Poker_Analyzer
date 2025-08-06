import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/theory_lesson_cluster.dart';

/// Generates a deterministic id for a [TheoryLessonCluster].
class TheoryClusterIdHasher {
  TheoryClusterIdHasher._();

  /// Returns a stable hash based on the sorted lesson ids of [cluster].
  static String hash(TheoryLessonCluster cluster, {int length = 12}) {
    final ids = cluster.lessons.map((e) => e.id).toList()..sort();
    final joined = ids.join('-');
    final digest = sha256.convert(utf8.encode(joined)).toString();
    return digest.substring(0, length);
  }
}
