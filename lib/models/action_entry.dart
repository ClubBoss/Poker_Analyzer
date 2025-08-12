import 'package:json_annotation/json_annotation.dart';

part 'action_entry.g.dart';

@JsonSerializable()
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

  factory ActionEntry.fromJson(Map<String, dynamic> j) =>
      _$ActionEntryFromJson(j);
  Map<String, dynamic> toJson() => _$ActionEntryToJson(this);

  /// Creates a copy of this [ActionEntry].
  ActionEntry copy() => ActionEntry(
        street,
        playerIndex,
        action,
        amount: amount,
        generated: generated,
        manualEvaluation: manualEvaluation,
        customLabel: customLabel,
        timestamp: timestamp,
        potAfter: potAfter,
        potOdds: potOdds,
        equity: equity,
        ev: ev,
        icmEv: icmEv,
      );
}
