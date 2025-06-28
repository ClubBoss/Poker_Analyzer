class ErrorLogger {
  ErrorLogger._();
  static final ErrorLogger instance = ErrorLogger._();
  factory ErrorLogger() => instance;

  final List<String> recentErrors = [];

  void logError(String msg, [Object? error, StackTrace? stack]) {
    final timestamp = DateTime.now().toIso8601String();
    var entry = '$timestamp $msg';
    if (error != null) entry += ': $error';
    if (stack != null) entry += '\n$stack';
    recentErrors.add(entry);
    if (recentErrors.length > 100) {
      recentErrors.removeRange(0, recentErrors.length - 100);
    }
    print(entry);
  }
}
