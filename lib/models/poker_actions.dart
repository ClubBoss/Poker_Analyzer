class PokerAction {
  final String label;
  final String value;
  final String icon;

  const PokerAction({
    required this.label,
    required this.value,
    required this.icon,
  });
}

const List<PokerAction> pokerActions = [
  PokerAction(label: 'Fold', value: 'fold', icon: '❌'),
  PokerAction(label: 'Call', value: 'call', icon: '📞'),
  PokerAction(label: 'Check', value: 'check', icon: '✅'),
  PokerAction(label: 'Bet', value: 'bet', icon: '💰'),
  PokerAction(label: 'Raise', value: 'raise', icon: '📈'),
];
