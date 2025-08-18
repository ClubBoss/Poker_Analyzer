import 'package:flutter/material.dart';

enum BoosterLessonStatus { newLesson, inProgress, repeated, skipped }

extension BoosterLessonStatusText on BoosterLessonStatus {
  String get label {
    switch (this) {
      case BoosterLessonStatus.newLesson:
        return 'New';
      case BoosterLessonStatus.inProgress:
        return 'In Progress';
      case BoosterLessonStatus.repeated:
        return 'Repeated';
      case BoosterLessonStatus.skipped:
        return 'Skipped';
    }
  }

  Color get color {
    switch (this) {
      case BoosterLessonStatus.newLesson:
        return Colors.blueAccent;
      case BoosterLessonStatus.inProgress:
        return Colors.orangeAccent;
      case BoosterLessonStatus.repeated:
        return Colors.greenAccent;
      case BoosterLessonStatus.skipped:
        return Colors.grey;
    }
  }
}
