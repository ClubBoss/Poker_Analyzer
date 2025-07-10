import '../models/card_model.dart';
import '../models/hand_analysis_record.dart';
import '../helpers/hand_utils.dart';
import 'push_fold_ev_service.dart';

class HandAnalyzerService {
  const HandAnalyzerService();

  HandAnalysisRecord? analyzePush({
    required List<CardModel> cards,
    required int stack,
    required int playerCount,
    required int heroIndex,
    int anteBb = 0,
  }) {
    if (cards.length < 2) return null;
    final code = handCode('${cards[0].rank}${cards[0].suit} ${cards[1].rank}${cards[1].suit}');
    if (code == null) return null;
    final ev = computePushEV(heroBbStack: stack, bbCount: playerCount - 1, heroHand: code, anteBb: anteBb);
    final stacks = List<int>.filled(playerCount, stack);
    final icm = computeIcmPushEV(chipStacksBb: stacks, heroIndex: heroIndex, heroHand: code, chipPushEv: ev);
    final action = ev >= 0 ? 'push' : 'fold';
    return HandAnalysisRecord(
      card1: '${cards[0].rank}${cards[0].suit}',
      card2: '${cards[1].rank}${cards[1].suit}',
      stack: stack,
      playerCount: playerCount,
      heroIndex: heroIndex,
      ev: ev,
      icm: icm,
      action: action,
    );
  }
}
