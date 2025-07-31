enum MemoryReminderType { decayBooster, brokenStreak, upcomingReview }

class MemoryReminder {
  final MemoryReminderType type;
  final int priority;
  final String? packId;

  const MemoryReminder({
    required this.type,
    required this.priority,
    this.packId,
  });
}
