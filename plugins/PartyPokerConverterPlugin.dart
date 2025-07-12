import 'dart:isolate';
import 'package:poker_analyzer/plugins/partypoker_converter_plugin.dart';

void main(List<String> args, SendPort sendPort) {
  sendPort.send(PartyPokerConverterPlugin());
}
