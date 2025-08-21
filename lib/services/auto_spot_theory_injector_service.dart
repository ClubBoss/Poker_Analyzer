import '../models/v2/training_pack_spot.dart';
import 'inline_theory_linker.dart';

/// Automatically attaches an [InlineTheoryLink] to [TrainingPackSpot]s
/// based on their existing theory tags.
class AutoSpotTheoryInjectorService {
  AutoSpotTheoryInjectorService({InlineTheoryLinker? linker})
      : _linker = linker ?? InlineTheoryLinker();

  final InlineTheoryLinker _linker;

  /// Attaches a matching [InlineTheoryLink] to [spot] if available.
  ///
  /// The method mutates [spot] in place and returns it for convenience.
  TrainingPackSpot inject(TrainingPackSpot spot) {
    spot.theoryLink = _linker.getLink(spot.tags);
    return spot;
  }

  /// Convenience method to inject links for multiple [spots].
  void injectAll(Iterable<TrainingPackSpot> spots) {
    for (final s in spots) {
      inject(s);
    }
  }
}
