/// E2E テストドライバー
///
/// integration_testパッケージを使用したE2Eテストの実行エントリーポイント
///
/// 使用方法:
/// ```bash
/// flutter test integration_test/
/// ```
///
/// 特定のデバイスで実行:
/// ```bash
/// flutter test integration_test/ -d <device_id>
/// ```
library;

import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
}
