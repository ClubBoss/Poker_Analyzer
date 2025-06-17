import 'package:test/test.dart';
import 'package:poker_ai_analyzer/services/service_registry.dart';

class _DummyService {
  const _DummyService();
}

void main() {
  late ServiceRegistry registry;

  setUp(() {
    registry = ServiceRegistry();
  });

  test('register and retrieve service', () {
    const service = _DummyService();
    registry.register<_DummyService>(service);
    final retrieved = registry.get<_DummyService>();
    expect(retrieved, same(service));
  });

  test('missing service throws', () {
    expect(() => registry.get<_DummyService>(), throwsStateError);
  });

  test('duplicate registration throws', () {
    registry.register<_DummyService>(const _DummyService());
    expect(
      () => registry.register<_DummyService>(const _DummyService()),
      throwsStateError,
    );
  });

  test('child registry falls back to parent', () {
    const service = _DummyService();
    registry.register<_DummyService>(service);
    final child = registry.createChild();
    final retrieved = child.get<_DummyService>();
    expect(retrieved, same(service));
  });

  test('dump and dumpAll diagnostics', () {
    registry.register<_DummyService>(const _DummyService());
    final child = registry.createChild();
    child.register<Object>(Object());

    expect(registry.dump(), contains(_DummyService));
    expect(registry.dumpAll(), contains(_DummyService));

    expect(child.dump(), contains(Object));
    expect(child.dumpAll(), containsAll(<Type>[_DummyService, Object]));
  });
}
