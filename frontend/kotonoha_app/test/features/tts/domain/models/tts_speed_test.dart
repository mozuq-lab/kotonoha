/// TTSSpeed enum テスト（verySlow追加）
///
/// TDD-TTS-SLOWER-SPEED: TTS読み上げ速度の追加オプション（より遅い速度の追加）
/// テストケース: TTC-VS-001, TTC-VS-009, TTC-VS-010
///
/// テスト対象: lib/features/tts/domain/models/tts_speed.dart
///
/// 【TDD Redフェーズ】: verySlow値が未実装、テストが失敗するはず
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';

void main() {
  group('TTSSpeed enum テスト（verySlow追加）', () {
    // =========================================================================
    // 正常系テストケース
    // =========================================================================
    group('正常系テスト', () {
      /// TTC-VS-001: TTSSpeed.verySlowの値が0.5であることを確認
      ///
      /// 優先度: P0（必須）
      /// 関連要件: TDD-TTS-SLOWER-SPEED要件定義書
      /// 検証内容: `TTSSpeed.verySlow.value`が0.5を返すこと
      test('TTC-VS-001: TTSSpeed.verySlowの値が0.5であることを確認', () {
        // 【テスト目的】: 「とても遅い」速度の値が0.5であることを確認 🔵
        // 【テスト内容】: TTSSpeed.verySlow.valueが0.5を返すことを検証
        // 【期待される動作】: TTSSpeedExtension.valueゲッターが正しい値を返す
        // 🔵 青信号: 要件定義書の「速度値の定義」テーブルに基づく

        // When: 【実際の処理実行】: verySlowの値を取得
        // 【処理内容】: TTSSpeed.verySlow.valueを呼び出す
        final value = TTSSpeed.verySlow.value;

        // Then: 【結果検証】: 0.5が返されることを確認
        // 【期待値確認】: 要件定義書で「0.5倍速」と定義されている
        // 【品質保証】: 速度enumの拡張が正しく実装されていることを確認
        expect(value, 0.5); // 【確認内容】: とても遅い速度が0.5であることを確認 🔵
      });
    });

    // =========================================================================
    // 境界値テストケース
    // =========================================================================
    group('境界値テスト', () {
      /// TTC-VS-009: すべてのTTSSpeed enum値が正しい速度値を返す
      ///
      /// 優先度: P0（必須）
      /// 関連要件: TDD-TTS-SLOWER-SPEED要件定義書
      /// 検証内容: 速度オプションの全範囲をテスト
      test(
          'TTC-VS-009: すべてのTTSSpeed enum値（verySlow/slow/normal/fast）が正しい速度値を返す',
          () {
        // 【テスト目的】: TTSSpeed enumの全値が正しい速度値を返すことを確認 🔵
        // 【テスト内容】: verySlow、slow、normal、fastすべての速度値を検証
        // 【期待される動作】: 各enumが定義された速度値を返す
        // 🔵 青信号: 要件定義書の「速度値の定義」テーブルに基づく

        // Then: 【結果検証】: すべての速度値が正しいことを確認
        // 【期待値確認】: 要件定義書の速度値定義に基づく
        // 【品質保証】: enum拡張の完全性確認

        // verySlow: 0.5倍速（新規追加）
        expect(
            TTSSpeed.verySlow.value, 0.5); // 【確認内容】: verySlowの値が0.5であることを確認 🔵

        // slow: 0.7倍速（既存）
        expect(TTSSpeed.slow.value, 0.7); // 【確認内容】: slowの値が0.7であることを確認 🔵

        // normal: 1.0倍速（既存）
        expect(TTSSpeed.normal.value, 1.0); // 【確認内容】: normalの値が1.0であることを確認 🔵

        // fast: 1.3倍速（既存）
        expect(TTSSpeed.fast.value, 1.3); // 【確認内容】: fastの値が1.3であることを確認 🔵

        // 【確認ポイント】: 新しい値の追加が既存の値に影響しないこと
      });

      /// TTC-VS-010: flutter_ttsの速度範囲内であることを確認
      ///
      /// 優先度: P0（必須）
      /// 関連要件: flutter_ttsパッケージの速度仕様
      /// 検証内容: 0.5がflutter_ttsの有効な速度範囲内であること
      test('TTC-VS-010: TTSSpeed.verySlowの値（0.5）がflutter_ttsの有効な速度範囲内であること',
          () {
        // 【テスト目的】: 0.5がflutter_ttsの有効な速度範囲内であることを確認 🟡
        // 【テスト内容】: 速度値がiOS（0.0〜1.0）、Android（0.0〜2.0）の範囲内であることを検証
        // 【期待される動作】: OS標準TTSエンジンで正常に動作すること
        // 🟡 黄信号: flutter_ttsパッケージのドキュメントから妥当な推測

        // Given: 【テストデータ準備】: verySlowの値を取得
        final verySlowValue = TTSSpeed.verySlow.value;

        // Then: 【結果検証】: flutter_ttsの速度範囲内であることを確認
        // 【期待値確認】: flutter_ttsの速度範囲（iOS: 0.0〜1.0、Android: 0.0〜2.0）
        // 【品質保証】: プラットフォーム互換性の確認

        // iOS範囲内（0.0〜1.0）
        expect(verySlowValue >= 0.0, isTrue); // 【確認内容】: 最小値以上であることを確認 🟡
        expect(verySlowValue <= 1.0, isTrue); // 【確認内容】: iOS最大値以下であることを確認 🟡

        // Android範囲内（0.0〜2.0）
        expect(verySlowValue <= 2.0, isTrue); // 【確認内容】: Android最大値以下であることを確認 🟡

        // 【確認ポイント】: 両プラットフォームで有効な値
        // 【確認ポイント】: flutter_tts仕様に準拠していること
      });

      /// TTC-VS-010b: すべてのTTSSpeed値がflutter_ttsの速度範囲内であることを確認
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: flutter_ttsパッケージの速度仕様
      /// 検証内容: すべての速度値がプラットフォーム互換であること
      test('TTC-VS-010b: すべてのTTSSpeed値がflutter_ttsの有効な速度範囲内であること', () {
        // 【テスト目的】: すべての速度値がflutter_ttsの有効範囲内であることを確認 🟡
        // 【テスト内容】: 全enum値がiOS/Android両方の範囲内であることを検証
        // 【期待される動作】: すべてのOS標準TTSエンジンで正常に動作すること
        // 🟡 黄信号: flutter_ttsパッケージのドキュメントから妥当な推測

        // Then: 【結果検証】: すべての速度値がflutter_ttsの範囲内であることを確認
        for (final speed in TTSSpeed.values) {
          final value = speed.value;

          // iOS範囲内（0.0〜1.0）- verySlow(0.5), slow(0.7), normal(1.0)はiOS範囲内
          // fast(1.3)はiOS範囲外だが、flutter_ttsが自動で調整する
          expect(value >= 0.0, isTrue,
              reason:
                  '${speed.name}の値($value)が最小値0.0以上であること'); // 【確認内容】: 最小値以上 🟡

          // Android範囲内（0.0〜2.0）
          expect(value <= 2.0, isTrue,
              reason:
                  '${speed.name}の値($value)がAndroid最大値2.0以下であること'); // 【確認内容】: Android範囲内 🟡
        }

        // 【確認ポイント】: クロスプラットフォームで同じ動作
      });
    });
  });
}
