import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poker_analyzer/services/banner_queue_service.dart';

MaterialBanner _banner(String text) {
  return MaterialBanner(
    content: Text(text),
    actions: [TextButton(onPressed: () {}, child: const Text('OK'))],
  );
}

void main() {
  testWidgets('displays banners sequentially with auto dismiss', (
    tester,
  ) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: key, home: const Scaffold()),
    );

    final service = BannerQueueService.instance;
    service.navigatorKey = key;
    service.queue(_banner('first'));
    service.queue(_banner('second'));
    service.queue(_banner('third'));

    await tester.pump();
    expect(find.text('first'), findsOneWidget);
    expect(find.text('second'), findsNothing);
    expect(find.text('third'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);
    expect(find.text('third'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('second'), findsNothing);
    expect(find.text('third'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('third'), findsNothing);
  });

  testWidgets('dismissCurrent skips to next banner immediately', (
    tester,
  ) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: key, home: const Scaffold()),
    );

    final service = BannerQueueService.instance;
    service.navigatorKey = key;
    service.queue(_banner('one'));
    service.queue(_banner('two'));

    await tester.pump();
    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsNothing);

    service.dismissCurrent();
    await tester.pump();
    expect(find.text('one'), findsNothing);
    expect(find.text('two'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
