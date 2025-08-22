import '../models/mistake_tag.dart';
import '../models/mistake_tag_cluster.dart';

final Map<MistakeTag, MistakeTagCluster> _clusterMap = {
  MistakeTag.overfoldBtn: MistakeTagCluster.tightPreflopBtn,
  MistakeTag.looseCallBb: MistakeTagCluster.looseCallBlind,
  MistakeTag.looseCallSb: MistakeTagCluster.looseCallBlind,
  MistakeTag.looseCallCo: MistakeTagCluster.looseCallBlind,
  MistakeTag.missedEvPush: MistakeTagCluster.missedEvOpportunities,
  MistakeTag.missedEvCall: MistakeTagCluster.missedEvOpportunities,
  MistakeTag.missedEvRaise: MistakeTagCluster.missedEvOpportunities,
  MistakeTag.overpush: MistakeTagCluster.aggressiveMistakes,
  MistakeTag.overfoldShortStack: MistakeTagCluster.tightPreflopBtn,
};

class MistakeTagClusterService {
  MistakeTagClusterService();

  MistakeTagCluster getClusterForTag(MistakeTag tag) {
    return _clusterMap[tag] ?? MistakeTagCluster.aggressiveMistakes;
  }
}
