class ActionEntry {
  /// Улица действия. 0 = Preflop, 1 = Flop, 2 = Turn, 3 = River
  final int street;

  /// Индекс игрока, совершившего действие
  final int playerIndex;

  /// Тип действия: fold, call, bet, raise, check и т.д.
  final String action;

  /// Размер ставки в фишках, если применимо
  final int? amount;

  /// Флаг, указывающий, что запись сгенерирована автоматически
  final bool generated;

  /// Время, когда было совершено действие
  final DateTime timestamp;

  /// Создает запись о действии игрока на определенной улице.
  /// [amount] заполняется только для действий bet, raise или call.
  /// [generated] помечает автоматически добавленные действия.
  ActionEntry(this.street, this.playerIndex, this.action,
      {this.amount, this.generated = false, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}
