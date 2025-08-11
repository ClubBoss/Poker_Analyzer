import '../models/line_pattern.dart';
import '../models/line_graph_result.dart';
import '../models/spot_seed.dart';
import '../models/board.dart';
import '../models/card_model.dart';
import '../models/line_graph_node.dart';
import '../models/line_graph_edge.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/theory_mini_lesson_node.dart';
import 'theory_lesson_meta_tag_extractor_service.dart';
import 'board_splitter.dart';

class LineGraphEngine {
  LineGraphEngine({TheoryLessonMetaTagExtractorService? extractor})
      : _extractor = extractor ?? const TheoryLessonMetaTagExtractorService();

  final TheoryLessonMetaTagExtractorService _extractor;

  final Map<String, LineGraphNode> _nodes = <String, LineGraphNode>{};
  final List<LineGraphEdge> _edges = <LineGraphEdge>[];
  final Map<LineGraphNode, List<TheoryMiniLessonNode>> _lessonLinks = {};
  final Map<LineGraphNode, List<TrainingPackSpot>> _spotLinks = {};

  /// Adds a linear sequence of tagged actions to the graph.
  ///
  /// [tags] must follow the `streetAction` pattern such as `flopCbet`.
  /// Nodes are created for each tag and edges connect consecutive nodes.
  void addLine(List<String> tags, {String position = 'BTN'}) {
    LineGraphNode? prev;
    for (final t in tags) {
      final parsed = _parseTag(t);
      if (parsed == null) continue;
      final node = _ensureNode(parsed.key, parsed.value, position, {t});
      if (prev != null) {
        _edges.add(LineGraphEdge(from: prev, to: node));
      }
      prev = node;
    }
  }

  /// Links [lesson] to the graph using extracted metadata and tags.
  void linkLesson(TheoryMiniLessonNode lesson) {
    final meta = _extractor.extract(lesson);
    String? tag;
    for (final t in lesson.tags) {
      if (_parseTag(t) != null) {
        tag = t;
        break;
      }
    }
    if (tag == null || meta.position == null || meta.street == null) return;
    final parsed = _parseTag(tag)!;
    final node = _ensureNode(
      parsed.key,
      parsed.value,
      meta.position!,
      {tag, ...lesson.tags},
    );
    _lessonLinks.putIfAbsent(node, () => []).add(lesson);
  }

  /// Links [spot] to the graph by matching tags and target street.
  void linkSpot(TrainingPackSpot spot) {
    final street =
        spot.meta['targetStreet']?.toString().toLowerCase() ??
            _streetFromIndex(spot.street);
    for (final tag in spot.tags) {
      final parsed = _parseTag(tag);
      if (parsed == null) continue;
      if (street != null && parsed.key != street) continue;
      final position = spot.hand.position.name.toUpperCase();
      final node = _ensureNode(parsed.key, parsed.value, position, {tag});
      _spotLinks.putIfAbsent(node, () => []).add(spot);
    }
  }

  /// Returns a linear path of nodes starting with a node containing [startTag].
  /// Traversal follows the first edge on each node up to [depth] steps.
  List<LineGraphNode> getLine(String startTag, int depth) {
    final start = _nodes.values.firstWhere(
      (n) => n.tagSet.contains(startTag),
      orElse: () => LineGraphNode(
        street: '',
        action: '',
        position: '',
      ),
    );
    if (start.action.isEmpty) return [];
    final result = <LineGraphNode>[start];
    var current = start;
    for (var i = 0; i < depth; i++) {
      final next = _edges.firstWhere(
        (e) => e.from == current,
        orElse: () => LineGraphEdge(from: current, to: current),
      );
      if (next.to == current) break;
      result.add(next.to);
      current = next.to;
    }
    return result;
  }

  /// Returns theory lessons linked to [node].
  List<TheoryMiniLessonNode> findLinkedLessons(LineGraphNode node) =>
      List.unmodifiable(_lessonLinks[node] ?? const []);

  /// Returns training spots linked to [node].
  List<TrainingPackSpot> findLinkedPacks(LineGraphNode node) =>
      List.unmodifiable(_spotLinks[node] ?? const []);

  /// Returns next possible nodes reachable from [node].
  List<LineGraphNode> findNextOptions(LineGraphNode node) => [
        for (final e in _edges)
          if (e.from == node) e.to,
      ];

  LineGraphNode _ensureNode(
    String street,
    String action,
    String position,
    Set<String> tags,
  ) {
    final key = '$position|$street|$action';
    final existing = _nodes[key];
    if (existing != null) {
      existing.tagSet.addAll(tags);
      return existing;
    }
    final node = LineGraphNode(
      street: street,
      action: action,
      position: position,
      tagSet: tags,
    );
    _nodes[key] = node;
    return node;
  }

  MapEntry<String, String>? _parseTag(String tag) {
    final match =
        RegExp(r'^(flop|turn|river)([A-Z].+)', caseSensitive: false).firstMatch(tag);
    if (match == null) return null;
    final street = match.group(1)!.toLowerCase();
    final action = match
        .group(2)!
        .replaceFirst(RegExp('^.'), match.group(2)![0].toLowerCase());
    return MapEntry(street, action);
  }

  String? _streetFromIndex(int street) {
    switch (street) {
      case 1:
        return 'flop';
      case 2:
        return 'turn';
      case 3:
        return 'river';
      default:
        return null;
    }
  }

  LineGraphResult build(LinePattern pattern) {
    final Map<String, List<HandActionNode>> streets = {};
    final List<String> tags = [];

    pattern.streets.forEach((street, actions) {
      final nodes = <HandActionNode>[];
      for (final act in actions) {
        final actor = _inferActor(act);
        final tag = '$street${_capitalize(act)}';
        nodes.add(HandActionNode(actor: actor, action: act, tag: tag));
        tags.add(tag);
      }
      streets[street] = nodes;
    });

    return LineGraphResult(
      heroPosition: pattern.startingPosition ?? 'hero',
      streets: streets,
      tags: tags,
    );
  }

  String _inferActor(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('villain')) {
      return 'villain';
    }
    return 'hero';
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

  List<SpotSeed> expandLine({
    required String preflopAction,
    required String line,
    required List<CardModel> board,
    required List<CardModel> hand,
    required String position,
  }) {
    final split = BoardSplitter.split(board);
    final streets = <String>[];
    if (split.flop.isNotEmpty) streets.add('flop');
    if (split.turn != null) streets.add('turn');
    if (split.river != null) streets.add('river');

    final actions = line
        .split('-')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final grouped = _groupActions(actions, streets.length);

    final seeds = <SpotSeed>[];
    final history = <String>[];
    final accumulatedTags = <String>[];
    if (preflopAction.isNotEmpty) {
      history.add(preflopAction);
    }
    for (var i = 0; i < streets.length; i++) {
      final street = streets[i];
      final tags = grouped[i]
          .map((act) => '$street${_capitalize(act)}')
          .toList();
      accumulatedTags.addAll(tags);
      seeds.add(
        SpotSeed(
          board: _boardUpTo(split, i),
          hand: hand,
          position: position,
          previousActions: List<String>.from(history),
          targetStreet: street,
          tags: List<String>.from(accumulatedTags),
        ),
      );
      history.addAll(grouped[i]);
    }
    return seeds;
  }

  List<List<String>> _groupActions(List<String> actions, int streetCount) {
    final groups = <List<String>>[];
    var index = 0;
    var remaining = actions.length;
    for (
      var remainingStreets = streetCount;
      remainingStreets > 0;
      remainingStreets--
    ) {
      final minForRest = remainingStreets - 1;
      var size = remaining - minForRest;
      if (size < 0) size = 0;
      final end = index + size;
      groups.add(actions.sublist(index, end));
      index = end;
      remaining -= size;
    }
    return groups;
  }

  List<CardModel> _boardUpTo(Board board, int index) {
    switch (index) {
      case 0:
        return List<CardModel>.from(board.flop);
      case 1:
        return [...board.flop, if (board.turn != null) board.turn!];
      case 2:
        return [
          ...board.flop,
          if (board.turn != null) board.turn!,
          if (board.river != null) board.river!,
        ];
      default:
        return [];
    }
  }
}
