import 'dart:io';
import 'package:poker_analyzer/services/intro_theory_pack_generator.dart';

Future<void> main(List<String> args) async {
  final generator = const IntroTheoryPackGenerator();
  final count = await generator.generate();
  stdout.writeln('Generated $count intro theory packs');
}
