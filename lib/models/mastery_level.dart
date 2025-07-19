enum MasteryLevel { beginner, intermediate, expert }

extension MasteryLevelLabel on MasteryLevel {
  String get label {
    switch (this) {
      case MasteryLevel.beginner:
        return 'Новичок';
      case MasteryLevel.intermediate:
        return 'Продвинутый';
      case MasteryLevel.expert:
        return 'Эксперт';
    }
  }
}
