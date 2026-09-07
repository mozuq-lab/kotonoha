/// E2E テスト用バインディング初期化ヘルパー（実機・シミュレーター向け）
/// 注意このファイルは `flutter drive --driver=` に渡すドライバーではない。
/// web向けのドライバーは `test_driver/integration_test.dart`（パッケージルート直下）
/// にあり、そちらは `integrationDriver` を呼ぶ。
/// 本ファイルはアプリ側VMで実行される `ensureInitialized` のみを持つ。
/// ファイル名が紛らわしいため混同しないこと。
/// なお `*_test.dart` に一致しないため、CIのターゲット走査対象にはならない。
/// 使用方法（実機・シミュレーター）
/// ```bash
/// flutter test integration_test/ -d <device_id>
/// ```
library;

import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
}
