import 'package:test/test.dart';
import 'package:poker_analyzer/plugins/plugin_manager.dart';
import 'package:poker_analyzer/plugins/service_extension.dart';
import 'package:poker_analyzer/plugins/plugin.dart';
import 'package:poker_analyzer/services/service_registry.dart';

class _IntExtension extends ServiceExtension<int> {
  @override
  int create(ServiceRegistry registry) => 42;
}

class _PluginA implements Plugin {
  int registerCount = 0;

  @override
  void register(ServiceRegistry registry) {
    registerCount++;
    registry.register<String>('hello');
  }

  @override
  List<ServiceExtension<dynamic>> get extensions => <ServiceExtension<dynamic>>[
        _IntExtension(),
      ];

  @override
  String get name => 'A';

  @override
  String get description => '';

  @override
  String get version => '1.0.0';
}

class _PluginB implements Plugin {
  int registerCount = 0;

  @override
  void register(ServiceRegistry registry) {
    registerCount++;
    registry.register<bool>(true);
  }

  @override
  String get name => 'B';

  @override
  String get description => '';

  @override
  String get version => '1.0.0';
}

void main() {
  group('PluginManager', () {
    test('services are not registered until initialization', () {
      final manager = PluginManager();
      final registry = ServiceRegistry();
      final plugin = _PluginA();
      manager.load(plugin);

      expect(() => registry.get<String>(), throwsStateError);
      expect(plugin.registerCount, 0);
    });

    test('initializeAll registers services and extensions', () {
      final manager = PluginManager();
      final registry = ServiceRegistry();
      final pluginA = _PluginA();
      final pluginB = _PluginB();
      manager.load(pluginA);
      manager.load(pluginB);

      manager.initializeAll(registry);

      expect(pluginA.registerCount, 1);
      expect(pluginB.registerCount, 1);
      expect(registry.get<String>(), 'hello');
      expect(registry.get<int>(), 42);
      expect(registry.get<bool>(), true);
    });
  });
}
