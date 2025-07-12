import 'dart:io';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/cloud_sync_service.dart';

class _PathProvider extends PathProviderPlatform {
  _PathProvider(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('save and load local value', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _PathProvider(dir.path);
    SharedPreferences.setMockInitialValues({});
    final service = CloudSyncService(
      firestore: FakeFirebaseFirestore(),
      auth: MockFirebaseAuth(mockUser: MockUser(uid: 'u')),
    );
    await service.init();
    await service.save('k', 'v');
    final v = await service.load('k');
    expect(v, 'v');
  });
}
