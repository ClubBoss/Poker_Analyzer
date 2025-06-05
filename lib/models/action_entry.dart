class ActionEntry {
  final int playerIndex; // 0 = "Вы", остальные — "Игрок 1", "Игрок 2" и т.д.
  final String action;   // например: "raise", "call", "check", "fold", "bet"
  final String size;     // например: "3bb", "50%", "pot"

  ActionEntry({
    required this.playerIndex,
    required this.action,
    required this.size,
  });
}