enum PlayerActionType { fold, check, call, bet, raise, allIn }

class PlayerActionModel {
  final PlayerActionType type;
  final double? size;

  PlayerActionModel({required this.type, this.size});
}
