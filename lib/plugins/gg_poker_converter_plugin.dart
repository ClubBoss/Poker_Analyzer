import 'package:poker_analyzer/plugins/converters/ggpoker_hand_history_converter.dart';
import 'package:poker_analyzer/plugins/plugin.dart';
import 'package:poker_analyzer/plugins/converter_registry.dart';
import 'package:poker_analyzer/services/service_registry.dart';

class GGPokerConverterPlugin extends GGPokerHandHistoryConverter
    implements Plugin {
  @override
  void register(ServiceRegistry registry) {
    registry.registerIfAbsent<ConverterRegistry>(ConverterRegistry());
    registry.get<ConverterRegistry>().register(this);
  }

  @override
  String get name => 'GGPoker Converter';

  @override
  String get description => 'Adds GGPoker hand history conversion';

  @override
  String get version => '1.0.0';
}
