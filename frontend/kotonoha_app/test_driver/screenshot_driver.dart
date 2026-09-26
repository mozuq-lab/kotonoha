/// ストア用スクリーンショットを撮るときの `flutter drive` のドライバー（ホスト側）
///
/// アプリ側の `binding.takeScreenshot(name)` で届いた画像を
/// `build/screenshots/<name>.png` に書く。使い方は
/// `integration_test/store/store_screenshots_test.dart` の先頭。
library;

import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
      onScreenshot: (name, bytes, [args]) async {
        final file = File('build/screenshots/$name.png');
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);
        return true;
      },
    );
