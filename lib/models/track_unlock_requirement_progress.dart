class TrackUnlockRequirementProgress {
  final String label;
  final String icon;
  final int current;
  final int required;
  final bool met;

  const TrackUnlockRequirementProgress({
    required this.label,
    required this.icon,
    required this.current,
    required this.required,
    required this.met,
  });
}
