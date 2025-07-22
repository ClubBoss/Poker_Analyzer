enum MistakeTagCluster {
  tightPreflopBtn('Too tight from BTN'),
  looseCallBlind('Leaky blind defense'),
  missedEvOpportunities('Missed EV opportunities'),
  aggressiveMistakes('Overly aggressive plays');

  final String label;
  const MistakeTagCluster(this.label);

  @override
  String toString() => label;
}
