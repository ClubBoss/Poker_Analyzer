import 'dart:isolate';
import 'package:poker_analyzer/plugins/poker_stars_converter_plugin.dart';

void main(List<String> args, SendPort sendPort) {
  sendPort.send(PokerStarsConverterPlugin());
}
