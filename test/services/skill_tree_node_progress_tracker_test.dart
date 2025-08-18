import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/skill_tree_build_result.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_node_progress_tracker.dart';
import 'package:poker_analyzer/services/skill_tree_track_resolver.dart';
import 'package:poker_analyzer/services/stage_completion_celebration_service.dart';
import 'package:poker_analyzer/services/skill_tree_library_service.dart';

class _FakeLibraryService implements SkillTreeLibraryService {
  final Map<String, SkillTreeBuildResult> _trees;
  final List<SkillTreeNodeModel> _nodes;
  _FakeLibraryService(this._trees, this._nodes);

  @override
  Future<void> reload() async {}

  @override
  SkillTreeBuildResult? getTree(String category) => _trees[category];

  @override
  SkillTreeBuildResult? getTrack(String trackId) => _trees[trackId];

  @override
  List<SkillTreeBuildResult> getAllTracks() => _trees.values.toList();

  @override
  List<SkillTreeNodeModel> getAllNodes() => List.unmodifiable(_nodes);
}

class _RecordingCelebrationService extends StageCompletionCelebrationService {
  _RecordingCelebrationService({
    required SkillTreeLibraryService library,
    required SkillTreeNodeProgressTracker progress,
  }) : super(library: library, progress: progress);

  int stageCalls = 0;
  int trackCalls = 0;

  @override
  Future<void> checkAndCelebrate(String trackId) async {
    stageCalls++;
  }

  @override
  Future<void> checkAndCelebrateTrackCompletion(String trackId) async {
    final tree = library.getTrack(trackId)?.tree;
    if (tree == null) return;
    final completed = progress.completedNodeIds.value;
    final completedStages = evaluator.getCompletedStages(tree, completed);
    final totalStages = tree.nodes.values.map((n) => n.level).toSet().length;
    if (completedStages.length < totalStages) return;
    trackCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('markCompleted persists and reports completion', () async {
    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.resetForTest();

    expect(await tracker.isCompleted('n1'), isFalse);
    await tracker.markCompleted('n1');
    expect(await tracker.isCompleted('n1'), isTrue);
  });

  test('markTrackCompleted persists and reports completion', () async {
    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.resetForTest();

    expect(await tracker.isTrackCompleted('T1'), isFalse);
    await tracker.markTrackCompleted('T1');
    expect(await tracker.isTrackCompleted('T1'), isTrue);
  });

  test('completedNodeIds notifies on updates', () async {
    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.resetForTest();

    final changes = <Set<String>>[];
    tracker.completedNodeIds.addListener(() {
      changes.add(tracker.completedNodeIds.value);
    });

    await tracker.markCompleted('a');
    await tracker.markCompleted('b');

    expect(changes.length, 2);
    expect(changes.last.contains('b'), isTrue);
  });

  test('triggers stage celebration after node completion', () async {
    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.resetForTest();

    final nodeA = SkillTreeNodeModel(
      id: 'a',
      title: 'A',
      category: 'T',
      level: 0,
    );
    final nodeB = SkillTreeNodeModel(
      id: 'b',
      title: 'B',
      category: 'T',
      level: 1,
    );
    const builder = SkillTreeBuilderService();
    final build = builder.build([nodeA, nodeB]);
    final lib = _FakeLibraryService({'T': build}, [nodeA, nodeB]);

    final originalResolver = SkillTreeTrackResolver.instance;
    SkillTreeTrackResolver.instance = SkillTreeTrackResolver(library: lib);

    final originalSvc = StageCompletionCelebrationService.instance;
    final recorder = _RecordingCelebrationService(
      library: lib,
      progress: tracker,
    );
    StageCompletionCelebrationService.instance = recorder;

    await tracker.markCompleted('a');

    expect(recorder.stageCalls, 1);

    StageCompletionCelebrationService.instance = originalSvc;
    SkillTreeTrackResolver.instance = originalResolver;
  });

  test('triggers track celebration after last node completion', () async {
    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.resetForTest();

    final nodeA = SkillTreeNodeModel(
      id: 'a',
      title: 'A',
      category: 'T',
      level: 0,
    );
    final nodeB = SkillTreeNodeModel(
      id: 'b',
      title: 'B',
      category: 'T',
      level: 1,
    );
    const builder = SkillTreeBuilderService();
    final build = builder.build([nodeA, nodeB]);
    final lib = _FakeLibraryService({'T': build}, [nodeA, nodeB]);

    final originalResolver = SkillTreeTrackResolver.instance;
    SkillTreeTrackResolver.instance = SkillTreeTrackResolver(library: lib);

    final originalSvc = StageCompletionCelebrationService.instance;
    final recorder = _RecordingCelebrationService(
      library: lib,
      progress: tracker,
    );
    StageCompletionCelebrationService.instance = recorder;

    await tracker.markCompleted('a');
    expect(recorder.trackCalls, 0);

    await tracker.markCompleted('b');
    expect(recorder.trackCalls, 1);

    StageCompletionCelebrationService.instance = originalSvc;
    SkillTreeTrackResolver.instance = originalResolver;
  });
}
