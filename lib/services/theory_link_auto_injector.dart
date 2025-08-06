import '../models/v2/training_pack_spot.dart';
import 'auto_spot_theory_injector_service.dart';

/// Wraps [AutoSpotTheoryInjectorService] for pipeline usage.
class TheoryLinkAutoInjector {
  final AutoSpotTheoryInjectorService _injector;

  TheoryLinkAutoInjector({AutoSpotTheoryInjectorService? injector})
      : _injector = injector ?? AutoSpotTheoryInjectorService();

  /// Injects theory links into all [spots].
  void injectAll(Iterable<TrainingPackSpot> spots) {
    _injector.injectAll(spots);
  }
}

