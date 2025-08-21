import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/training_pack_search_service.dart';
import 'package:poker_analyzer/services/training_pack_search_index_builder.dart';
import 'package:poker_analyzer/models/v2/pack_ux_metadata.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/core/training/library/training_pack_library_v2.dart';
import 'package:poker_analyzer/models/game_type.dart';

class _FakeBuilder extends TrainingPackSearchIndexBuilder {
  List<TrainingPackTemplateV2>? lastBuilt;
  Map<String, dynamic>? lastQuery;
  int buildCount = 0;

  @override
  void build(List<TrainingPackTemplateV2> packs) {
    buildCount++;
    lastBuilt = packs;
  }

  @override
  List<TrainingPackTemplateV2> query({
    TrainingPackLevel? level,
    TrainingPackTopic? topic,
    List<String>? tags,
    TrainingPackFormat? format,
    TrainingPackComplexity? complexity,
  }) {
    lastQuery = {
      'level': level,
      'topic': topic,
      'tags': tags,
      'format': format,
      'complexity': complexity,
    };
    return const [];
  }
}

class _FakeLibrary implements TrainingPackLibraryV2 {
  final List<TrainingPackTemplateV2> _packs;
  _FakeLibrary(this._packs);

  @override
  List<TrainingPackTemplateV2> get packs => _packs;

  @override
  void addPack(TrainingPackTemplateV2 pack) => _packs.add(pack);

  @override
  void clear() => _packs.clear();

  @override
  List<TrainingPackTemplateV2> filterBy({
    GameType? gameType,
    TrainingType? type,
    List<String>? tags,
  }) =>
      throw UnimplementedError();

  @override
  TrainingPackTemplateV2? getById(String id) => _packs.firstWhere(
        (p) => p.id == id,
        orElse: () => throw UnimplementedError(),
      );

  @override
  Future<void> loadFromFolder([
    String path = TrainingPackLibraryV2.packsDir,
  ]) async {}

  @override
  Future<void> reload() async {}
}

TrainingPackTemplateV2 _pack(String id) {
  return TrainingPackTemplateV2(
    id: id,
    name: id,
    trainingType: TrainingType.postflop,
    gameType: GameType.tournament,
    tags: const ['tag'],
    meta: {
      'level': TrainingPackLevel.beginner.name,
      'topic': TrainingPackTopic.postflop.name,
      'format': TrainingPackFormat.tournament.name,
      'complexity': TrainingPackComplexity.simple.name,
    },
  );
}

void main() {
  test('delegates query and rebuilds on library change', () {
    final builder = _FakeBuilder();
    final controller = StreamController<void>.broadcast(sync: true);
    final library = _FakeLibrary([_pack('p1')]);
    final service = TrainingPackSearchService(
      library: library,
      indexBuilder: builder,
      libraryChanges: controller.stream,
    );

    service.init();
    expect(builder.buildCount, 1);
    expect(builder.lastBuilt, library.packs);

    service.query(
      level: TrainingPackLevel.beginner,
      topic: TrainingPackTopic.postflop,
      tags: const ['x'],
      format: TrainingPackFormat.tournament,
      complexity: TrainingPackComplexity.simple,
    );
    expect(builder.lastQuery, {
      'level': TrainingPackLevel.beginner,
      'topic': TrainingPackTopic.postflop,
      'tags': const ['x'],
      'format': TrainingPackFormat.tournament,
      'complexity': TrainingPackComplexity.simple,
    });

    library.addPack(_pack('p2'));
    controller.add(null);

    expect(builder.buildCount, 2);
    expect(builder.lastBuilt, library.packs);

    controller.close();
  });
}
