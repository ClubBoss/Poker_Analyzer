enum PokerStreet { preflop, flop, turn, river }

String pokerStreetToString(PokerStreet street) {
  switch (street) {
    case PokerStreet.preflop:
      return 'Preflop';
    case PokerStreet.flop:
      return 'Flop';
    case PokerStreet.turn:
      return 'Turn';
    case PokerStreet.river:
      return 'River';
  }
}

PokerStreet pokerStreetFromString(String street) {
  switch (street.toLowerCase()) {
    case 'preflop':
      return PokerStreet.preflop;
    case 'flop':
      return PokerStreet.flop;
    case 'turn':
      return PokerStreet.turn;
    case 'river':
      return PokerStreet.river;
    default:
      return PokerStreet.preflop;
  }
}
