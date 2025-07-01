class ActionEntry {
  /// Улица действия. 0 = Preflop, 1 = Flop, 2 = Turn, 3 = River
  final int street;

  /// Индекс игрока, совершившего действие
  final int playerIndex;

  /// Тип действия: fold, call, bet, raise, check и т.д.
  final String action;

  /// Размер ставки в фишках, если применимо
  final double? amount;

  /// Флаг, указывающий, что запись сгенерирована автоматически
  final bool generated;

  /// Пользовательская оценка качества действия, заданная вручную
  String? manualEvaluation;

  /// Пользовательская метка действия при типе 'custom'
  String? customLabel;

  /// Размер банка после применения действия
  double potAfter;

  double? potOdds;

  double? equity;

  double? ev;

  double? icmEv;

  /// Время, когда было совершено действие
  final DateTime timestamp;

  /// Создает запись о действии игрока на определенной улице.
  /// [amount] заполняется только для действий bet, raise или call.
  /// [generated] помечает автоматически добавленные действия.
  ActionEntry(this.street, this.playerIndex, this.action,
      {this.amount,
      this.generated = false,
      this.manualEvaluation,
      this.customLabel,
      DateTime? timestamp,
      this.potAfter = 0,
      this.potOdds,
      this.equity,
      this.ev,
      this.icmEv})
      : timestamp = timestamp ?? DateTime.now();

  factory ActionEntry.fromJson(Map<String, dynamic> j) => ActionEntry(
        j['street'] as int? ?? 0,
        j['playerIndex'] as int? ?? 0,
        j['action'] as String? ?? '',
        amount: (j['amount'] as num?)?.toDouble(),
        generated: j['generated'] as bool? ?? false,
        manualEvaluation: j['manualEvaluation'] as String?,
        customLabel: j['customLabel'] as String?,
        timestamp:
            DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now(),
        potAfter: (j['potAfter'] as num?)?.toDouble() ?? 0,
        potOdds: (j['potOdds'] as num?)?.toDouble(),
        equity: (j['equity'] as num?)?.toDouble(),
        ev: (j['ev'] as num?)?.toDouble(),
        icmEv: (j['icmEv'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'street': street,
        'playerIndex': playerIndex,
        'action': action,
        if (amount != null) 'amount': amount,
        'generated': generated,
        'timestamp': timestamp.toIso8601String(),
        if (manualEvaluation != null) 'manualEvaluation': manualEvaluation,
        if (customLabel != null) 'customLabel': customLabel,
        'potAfter': potAfter,
        if (potOdds != null) 'potOdds': potOdds,
        if (equity != null) 'equity': equity,
        if (ev != null) 'ev': ev,
        if (icmEv != null) 'icmEv': icmEv,
      };
}
