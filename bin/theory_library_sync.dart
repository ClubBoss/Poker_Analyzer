import 'dart:io';

import 'package:args/args.dart';
import 'package:poker_analyzer/services/theory_pack_exporter_service.dart';
import 'package:poker_analyzer/services/theory_pack_importer_service.dart';
import 'package:poker_analyzer/services/theory_mini_lesson_library_service.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()..addFlag('help', abbr: 'h', negatable: false);
  final result = parser.parse(args);
  if (result['help'] as bool || result.rest.length < 2) {
    stdout
        .writeln('Usage: dart theory_library_sync.dart <export|import> <dir>');
    return;
  }

  final command = result.rest[0];
  final dir = result.rest[1];

  switch (command) {
    case 'export':
      await TheoryMiniLessonLibraryService.instance.loadFromDirs(const [
        'assets/mini_lessons',
        'assets/theory_mini_lessons',
        'assets/theory_lessons/level1',
        'assets/theory_lessons/level2',
        'assets/theory_lessons/level3',
      ]);
      final lessons = TheoryMiniLessonLibraryService.instance.lessons;
      final exporter = const TheoryPackExporterService();
      final files = await exporter.export(lessons, dir);
      stdout.writeln(
          'Exported ${lessons.length} lessons into ${files.length} files.');
      break;
    case 'import':
      final importer = const TheoryPackImporterService();
      final lessons = await importer.importLessons(dir);
      TheoryMiniLessonLibraryService.instance.register(lessons);
      stdout.writeln('Imported ${lessons.length} lessons.');
      break;
    default:
      stdout.writeln('Unknown command: $command');
  }
}
