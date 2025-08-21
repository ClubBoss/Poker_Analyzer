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
  final String? manualEvaluation;

  /// Пользовательская метка действия при типе 'custom'
  final String? customLabel;

  /// Размер банка после применения действия
  final double potAfter;

  final double? potOdds;

  final double? equity;

  final double? ev;

  final double? icmEv;

  /// Время, когда было совершено действие
  final DateTime timestamp;

  /// Создает запись о действии игрока на определенной улице.
  /// [amount] заполняется только для действий bet, raise или call.
  /// [generated] помечает автоматически добавленные действия.
  ActionEntry(
    this.street,
    this.playerIndex,
    this.action, {
    this.amount,
    this.generated = false,
    this.manualEvaluation,
    this.customLabel,
    DateTime? timestamp,
    this.potAfter = 0,
    this.potOdds,
    this.equity,
    this.ev,
    this.icmEv,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ActionEntry.fromJson(Map<String, dynamic> j) =>
      _$ActionEntryFromJson(j);
  Map<String, dynamic> toJson() => _$ActionEntryToJson(this);

  /// Creates a copy of this [ActionEntry].
  ActionEntry copy() => copyWith();

  /// Returns a copy of this [ActionEntry] with the given fields replaced.
  ActionEntry copyWith({
    int? street,
    int? playerIndex,
    String? action,
    double? amount,
    bool? generated,
    String? manualEvaluation,
    String? customLabel,
    DateTime? timestamp,
    double? potAfter,
    double? potOdds,
    double? equity,
    double? ev,
    double? icmEv,
  }) =>
      ActionEntry(
        street ?? this.street,
        playerIndex ?? this.playerIndex,
        action ?? this.action,
        amount: amount ?? this.amount,
        generated: generated ?? this.generated,
        manualEvaluation: manualEvaluation ?? this.manualEvaluation,
        customLabel: customLabel ?? this.customLabel,
        timestamp: timestamp ?? this.timestamp,
        potAfter: potAfter ?? this.potAfter,
        potOdds: potOdds ?? this.potOdds,
        equity: equity ?? this.equity,
        ev: ev ?? this.ev,
        icmEv: icmEv ?? this.icmEv,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActionEntry &&
        other.street == street &&
        other.playerIndex == playerIndex &&
        other.action == action &&
        other.amount == amount &&
        other.generated == generated &&
        other.manualEvaluation == manualEvaluation &&
        other.customLabel == customLabel &&
        other.potAfter == potAfter &&
        other.potOdds == potOdds &&
        other.equity == equity &&
        other.ev == ev &&
        other.icmEv == icmEv &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(
        street,
        playerIndex,
        action,
        amount,
        generated,
        manualEvaluation,
        customLabel,
        potAfter,
        potOdds,
        equity,
        ev,
        icmEv,
        timestamp,
      );
}
