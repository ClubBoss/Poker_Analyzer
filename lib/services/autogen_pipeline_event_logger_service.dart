class AutogenPipelineEvent {
  final String type;
  final String message;
  final DateTime timestamp;

  const AutogenPipelineEvent({
    required this.type,
    required this.message,
    required this.timestamp,
  });
}

/// Simple in-memory logger for autogen pipeline events.
class AutogenPipelineEventLoggerService {
  AutogenPipelineEventLoggerService._();

  static final List<AutogenPipelineEvent> _events = [];

  /// Adds an event to the log.
  static void log(String type, String message) {
    _events.add(
      AutogenPipelineEvent(
        type: type,
        message: message,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Returns an immutable view of all logged events.
  static List<AutogenPipelineEvent> getLog() => List.unmodifiable(_events);

  /// Clears all logged events.
  static void clearLog() => _events.clear();
}

