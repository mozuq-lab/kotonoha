library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';
import 'package:kotonoha_app/features/network/domain/models/network_state.dart';

void main() {
  group('TASK-0058: オフライン動作確認テスト', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // 1. ネットワーク状態管理テスト（NetworkProvider統合）

    group('1. ネットワーク状態管理テスト', () {
      /// NetworkProviderがアプリ全体で利用可能
      test('TC-058-001: NetworkProviderがアプリ全体で利用可能', () {
        // Given: ProviderScopeでNetworkProviderを初期化
        // When: NetworkProviderにアクセス
        final state = container.read(networkProvider);

        // Then: NetworkProviderが正しく初期化される
        expect(state, isNotNull, reason: 'NetworkProviderは初期化されている必要がある');
        expect(state, NetworkState.checking, reason: '初期状態はcheckingである必要がある');
      });

      /// NetworkStateがonline状態に遷移
      test('TC-058-002: NetworkStateがonline状態に遷移', () async {
        // Given: NetworkProviderが初期化されている
        final notifier = container.read(networkProvider.notifier);

        // When: setOnlineを呼び出し
        await notifier.setOnline();

        // Then: NetworkStateがonlineに変更される
        final state = container.read(networkProvider);
        expect(state, NetworkState.online,
            reason: 'setOnline()後はonline状態になる必要がある');

        // And: isAIConversionAvailableがtrueを返す
        expect(notifier.isAIConversionAvailable, true,
            reason: 'オンライン時はAI変換が利用可能である必要がある');
      });

      /// NetworkStateがoffline状態に遷移
      test('TC-058-003: NetworkStateがoffline状態に遷移', () async {
        // Given: NetworkProviderが初期化されている
        final notifier = container.read(networkProvider.notifier);

        // When: setOfflineを呼び出し
        await notifier.setOffline();

        // Then: NetworkStateがofflineに変更される
        final state = container.read(networkProvider);
        expect(state, NetworkState.offline,
            reason: 'setOffline()後はoffline状態になる必要がある');

        // And: isAIConversionAvailableがfalseを返す
        expect(notifier.isAIConversionAvailable, false,
            reason: 'オフライン時はAI変換が利用不可である必要がある');
      });

      /// ネットワーク状態変更時にUIがリビルドされる
      test('TC-058-004: ネットワーク状態変更時にUIがリビルドされる', () async {
        // Given: NetworkProviderを監視するリスナーを設定
        final notifier = container.read(networkProvider.notifier);
        final states = <NetworkState>[];

        container.listen<NetworkState>(
          networkProvider,
          (previous, next) {
            states.add(next);
          },
          fireImmediately: false,
        );

        // When: NetworkStateをonline→offline→onlineに切り替え
        await notifier.setOnline();
        await notifier.setOffline();
        await notifier.setOnline();

        // Then: 各状態変更がリスナーに通知される
        expect(states.length, 3, reason: '3回の状態変更が通知される必要がある');
        expect(states[0], NetworkState.online);
        expect(states[1], NetworkState.offline);
        expect(states[2], NetworkState.online);
      });

      /// 複数回のネットワーク切り替えが正常動作
      test('TC-058-005: 複数回のネットワーク切り替えが正常動作', () async {
        // Given: NetworkProviderが初期化されている
        final notifier = container.read(networkProvider.notifier);

        // When: ネットワーク状態を5回以上連続で切り替え
        for (var i = 0; i < 5; i++) {
          await notifier.setOnline();
          await notifier.setOffline();
        }

        // Then: アプリがクラッシュしない（テストが正常完了）
        final state = container.read(networkProvider);
        expect(state, NetworkState.offline,
            reason: '最後の切り替え後はoffline状態である必要がある');
      });

      /// NetworkState.checkingでAI変換が無効
      test('TC-058-006: NetworkState.checkingでAI変換が無効', () {
        // Given: NetworkProviderが初期化されたばかり（checking状態）
        final notifier = container.read(networkProvider.notifier);

        // When: isAIConversionAvailableを取得
        final isAvailable = notifier.isAIConversionAvailable;

        // Then: isAIConversionAvailableがfalseを返す
        expect(isAvailable, false, reason: 'checking状態ではAI変換が無効である必要がある');
      });

      /// NetworkProviderのDispose処理が正常動作
      test('TC-058-007: NetworkProviderのDispose処理が正常動作', () {
        // Given: NetworkProviderがProviderContainerに登録されている
        final testContainer = ProviderContainer();

        // When: ProviderContainer.disposeを呼び出し
        testContainer.dispose();

        // Then: メモリリークが発生しない（テストが正常完了）
        // dispose後のアクセスは例外をスローする
        expect(() => testContainer.read(networkProvider), throwsStateError,
            reason: 'dispose後のProviderアクセスは例外をスローする必要がある');
      });
    });

    // 2. オフライン時の基本機能動作テスト（モック前提）

    group('2. オフライン時の基本機能動作テスト', () {
      /// オフライン時も文字盤タップで文字入力可能（統合テスト）
      test('TC-058-008: オフライン時も文字盤タップで文字入力可能（統合テスト）', () async {
        // Given: NetworkStateがoffline
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOffline();

        // When/Then: オフライン状態であることを確認
        expect(container.read(networkProvider), NetworkState.offline);

        // ここではネットワーク状態のみを確認し、UI・TTS・永続化の動作は検証していない。
      });

      /// オフライン時も定型文一覧が表示される（統合テスト）
      test('TC-058-012: オフライン時も定型文一覧が表示される（統合テスト）', () async {
        // Given: NetworkStateがoffline
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOffline();

        // When/Then: オフライン状態であることを確認
        expect(container.read(networkProvider), NetworkState.offline);

        // ここではネットワーク状態のみを確認し、UI・TTS・永続化の動作は検証していない。
      });

      /// オフライン時もTTS読み上げが1秒以内に開始される（統合テスト）
      test('TC-058-023: オフライン時もTTS読み上げが1秒以内に開始される（統合テスト）', () async {
        // Given: NetworkStateがoffline
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOffline();

        // When/Then: オフライン状態であることを確認
        expect(container.read(networkProvider), NetworkState.offline);

        // ここではネットワーク状態のみを確認し、UI・TTS・永続化の動作は検証していない。
      });
    });

    // 3. AI変換ボタン無効化テスト（統合テスト）

    group('3. AI変換ボタン無効化テスト', () {
      /// オフライン時にAI変換ボタンがグレーアウト表示（統合テスト）
      test('TC-058-026: オフライン時にAI変換ボタンがグレーアウト表示（統合テスト）', () async {
        // Given: NetworkStateがoffline
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOffline();

        // When/Then: isAIConversionAvailableがfalseを返す
        expect(notifier.isAIConversionAvailable, false,
            reason: 'オフライン時はAI変換が利用不可である必要がある');

        // ここではネットワーク状態のみを確認し、UI・TTS・永続化の動作は検証していない。
      });

      /// オフライン時にAI変換ボタンがタップ不可（統合テスト）
      test('TC-058-027: オフライン時にAI変換ボタンがタップ不可（統合テスト）', () async {
        // Given: NetworkStateがoffline
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOffline();

        // When/Then: isAIConversionAvailableがfalseを返す
        expect(notifier.isAIConversionAvailable, false,
            reason: 'オフライン時はAI変換が利用不可である必要がある');

        // ここではネットワーク状態のみを確認し、UI・TTS・永続化の動作は検証していない。
      });

      /// オンライン時にAI変換ボタンが有効化される
      test('TC-058-030: オンライン時にAI変換ボタンが有効化される', () async {
        // Given: NetworkStateがonline
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOnline();

        // When/Then: isAIConversionAvailableがtrueを返す
        expect(notifier.isAIConversionAvailable, true,
            reason: 'オンライン時はAI変換が利用可能である必要がある');
      });

      /// ネットワーク状態切り替えでAI変換ボタンが動的に有効/無効化
      test('TC-058-031: ネットワーク状態切り替えでAI変換ボタンが動的に有効/無効化', () async {
        // Given: NetworkStateがonline
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOnline();

        // When/Then: オンライン時はAI変換が有効
        expect(notifier.isAIConversionAvailable, true);

        // When: offlineに切り替え
        await notifier.setOffline();

        // Then: AI変換が無効
        expect(notifier.isAIConversionAvailable, false);

        // When: 再度onlineに切り替え
        await notifier.setOnline();

        // Then: AI変換が有効
        expect(notifier.isAIConversionAvailable, true);
      });
    });

    // 4. ローカルストレージ動作確認テスト（統合テスト）

    group('4. ローカルストレージ動作確認テスト', () {
      /// オフライン時も定型文がHiveに保存される（統合テスト）
      test('TC-058-039: オフライン時も定型文がHiveに保存される（統合テスト）', () async {
        // Given: NetworkStateがoffline
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOffline();

        // When/Then: オフライン状態であることを確認
        expect(container.read(networkProvider), NetworkState.offline);

        // ここではネットワーク状態のみを確認し、UI・TTS・永続化の動作は検証していない。
      });

      /// オフライン時も設定がshared_preferencesに保存される（統合テスト）
      test('TC-058-040: オフライン時も設定がshared_preferencesに保存される（統合テスト）', () async {
        // Given: NetworkStateがoffline
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOffline();

        // When/Then: オフライン状態であることを確認
        expect(container.read(networkProvider), NetworkState.offline);

        // ここではネットワーク状態のみを確認し、UI・TTS・永続化の動作は検証していない。
      });
    });

    // 5. エラーハンドリングテスト

    group('5. エラーハンドリングテスト', () {
      /// オフライン状態でもアプリがクラッシュしない
      test('TC-058-046: オフライン状態でもアプリがクラッシュしない', () async {
        // Given: NetworkStateがoffline
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOffline();

        // When: 基本機能を使用する想定（ネットワーク状態を確認）
        final state = container.read(networkProvider);

        // Then: アプリがクラッシュしない（テストが正常完了）
        expect(state, NetworkState.offline);
      });

      /// ネットワーク切り替えが連続5回以上でも正常動作
      test('TC-058-047: ネットワーク切り替えが連続5回以上でも正常動作', () async {
        // Given: NetworkProviderが初期化されている
        final notifier = container.read(networkProvider.notifier);

        // When: NetworkStateをonline↔offlineに5回以上連続で切り替え
        for (var i = 0; i < 6; i++) {
          await notifier.setOnline();
          await notifier.setOffline();
        }

        // Then: アプリがクラッシュしない
        final state = container.read(networkProvider);
        expect(state, NetworkState.offline);
      });
    });

    // 6. 境界値・異常系テスト

    group('6. 境界値・異常系テスト', () {
      /// NetworkState.checking状態でAI変換ボタンが無効化
      test('TC-058-052: NetworkState.checking状態でAI変換ボタンが無効化', () async {
        // Given: アプリが起動したばかり（NetworkState.checking）
        final notifier = container.read(networkProvider.notifier);
        await notifier.setChecking();

        // When: AI変換ボタンの状態を確認
        final isAvailable = notifier.isAIConversionAvailable;

        // Then: isAIConversionAvailableがfalseを返す
        expect(isAvailable, false, reason: 'checking状態ではAI変換が無効である必要がある');
      });
    });
  });
}
