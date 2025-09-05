import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

FutureOr<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Consistent binding; avoids extra setup cost per test.
  TestWidgetsFlutterBinding.ensureInitialized();
  await testMain();
}
