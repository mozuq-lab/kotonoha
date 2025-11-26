/// app_providers.dart エクスポートテスト
///
/// TASK-0057: Riverpod Provider 構造設計
/// TC-057-034 〜 TC-057-038
///
/// 関連要件:
/// - Provider一覧エクスポート（アーキテクチャ設計）
library;

import 'package:flutter_test/flutter_test.dart';

// app_providers.dart から全Providerをインポート
import 'package:kotonoha_app/shared/providers/app_providers.dart';

void main() {
  group('app_providers.dart エクスポートテスト', () {
    // =========================================================================
    // エクスポートテスト
    // =========================================================================

    group('エクスポートテスト', () {
      test('TC-057-034: inputBufferProviderがエクスポートされる', () {
        // Assert - インポートが成功していればProviderが存在する
        expect(inputBufferProvider, isNotNull);
      });

      test('TC-057-035: presetPhraseNotifierProviderがエクスポートされる', () {
        // Assert - インポートが成功していればProviderが存在する
        expect(presetPhraseNotifierProvider, isNotNull);
      });

      test('TC-057-036: historyProviderがエクスポートされる', () {
        // Assert - インポートが成功していればProviderが存在する
        expect(historyProvider, isNotNull);
      });

      test('TC-057-037: favoriteProviderがエクスポートされる', () {
        // Assert - インポートが成功していればProviderが存在する
        expect(favoriteProvider, isNotNull);
      });

      test('TC-057-038: networkProviderがエクスポートされる', () {
        // Assert - インポートが成功していればProviderが存在する
        expect(networkProvider, isNotNull);
      });
    });
  });
}
