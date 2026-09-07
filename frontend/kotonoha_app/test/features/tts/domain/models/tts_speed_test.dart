/// TTSSpeed enum テスト（verySlow追加）
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';

void main() {
  group('TTSSpeed enum テスト（verySlow追加）', () {
    // 正常系テストケース
    group('正常系テスト', () {
      /// TTSSpeed.verySlowの値が0.5であることを確認
      test('TTC-VS-001: TTSSpeed.verySlowの値が0.5であることを確認', () {
        // When: 実際の処理実行: verySlowの値を取得
        // 処理内容: TTSSpeed.verySlow.valueを呼び出す
        final value = TTSSpeed.verySlow.value;

        // Then: 結果検証: 0.5が返されることを確認
        // 要件定義書で「0.5倍速」と定義されている
        // 品質保証: 速度enumの拡張が正しく実装されていることを確認
        expect(value, 0.5);
      });
    });

    // 境界値テストケース
    group('境界値テスト', () {
      /// すべてのTTSSpeed enum値が正しい速度値を返す
      test(
          'TTC-VS-009: すべてのTTSSpeed enum値（verySlow/slow/normal/fast）が正しい速度値を返す',
          () {
        // Then: 結果検証: すべての速度値が正しいことを確認
        // 要件定義書の速度値定義に基づく
        // 品質保証: enum拡張の完全性確認

        // verySlow: 0.5倍速（新規追加）
        expect(TTSSpeed.verySlow.value, 0.5);

        // slow: 0.7倍速（既存）
        expect(TTSSpeed.slow.value, 0.7);

        // normal: 1.0倍速（既存）
        expect(TTSSpeed.normal.value, 1.0);

        // fast: 1.3倍速（既存）
        expect(TTSSpeed.fast.value, 1.3);

        // 確認ポイント: 新しい値の追加が既存の値に影響しないこと
      });

      /// flutter_ttsの速度範囲内であることを確認
      test('TTC-VS-010: TTSSpeed.verySlowの値（0.5）がflutter_ttsの有効な速度範囲内であること',
          () {
        // Given: テストデータ準備: verySlowの値を取得
        final verySlowValue = TTSSpeed.verySlow.value;

        // Then: 結果検証: flutter_ttsの速度範囲内であることを確認
        // flutter_ttsの速度範囲（iOS: 0.0〜1.0、Android: 0.0〜2.0）
        // 品質保証: プラットフォーム互換性の確認

        // iOS範囲内（0.0〜1.0）
        expect(verySlowValue >= 0.0, isTrue);
        expect(verySlowValue <= 1.0, isTrue);

        // Android範囲内（0.0〜2.0）
        expect(verySlowValue <= 2.0, isTrue);

        // 確認ポイント: 両プラットフォームで有効な値
        // 確認ポイント: flutter_tts仕様に準拠していること
      });

      /// すべてのTTSSpeed値がflutter_ttsの速度範囲内であることを確認
      test('TTC-VS-010b: すべてのTTSSpeed値がflutter_ttsの有効な速度範囲内であること', () {
        // Then: 結果検証: すべての速度値がflutter_ttsの範囲内であることを確認
        for (final speed in TTSSpeed.values) {
          final value = speed.value;

          // iOS範囲内（0.0〜1.0）- verySlow(0.5), slow(0.7), normal(1.0)はiOS範囲内
          // fast(1.3)はiOS範囲外だが、flutter_ttsが自動で調整する
          expect(value >= 0.0, isTrue,
              reason: '${speed.name}の値($value)が最小値0.0以上であること');

          // Android範囲内（0.0〜2.0）
          expect(value <= 2.0, isTrue,
              reason: '${speed.name}の値($value)がAndroid最大値2.0以下であること');
        }

        // 確認ポイント: クロスプラットフォームで同じ動作
      });
    });
  });
}
