import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_library_service.dart';

/// Provides navigation helpers for mini theory lesson graphs.
class TheoryGraphNavigationEngine {
  final MiniLessonLibraryService library;

  TheoryGraphNavigationEngine({MiniLessonLibraryService? library})
      : library = library ?? MiniLessonLibraryService.instance;

  final Map<String, TheoryMiniLessonNode> _byId = {};
  final Map<String, String?> _nextIndex = {};
  final Map<String, String?> _previousIndex = {};
  final Map<String, String?> _restartIndex = {};

  bool _initialized = false;

  /// Loads lessons from [library] and builds traversal indexes.
  Future<void> initialize() async {
    if (_initialized) return;
    await library.loadAll();
    _buildIndexes();
    _initialized = true;
  }

  void _buildIndexes() {
    _byId.clear();
    for (final l in library.all) {
      _byId[l.id] = l;
    }

    final incoming = <String, int>{for (final id in _byId.keys) id: 0};
    for (final n in _byId.values) {
      for (final next in n.nextIds) {
        if (_byId.containsKey(next)) {
          incoming[next] = (incoming[next] ?? 0) + 1;
        }
      }
    }

    final visited = <String>{};
    final roots = [
      for (final id in _byId.keys)
        if ((incoming[id] ?? 0) == 0) id,
    ];

    for (final root in roots) {
      _traverseChain(root, visited);
    }

    for (final id in _byId.keys) {
      if (!visited.contains(id)) {
        _traverseChain(id, visited);
      }
    }
  }

  void _traverseChain(String start, Set<String> globalVisited) {
    var current = start;
    var restart = _byId[current]!.tags.contains('milestone') ? current : start;
    final seen = <String>{};
    _restartIndex[current] = restart;
    while (true) {
      if (!globalVisited.add(current)) break;
      if (!seen.add(current)) break; // cycle detected
      final node = _byId[current];
      if (node == null) break;
      String? nextId;
      for (final n in node.nextIds) {
        if (_byId.containsKey(n)) {
          nextId = n;
          break;
        }
      }
      if (nextId == null || seen.contains(nextId)) {
        _nextIndex[current] = null;
        break;
      }
      _nextIndex[current] = nextId;
      _previousIndex.putIfAbsent(nextId, () => current);
      if (_byId[nextId]!.tags.contains('milestone')) {
        restart = nextId;
      }
      _restartIndex[nextId] = restart;
      current = nextId;
    }
  }

  /// Returns the next lesson following [currentId] or null.
  TheoryMiniLessonNode? getNext(String currentId) {
    final nextId = _nextIndex[currentId];
    return nextId != null ? _byId[nextId] : null;
  }

  /// Returns the previous lesson leading to [currentId] or null.
  TheoryMiniLessonNode? getPrevious(String currentId) {
    final prevId = _previousIndex[currentId];
    return prevId != null ? _byId[prevId] : null;
  }

  /// Returns the restart point (nearest root or milestone) for [currentId].
  TheoryMiniLessonNode? getRestartPoint(String currentId) {
    final restartId = _restartIndex[currentId];
    return restartId != null ? _byId[restartId] : null;
  }
}
