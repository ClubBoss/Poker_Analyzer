/// Returns the list of position names for a given number of players.
///
/// The list is ordered from UTG to BB and supports tables with 2 to 9 players.
/// Throws an [ArgumentError] if the provided [playerCount] is outside this range.
List<String> getPositionList(int playerCount) {
  if (playerCount < 2 || playerCount > 9) {
    throw ArgumentError('Supported range: 2 to 9 players');
  }

  final Map<int, List<String>> positionsByCount = {
    2: ['SB', 'BB'],
    3: ['BTN', 'SB', 'BB'],
    4: ['CO', 'BTN', 'SB', 'BB'],
    5: ['MP', 'CO', 'BTN', 'SB', 'BB'],
    6: ['UTG', 'HJ', 'CO', 'BTN', 'SB', 'BB'],
    7: ['UTG', 'MP', 'HJ', 'CO', 'BTN', 'SB', 'BB'],
    8: ['UTG', 'UTG+1', 'MP', 'HJ', 'CO', 'BTN', 'SB', 'BB'],
    9: ['UTG', 'UTG+1', 'UTG+2', 'MP', 'HJ', 'CO', 'BTN', 'SB', 'BB'],
  };

  return positionsByCount[playerCount]!;
}
