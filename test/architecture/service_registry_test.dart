import 'package:test/test.dart';
import 'package:poker_analyzer/services/service_registry.dart';

void main() {
  group('ServiceRegistry', () {
    test('registers and retrieves a service', () {
      final registry = ServiceRegistry();
      registry.register<String>('hello');
      expect(registry.get<String>(), 'hello');
    });

    test('throws on duplicate registration', () {
      final registry = ServiceRegistry();
      registry.register<int>(1);
      expect(() => registry.register<int>(2), throwsStateError);
    });

    test('throws when service missing', () {
      final registry = ServiceRegistry();
      expect(() => registry.get<double>(), throwsStateError);
    });

    test('child registry falls back to parent', () {
      final parent = ServiceRegistry();
      parent.register<String>('parent');
      final child = parent.createChild();
      expect(child.get<String>(), 'parent');
      child.register<int>(42);
      expect(child.get<int>(), 42);
      expect(() => parent.get<int>(), throwsStateError);
    });

    test('dump and dumpAll report correct types', () {
      final parent = ServiceRegistry();
      parent.register<String>('parent');
      final child = parent.createChild();
      child.register<int>(42);

      expect(parent.dump(), <Type>[String]);
      expect(parent.dumpAll(), <Type>[String]);

      expect(child.dump(), <Type>[int]);
      expect(child.dumpAll(), containsAll(<Type>[String, int]));
    });
  });
}
