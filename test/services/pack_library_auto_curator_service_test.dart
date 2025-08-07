import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/auto_deduplication_engine.dart';
import 'package:poker_analyzer/services/pack_library_auto_curator_service.dart';

class _NoopDedup extends AutoDeduplicationEngine {
  _NoopDedup() : super(log: IOSink(StreamController<List<int>>().sink));

  @override
  List<TrainingPackModel> deduplicate(List<TrainingPackModel> input) => input;
}

void main() {
  test('curate selects best pack per cluster and sorts by coverage', () {
    final curator = PackLibraryAutoCuratorService(dedup: _NoopDedup());

    TrainingPackModel pack(
      String id, {
      List<TrainingPackSpot>? spots,
      List<String>? tags,
      Map<String, dynamic>? metadata,
    }) {
      return TrainingPackModel(
        id: id,
        title: id,
        spots: spots ?? const [],
        tags: tags,
        metadata: metadata,
      );
    }

    TrainingPackSpot spot(
      String id, {
      List<String>? tags,
      Map<String, dynamic>? meta,
    }) {
      return TrainingPackSpot(id: id, tags: tags, meta: meta);
    }

    final p1 = pack('p1', spots: [
      spot('s1', meta: {'clusterId': 'c1'}),
      spot('s2', meta: {'clusterId': 'c1'}),
    ], tags: ['a']);

    final p2 = pack('p2', spots: [
      spot('s3', meta: {'clusterId': 'c1'}),
      spot('s4', meta: {'clusterId': 'c1'}),
      spot('s5', meta: {'clusterId': 'c1'}),
    ], tags: ['a', 'b']);

    final p3 = pack('p3', spots: [
      spot('s6', meta: {'clusterId': 'c2'}),
    ], tags: ['c']);

    final p4 = pack('p4', spots: [
      spot('s7'),
      spot('s8'),
      spot('s9'),
      spot('s10'),
      spot('s11'),
    ], tags: ['d', 'e', 'f']);

    final p5 = pack('p5', spots: [
      spot('s12'),
      spot('s13'),
      spot('s14'),
    ], tags: ['x', 'y', 'z']);

    final result = curator.curate([p1, p2, p3, p4, p5], limit: 4);

    expect(result.map((p) => p.id).toList(), ['p4', 'p5', 'p2', 'p3']);
  });
}
