class ActionEntry {
  /// Улица действия. 0 = Preflop, 1 = Flop, 2 = Turn, 3 = River
  final int street;

  /// Индекс игрока, совершившего действие
  final int playerIndex;

  /// Тип действия: fold, call, bet, raise, check и т.д.
  final String action;

  /// Размер ставки в фишках, если применимо
  final int? amount;

  ActionEntry({
    required this.street,
    required this.playerIndex,
    required this.action,
    this.amount,
  });
}