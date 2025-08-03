/// Utilities for working with poker streets.
///
/// Provides a constant list of street names and a helper to map
/// numeric indices to those names.
library poker_street_helper;

import 'package:intl/intl.dart';

/// Street name list ordered from preflop to river.
const kStreetNames = ['Preflop', 'Flop', 'Turn', 'River'];

/// Returns the localized street name for [index].
///
/// Values outside the valid range are clamped.
String streetName(int index) {
  switch (index.clamp(0, kStreetNames.length - 1)) {
    case 0:
      return Intl.message('Preflop', name: 'street_preflop');
    case 1:
      return Intl.message('Flop', name: 'street_flop');
    case 2:
      return Intl.message('Turn', name: 'street_turn');
    default:
      return Intl.message('River', name: 'street_river');
  }
}
