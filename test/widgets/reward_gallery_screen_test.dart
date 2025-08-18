import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:poker_analyzer/screens/reward_gallery_screen.dart';

class _FakeSharePlatform extends SharePlatform {
  bool shared = false;
  @override
  Future<void> share(
    String? text, {
    String? subject,
    ShareOptions? sharePositionOrigin,
  }) async {
    shared = true;
  }

  @override
  Future<void> shareXFiles(
    List<XFile> files, {
    String? text,
    String? subject,
    ShareOptions? sharePositionOrigin,
  }) async {
    shared = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Share button shares reward', (tester) async {
    SharedPreferences.setMockInitialValues({'reward_granted_test': true});
    final share = _FakeSharePlatform();
    SharePlatform.instance = share;

    await tester.pumpWidget(const MaterialApp(home: RewardGalleryScreen()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.share), findsOneWidget);
    await tester.tap(find.byIcon(Icons.share));
    await tester.pumpAndSettle();
    expect(share.shared, true);
  });
}
