enum MistakeTag {
  overfoldBtn('BTN Overfold'),
  looseCallBb('Loose Call BB'),
  missedEvPush('Missed +EV Push'),
  overpush('Overly Loose Push'),
  overfoldShortStack('Short Stack Overfold');

  final String label;
  const MistakeTag(this.label);

  @override
  String toString() => label;
}

