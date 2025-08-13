enum MistakeTag {
  overfoldBtn('BTN Overfold'),
  looseCallBb('Loose Call BB'),
  looseCallSb('Loose Call SB'),
  looseCallCo('Loose Call CO'),
  missedEvPush('Missed +EV Push'),
  missedEvCall('Missed +EV Call'),
  missedEvRaise('Missed +EV Raise'),
  overpush('Overly Loose Push'),
  overfoldShortStack('Short Stack Overfold');

  final String label;
  const MistakeTag(this.label);

  @override
  String toString() => label;
}
