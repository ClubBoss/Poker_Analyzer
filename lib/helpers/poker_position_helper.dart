/// Returns the list of position names for a given number of players.
///
/// The list is ordered from UTG to BB and supports tables with 2 to 10 players.
/// Throws an [ArgumentError] if the provided [playerCount] is outside this range.
List<String> getPositionList(int playerCount) {
  if (playerCount < 2 || playerCount > 10) {
    throw ArgumentError('Supported range: 2 to 10 players');
  }

  const Map<int, List<String>> positionsByCount = {
    2: const ['SB', 'BB'],
    3: const ['BTN', 'SB', 'BB'],
    4: const ['CO', 'BTN', 'SB', 'BB'],
    5: const ['MP', 'CO', 'BTN', 'SB', 'BB'],
    6: const ['UTG', 'HJ', 'CO', 'BTN', 'SB', 'BB'],
    7: const ['UTG', 'MP', 'HJ', 'CO', 'BTN', 'SB', 'BB'],
    8: const ['UTG', 'UTG+1', 'MP', 'HJ', 'CO', 'BTN', 'SB', 'BB'],
    9: const ['UTG', 'UTG+1', 'UTG+2', 'MP', 'HJ', 'CO', 'BTN', 'SB', 'BB'],
    10: const ['UTG', 'UTG+1', 'UTG+2', 'UTG+3', 'MP', 'HJ', 'CO', 'BTN', 'SB', 'BB'],
  };

  return positionsByCount[playerCount]!;
}
