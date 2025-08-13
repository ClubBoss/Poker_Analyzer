import 'package:poker_analyzer/plugins/converters/ipoker_hand_history_converter.dart';
import 'package:poker_analyzer/plugins/plugin.dart';
import 'package:poker_analyzer/plugins/converter_registry.dart';
import 'package:poker_analyzer/services/service_registry.dart';

class IpokerConverterPlugin extends IpokerHandHistoryConverter
    implements Plugin {
  @override
  void register(ServiceRegistry registry) {
    registry.registerIfAbsent<ConverterRegistry>(ConverterRegistry());
    registry.get<ConverterRegistry>().register(this);
  }

  @override
  String get name => 'iPoker Converter';

  @override
  String get description => 'Adds iPoker hand history conversion';

  @override
  String get version => '1.0.0';
}
