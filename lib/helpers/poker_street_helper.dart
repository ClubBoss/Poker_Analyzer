/// Utilities for working with poker streets.
///
/// Provides a constant list of street names and a helper to map
/// numeric indices to those names.
library poker_street_helper;

/// Street name list ordered from preflop to river.
const kStreetNames = ['Preflop', 'Flop', 'Turn', 'River'];

/// Returns the street name for [index].
///
/// Values outside the valid range are clamped.
String streetName(int index) {
  return kStreetNames[index.clamp(0, kStreetNames.length - 1)];
}
