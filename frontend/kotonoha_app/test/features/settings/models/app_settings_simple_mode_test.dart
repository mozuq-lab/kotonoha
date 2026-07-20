/// AppSettings モデルテスト（シンプルモード）
///
/// fix/improvement-p0-p2: シンプルモード（疲労時・症状進行時の簡易画面）
///
/// テスト対象: lib/features/settings/models/app_settings.dart の simpleMode フィールド
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/settings/models/app_settings.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';

void main() {
  group('AppSettings - シンプルモード', () {
    test('デフォルト値はfalse（通常モード）である', () {
      const settings = AppSettings();

      expect(settings.simpleMode, isFalse);
    });

    test('copyWithでsimpleModeのみを変更し、他のフィールドは保持される', () {
      const original = AppSettings(fontSize: FontSize.large, simpleMode: false);

      final updated = original.copyWith(simpleMode: true);

      expect(updated.simpleMode, isTrue);
      expect(updated.fontSize, FontSize.large);
    });

    test('toJson()でsimple_modeキーとしてシリアライズされる', () {
      const settings = AppSettings(simpleMode: true);

      final json = settings.toJson();

      expect(json['simple_mode'], isTrue);
    });

    test('fromJson()でsimple_modeキーからデシリアライズされる', () {
      final json = {'simple_mode': true};

      final settings = AppSettings.fromJson(json);

      expect(settings.simpleMode, isTrue);
    });

    test('fromJson()でsimple_modeキーが存在しない場合はfalseにフォールバックする', () {
      final json = <String, dynamic>{};

      final settings = AppSettings.fromJson(json);

      expect(settings.simpleMode, isFalse);
    });
  });
}
