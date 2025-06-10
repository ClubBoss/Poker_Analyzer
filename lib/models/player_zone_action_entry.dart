class ActionEntry {
  final String playerName;
  final String street;
  final String action;
  final int? amount;

  ActionEntry({
    required this.playerName,
    required this.street,
    required this.action,
    this.amount,
  });
}
