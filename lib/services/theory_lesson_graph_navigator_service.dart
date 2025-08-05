import 'mini_lesson_library_service.dart';
import '../models/theory_lesson_cluster.dart';
import '../models/theory_mini_lesson_node.dart';

/// Enables forward, backward and sibling navigation between theory lessons.
class TheoryLessonGraphNavigatorService {
  final MiniLessonLibraryService library;
  final TheoryLessonCluster? cluster;
  final Set<String> tagFilter;

  final Map<String, TheoryMiniLessonNode> _byId = {};
  final Map<String, List<String>> _prev = {};

  bool _initialized = false;

  TheoryLessonGraphNavigatorService({
    MiniLessonLibraryService? library,
    this.cluster,
    Set<String>? tagFilter,
  }) : library = library ?? MiniLessonLibraryService.instance,
       tagFilter = tagFilter ?? const {};

  /// Loads lessons and builds navigation indexes.
  Future<void> initialize() async {
    if (_initialized) return;
    await library.loadAll();
    _buildIndexes();
    _initialized = true;
  }

  void _buildIndexes() {
    _byId.clear();
    _prev.clear();

    final lessons = cluster?.lessons ?? library.all;
    for (final l in lessons) {
      if (tagFilter.isNotEmpty && !l.tags.any((t) => tagFilter.contains(t))) {
        continue;
      }
      _byId[l.id] = l;
    }

    for (final l in _byId.values) {
      for (final next in l.nextIds) {
        if (_byId.containsKey(next)) {
          _prev.putIfAbsent(next, () => []).add(l.id);
        }
      }
    }
  }

  TheoryMiniLessonNode? _byIdOrNull(String id) => _byId[id];

  /// Returns the next lesson following [id] or null.
  TheoryMiniLessonNode? getNext(String id) {
    final node = _byId[id];
    if (node == null) return null;
    for (final next in node.nextIds) {
      final candidate = _byId[next];
      if (candidate != null) return candidate;
    }
    if (cluster != null) {
      final idx = cluster!.lessons.indexWhere((e) => e.id == id);
      if (idx >= 0 && idx < cluster!.lessons.length - 1) {
        final fallback = cluster!.lessons[idx + 1];
        return _byIdOrNull(fallback.id);
      }
    }
    return null;
  }

  /// Returns the previous lesson leading to [id] or null.
  TheoryMiniLessonNode? getPrevious(String id) {
    final list = _prev[id];
    if (list != null && list.isNotEmpty) {
      for (final prev in list) {
        final node = _byId[prev];
        if (node != null) return node;
      }
    }
    if (cluster != null) {
      final idx = cluster!.lessons.indexWhere((e) => e.id == id);
      if (idx > 0) {
        final fallback = cluster!.lessons[idx - 1];
        return _byIdOrNull(fallback.id);
      }
    }
    return null;
  }

  /// Returns lessons related to [id] by cluster membership or shared tags.
  List<TheoryMiniLessonNode> getSiblings(String id) {
    final node = _byId[id];
    if (node == null) return const [];
    final result = <TheoryMiniLessonNode>{};

    if (cluster != null) {
      for (final l in cluster!.lessons) {
        if (l.id != id && _byId.containsKey(l.id)) {
          result.add(_byId[l.id]!);
        }
      }
    }

    for (final tag in node.tags) {
      for (final other in _byId.values) {
        if (other.id == id) continue;
        if (other.tags.contains(tag)) result.add(other);
      }
    }

    return result.toList();
  }
}

