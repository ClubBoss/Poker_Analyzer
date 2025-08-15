import 'package:poker_analyzer/plugins/plugin.dart';
import 'package:poker_analyzer/services/service_registry.dart';
import 'package:poker_analyzer/services/push_fold_ev_service.dart';
import 'package:poker_analyzer/services/icm_push_ev_service.dart';
import 'package:poker_analyzer/helpers/hand_utils.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/plugins/service_extension.dart';

class LocalEvService {
  const LocalEvService();

  Future<void> evaluate(TrainingPackSpot spot, {int anteBb = 0}) async {
    final hero = spot.hand.heroIndex;
    final hand = handCode(spot.hand.heroCards);
    final stack = spot.hand.stacks['$hero']?.round();
    if (hand == null || stack == null) return;
    final acts = spot.hand.actions[0];
    if (acts != null) {
      for (var i = 0; i < acts.length; i++) {
        final a = acts[i];
        if (a.playerIndex == hero &&
            (a.action == 'push' || a.action == 'call' || a.action == 'raise')) {
          acts[i] = a.copyWith(
            ev: computePushEV(
              heroBbStack: stack,
              bbCount: spot.hand.playerCount - 1,
              heroHand: hand,
              anteBb: anteBb,
            ),
          );
          break;
        }
      }
    }
  }

  Future<void> evaluateIcm(TrainingPackSpot spot,
      {int anteBb = 0, List<double> payouts = const [0.5, 0.3, 0.2]}) async {
    final hero = spot.hand.heroIndex;
    final hand = handCode(spot.hand.heroCards);
    final stack = spot.hand.stacks['$hero']?.round();
    if (hand == null || stack == null) return;
    final stacks = [
      for (var i = 0; i < spot.hand.playerCount; i++)
        spot.hand.stacks['$i']?.round() ?? 0
    ];
    final callers = [
      for (final a in spot.hand.actions[0] ?? [])
        if (a.playerIndex != hero && a.action == 'call') a.playerIndex
    ];
    final acts = spot.hand.actions[0];
    if (acts != null) {
      for (var i = 0; i < acts.length; i++) {
        final a = acts[i];
        if (a.playerIndex == hero &&
            (a.action == 'push' || a.action == 'call' || a.action == 'raise')) {
          final ev = computePushEV(
            heroBbStack: stack,
            bbCount: spot.hand.playerCount - 1,
            heroHand: hand,
            anteBb: anteBb,
          );
          final icm = callers.length > 1
              ? computeMultiwayIcmEV(
                  chipStacksBb: stacks,
                  heroIndex: hero,
                  chipPushEv: ev,
                  callerIndices: callers,
                  payouts: payouts,
                )
              : computeLocalIcmPushEV(
                  chipStacksBb: stacks,
                  heroIndex: hero,
                  heroHand: hand,
                  anteBb: anteBb,
                  payouts: payouts,
                );
          acts[i] = a.copyWith(ev: ev, icmEv: icm);
          break;
        }
      }
    }
  }
}

class LocalEvPlugin implements Plugin {
  @override
  void register(ServiceRegistry registry) {
    registry.registerIfAbsent<LocalEvService>(const LocalEvService());
  }

  @override
  void unregister(ServiceRegistry registry) {}

  @override
  List<ServiceExtension<dynamic>> get extensions => const [];

  @override
  String get name => 'Local EV';

  @override
  String get description => 'Local EV evaluation';

  @override
  String get version => '1.0.0';
}
