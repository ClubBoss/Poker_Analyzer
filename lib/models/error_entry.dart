class ErrorEntry {
  final String spotTitle;
  final String situationDescription;
  final String userAction;
  final String correctAction;
  final String aiExplanation;

  ErrorEntry({
    required this.spotTitle,
    required this.situationDescription,
    required this.userAction,
    required this.correctAction,
    required this.aiExplanation,
  });
}
