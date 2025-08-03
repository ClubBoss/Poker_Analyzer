class ActionLine {
  final List<String> actions;
  final String street;
  final Set<String> tags;

  ActionLine({
    required this.actions,
    required this.street,
    Set<String>? tags,
  }) : tags = tags ?? {};
}
