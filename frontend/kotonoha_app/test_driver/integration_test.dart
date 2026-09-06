/// flutter drive 用テストドライバー（ホストVM側エントリーポイント）
///
/// ファイル目的: `flutter drive --driver=` に渡すホスト側の起点
/// 実装方針: integration_test パッケージの `integrationDriver()` を呼び、
/// アプリ側VMで実行される `--target` のテスト結果を回収して終了コードへ反映する
///
/// 重要: ここで `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` を
/// 呼んではならない。それはアプリ側VM（`--target` 側）で呼ぶAPIであり、
/// driver側で呼ぶとテスト結果を回収せずに即終了し、CIが偽グリーンになる。
///
/// 使用方法（Web / ヘッドレスChrome）:
/// ```bash
/// flutter drive \
///   --driver=test_driver/integration_test.dart \
///   --target=integration_test/app_startup_test.dart \
///   -d web-server \
///   --browser-name=chrome \
///   --headless
/// ```
library;

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
