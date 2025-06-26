enum GameType { tournament, cash }

extension GameTypeLabel on GameType {
  String get label => this == GameType.tournament ? 'Tournament' : 'Cash Game';
}
