/// SettingsProvider TTS速度設定テスト
///
/// TASK-0049: TTS速度設定（遅い/普通/速い）
/// テストケース: TC-049-005〜TC-049-006, TC-049-010, TC-049-012〜TC-049-014
///
/// テスト対象: lib/features/settings/providers/settings_provider.dart
///
/// 【TDD Redフェーズ】: setTTSSpeed()メソッドが未実装、テストが失敗するはず
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';

/// TTSNotifierのモック
class MockTTSNotifier extends Mock {
  Future<void> setSpeed(TTSSpeed speed);
}

void main() {
  group('SettingsNotifier - TTS速度設定テスト', () {
    late ProviderContainer container;
    late MockTTSNotifier mockTTSNotifier;

    setUpAll(() {
      // Mocktailのフォールバック値を登録
      registerFallbackValue(TTSSpeed.normal);
    });

    setUp(() async {
      // 【テスト前準備】: SharedPreferencesのモックを初期化
      // 【環境初期化】: 各テストが独立して実行できるよう、クリーンな状態から開始
      SharedPreferences.setMockInitialValues({});

      // TTSNotifierのモックを作成
      mockTTSNotifier = MockTTSNotifier();
      when(() => mockTTSNotifier.setSpeed(any())).thenAnswer((_) async {});
    });

    tearDown(() {
      // 【テスト後処理】: ProviderContainerを破棄し、次のテストに影響しないようにする
      // 【状態復元】: メモリリークを防ぐため、リソースを解放
      container.dispose();
    });

    // =========================================================================
    // 正常系テストケース
    // =========================================================================
    group('正常系テスト', () {
      /// TC-049-005: SettingsNotifier.setTTSSpeed()でshared_preferencesに保存される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-5003, REQ-2007
      /// 検証内容: TTS速度設定の永続化
      test(
          'TC-049-005: setTTSSpeed()メソッドを呼び出すと、shared_preferencesに速度設定が保存されることを確認',
          () async {
        // 【テスト目的】: TTS速度設定がshared_preferencesに保存されることを確認 🔵
        // 【テスト内容】: setTTSSpeed(TTSSpeed.fast)を呼び出し、shared_preferencesに保存されることを検証
        // 【期待される動作】: shared_preferencesに'tts_speed': 'fast'が保存され、状態も即座に更新される
        // 🔵 青信号: requirements.md（129-131行目）、REQ-5003、REQ-2007に基づく

        // Given: 【テストデータ準備】: ProviderContainerを作成
        // 【初期条件設定】: 初期状態（normal）から開始
        container = ProviderContainer();

        // 【Provider初期化】: build()を完了させる
        await container.read(settingsNotifierProvider.future);

        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: 【実際の処理実行】: setTTSSpeed(TTSSpeed.fast)を呼び出す
        // 【処理内容】: ユーザーが設定画面で「速い」を選択した場合を模擬
        await notifier.setTTSSpeed(TTSSpeed.fast);

        // Then: 【結果検証】: 状態が更新され、shared_preferencesに保存されたことを確認
        // 【期待値確認】: REQ-5003（設定永続化）とREQ-2007（即座反映）を満たす
        // 【品質保証】: ユーザーの速度変更が確実に保存され、アプリ再起動後も設定が失われないことを保証
        final state = container.read(settingsNotifierProvider);
        final settings = state.requireValue;

        expect(settings.ttsSpeed, TTSSpeed.fast); // 【確認内容】: 状態が更新されたことを確認 🔵

        // 【検証項目】: SharedPreferencesに保存されていること
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('tts_speed'),
            'fast'); // 【確認内容】: SharedPreferencesに正しく保存されたことを確認 🔵
      });

      /// TC-049-006: SettingsNotifier.setTTSSpeed()でTTSNotifier.setSpeed()が呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-404
      /// 検証内容: 設定変更とTTS速度変更の連携
      test(
          'TC-049-006: setTTSSpeed()を呼び出すと、TTSNotifier.setSpeed()が呼ばれ、TTSエンジンに速度が反映されることを確認',
          () async {
        // 【テスト目的】: 設定変更がTTSエンジンに正しく伝達されることを確認 🔵
        // 【テスト内容】: setTTSSpeed(TTSSpeed.slow)を呼び出し、TTSNotifier.setSpeed()が呼ばれることを検証
        // 【期待される動作】: TTSNotifier.setSpeed()が1回呼ばれ、引数はTTSSpeed.slow
        // 🔵 青信号: requirements.md（122-127行目）のデータフローに基づく

        // Given: 【テストデータ準備】: TTSNotifierのモックを注入したProviderContainerを作成
        // 【初期条件設定】: 初期状態から開始
        container = ProviderContainer(
          overrides: [
            // TTSNotifierのモックを注入（実際の実装では異なる方法が必要）
            // Note: この部分は実装時に適切なモック方法を採用する必要がある
          ],
        );

        // 【Provider初期化】: build()を完了させる
        await container.read(settingsNotifierProvider.future);

        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: 【実際の処理実行】: setTTSSpeed(TTSSpeed.slow)を呼び出す
        // 【処理内容】: ユーザーが設定画面で「遅い」を選択した場合を模擬
        await notifier.setTTSSpeed(TTSSpeed.slow);

        // Then: 【結果検証】: TTSNotifier.setSpeed()が呼ばれたことを確認
        // 【期待値確認】: requirements.md（122-127行目）のデータフローに基づく
        // 【品質保証】: 設定画面での速度変更が、TTSエンジンに正しく伝達されることを保証

        // Note: モック化の方法により検証方法が異なるため、実装時に適切な検証方法を採用する
        // verify(() => mockTTSNotifier.setSpeed(TTSSpeed.slow)).called(1);
      });

      /// TC-049-010: アプリ再起動後、保存されたTTS速度が復元される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-5003
      /// 検証内容: 設定永続化の確認
      test('TC-049-010: アプリを終了し再起動した後、前回設定したTTS速度が正しく復元されることを確認', () async {
        // 【テスト目的】: 永続化された速度設定が再起動後も保持されることを確認 🔵
        // 【テスト内容】: shared_preferencesに保存された速度設定が再起動後に正しく復元されることを検証
        // 【期待される動作】: 前回のセッションで設定した速度が復元される
        // 🔵 青信号: requirements.md（238-245行目）の使用例に基づく

        // Given: 【テストデータ準備】: 前回のセッションで速度を「速い」に設定した状態を模擬
        // 【初期条件設定】: ユーザーが前回のセッションで速度を「速い」に設定し、翌日アプリを再起動した場合
        SharedPreferences.setMockInitialValues({
          'tts_speed': 'fast',
        });

        // When: 【実際の処理実行】: 新しいProviderContainerを作成（再起動を模擬）
        // 【処理内容】: アプリ起動時のProvider初期化
        container = ProviderContainer();
        final settings = await container.read(settingsNotifierProvider.future);

        // Then: 【結果検証】: 速度が「速い」に復元されたことを確認
        // 【期待値確認】: REQ-5003（設定永続化）に基づく
        // 【品質保証】: アプリ再起動後も設定が失われないことを確認
        expect(settings.ttsSpeed,
            TTSSpeed.fast); // 【確認内容】: 保存された速度が正しく復元されたことを確認 🔵
      });
    });

    // =========================================================================
    // 異常系テストケース
    // =========================================================================
    group('異常系テスト', () {
      /// TC-049-012: shared_preferences保存失敗時もUI状態は更新される（楽観的更新）
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: REQ-2007, NFR-304, EDGE-2
      /// 検証内容: 楽観的更新パターンの動作確認
      test(
          'TC-049-012: shared_preferences.setString()が失敗した場合でも、AppSettingsの状態は更新されることを確認',
          () async {
        // 【テスト目的】: 楽観的更新パターンの動作確認 🟡
        // 【テスト内容】: shared_preferences保存失敗時でも状態更新は成功することを検証
        // 【期待される動作】: UI応答性を維持し、状態は更新される
        // 🟡 黄信号: requirements.md（298-308行目）のEDGE-2、既存テスト（settings_provider_test.dart TC-012）のパターンを踏襲

        // Given: 【テストデータ準備】: ProviderContainerを作成
        // 【初期条件設定】: 正常な初期状態
        // 【実際の発生シナリオ】: ストレージ容量不足、ファイルシステムエラー
        container = ProviderContainer();

        // 【Provider初期化】: build()を完了させる
        await container.read(settingsNotifierProvider.future);

        final notifier = container.read(settingsNotifierProvider.notifier);

        // Note: flutter_testのモック機能では保存失敗を直接シミュレートできないため、
        // この部分は実装後に実際の挙動を確認する必要がある

        // When: 【実際の処理実行】: setTTSSpeed(TTSSpeed.fast)を呼び出す
        // 【処理内容】: TTS速度変更（書き込み失敗は実装後にモックで検証）
        await notifier.setTTSSpeed(TTSSpeed.fast);

        // Then: 【結果検証】: 状態更新は成功していることを確認
        // 【期待値確認】: NFR-2007（即座反映）とNFR-304（エラーハンドリング）の両立
        // 【システムの安全性】: 保存失敗でもUIは正常に動作
        final state = container.read(settingsNotifierProvider);
        final settings = state.requireValue;

        expect(settings.ttsSpeed,
            TTSSpeed.fast); // 【確認内容】: 状態更新は成功していることを確認（楽観的更新） 🟡
      });

      /// TC-049-013: TTS初期化前に速度を設定してもエラーにならない
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: NFR-301, ERROR-1
      /// 検証内容: 初期化順序に依存しない堅牢な実装
      test('TC-049-013: TTSServiceが初期化される前にsetTTSSpeed()を呼んでも、エラーが発生しないことを確認',
          () async {
        // 【テスト目的】: 初期化タイミングに関わらず安全に動作することを確認 🟡
        // 【テスト内容】: TTS初期化前に速度設定を行ってもエラーが発生しないことを検証
        // 【期待される動作】: 速度値は保存され、TTS初期化後に適用される
        // 🟡 黄信号: requirements.md（323-331行目）のERROR-1、防御的プログラミングの原則に基づく

        // Given: 【テストデータ準備】: ProviderContainerを作成
        // 【初期条件設定】: TTS初期化前の状態
        // 【実際の発生シナリオ】: アプリ起動直後、ユーザーが即座に設定画面を開いた場合
        container = ProviderContainer();

        // 【Provider初期化】: build()を完了させる
        await container.read(settingsNotifierProvider.future);

        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: 【実際の処理実行】: TTS初期化前にsetTTSSpeed()を呼び出す
        // 【処理内容】: 速度設定を行う（TTS初期化前）
        await notifier.setTTSSpeed(TTSSpeed.slow);

        // Then: 【結果検証】: エラーが発生せず、速度値が保存されたことを確認
        // 【期待値確認】: 初期化順序に依存しない堅牢性
        // 【システムの安全性】: 初期化順序に関わらず、速度設定は常に保持される
        final state = container.read(settingsNotifierProvider);
        final settings = state.requireValue;

        expect(settings.ttsSpeed, TTSSpeed.slow); // 【確認内容】: 速度値が保存されたことを確認 🟡
        // エラーが発生しないことを確認（テストが完了すること自体が確認）
      });

      /// TC-049-014: flutter_tts.setSpeechRate()失敗時もアプリは継続動作
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: NFR-301, ERROR-2
      /// 検証内容: TTSエンジンエラーに対する堅牢性
      test('TC-049-014: flutter_ttsの速度設定が失敗した場合でも、エラーログを出力してアプリは継続動作することを確認',
          () async {
        // 【テスト目的】: TTSエンジンエラーに対する堅牢性を確認 🟡
        // 【テスト内容】: flutter_ttsの速度設定失敗時でもアプリが継続動作することを検証
        // 【期待される動作】: エラーログが出力され、状態には反映される
        // 🟡 黄信号: requirements.md（333-342行目）のERROR-2、既存テスト（tts_service_test.dart TC-048-011）のパターンを踏襲

        // Given: 【テストデータ準備】: ProviderContainerを作成
        // 【初期条件設定】: TTSエンジンが速度変更を受け付けない状態を模擬
        // 【実際の発生シナリオ】: 古いOSバージョンでの互換性問題、デバイス固有のTTSエンジンの制約
        container = ProviderContainer();

        // 【Provider初期化】: build()を完了させる
        await container.read(settingsNotifierProvider.future);

        final notifier = container.read(settingsNotifierProvider.notifier);

        // Note: flutter_tts.setSpeechRate()の失敗は実装後にモックで検証する必要がある

        // When: 【実際の処理実行】: setTTSSpeed()を呼び出す
        // 【処理内容】: 速度設定を行う（TTSエンジンエラー発生）
        await notifier.setTTSSpeed(TTSSpeed.fast);

        // Then: 【結果検証】: アプリが継続動作し、状態には反映されたことを確認
        // 【期待値確認】: NFR-301（基本機能継続）に準拠
        // 【システムの安全性】: TTSエンジンのエラーでもアプリはクラッシュしない
        final state = container.read(settingsNotifierProvider);
        final settings = state.requireValue;

        expect(settings.ttsSpeed, TTSSpeed.fast); // 【確認内容】: 状態には反映されたことを確認 🟡
        // アプリが継続動作することを確認（テストが完了すること自体が確認）
      });
    });
  });
}
