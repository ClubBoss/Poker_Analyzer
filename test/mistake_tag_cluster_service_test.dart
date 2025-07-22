import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/mistake_tag_cluster_service.dart';
import 'package:poker_analyzer/models/mistake_tag.dart';
import 'package:poker_analyzer/models/mistake_tag_cluster.dart';

void main() {
  const service = MistakeTagClusterService();

  test('maps tags to clusters correctly', () {
    expect(
      service.getClusterForTag(MistakeTag.overfoldBtn),
      MistakeTagCluster.tightPreflopBtn,
    );
    expect(
      service.getClusterForTag(MistakeTag.looseCallBb),
      MistakeTagCluster.looseCallBlind,
    );
    expect(
      service.getClusterForTag(MistakeTag.missedEvPush),
      MistakeTagCluster.missedEvOpportunities,
    );
    expect(
      service.getClusterForTag(MistakeTag.overpush),
      MistakeTagCluster.aggressiveMistakes,
    );
  });
}
