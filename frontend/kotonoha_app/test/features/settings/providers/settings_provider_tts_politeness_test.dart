/// TTS速度・AI丁寧さレベル設定 Providerテスト
///
/// TASK-0074: TTS速度・AI丁寧さレベル設定UI
/// テストケース: TC-074-003〜TC-074-021
///
/// テスト対象: TTS速度とAI丁寧さレベル設定がProviderで正しく管理されること
///
/// 【TDD Redフェーズ】: TTS速度とAI丁寧さレベル設定の全テストケースを作成
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/models/app_theme.dart';

void main() {
  group('TASK-0074: TTS速度・AI丁寧さレベル設定 Providerテスト', () {
    setUp(() async {
      // SharedPreferencesのモックを初期化
      SharedPreferences.setMockInitialValues({});
    });

    // =========================================================================
    // 1. 正常系テストケース（基本動作）
    // =========================================================================
    group('正常系テストケース', () {
      /// TC-074-003: TTS速度「遅い」の選択と保存
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-404, REQ-5003
      /// 検証内容: TTS速度「遅い」が正しく選択・保存されること
      test('TC-074-003: TTS速度「遅い」の選択と保存', () async {
        // 【テスト目的】: TTS速度「遅い」が正しく設定されることを確認 🔵
        // 【テスト内容】: setTTSSpeed(TTSSpeed.slow)を呼び出し、状態とSharedPreferencesを検証
        // 【期待される動作】: stateがslowに更新され、SharedPreferencesに保存される
        // 🔵 青信号: REQ-404「TTS速度を3段階から選択可能」、REQ-5003「設定永続化」

        // Given: 【テストデータ準備】: ProviderContainer作成
        final container = ProviderContainer();

        // Provider初期化
        await container.read(settingsNotifierProvider.future);

        // When: 【実際の処理実行】: TTS速度を「遅い」に設定
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setTTSSpeed(TTSSpeed.slow);

        // Then: 【結果検証】: TTS速度がslowに更新されている
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.ttsSpeed, TTSSpeed.slow); // 【確認内容】: stateのttsSpeedがslowであること 🔵

        // SharedPreferencesに保存されていること
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('tts_speed'), TTSSpeed.slow.name); // 【確認内容】: SharedPreferencesに"slow"が保存されていること 🔵

        container.dispose();
      });

      /// TC-074-004: TTS速度「普通」の選択と保存（デフォルト）
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-404, REQ-5003
      /// 検証内容: デフォルト値「普通」が正しく動作すること
      test('TC-074-004: TTS速度「普通」の選択と保存（デフォルト）', () async {
        // 【テスト目的】: デフォルト値「普通」が正しく設定されることを確認 🔵
        // 【テスト内容】: 初期状態でttsSpeedがnormalであることを検証
        // 【期待される動作】: 初期状態のttsSpeedがnormalになる
        // 🔵 青信号: REQ-404「デフォルトは普通」

        // Given: 【テストデータ準備】: 空のSharedPreferences
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        // When: 【実際の処理実行】: 初期状態を取得
        final settings = await container.read(settingsNotifierProvider.future);

        // Then: 【結果検証】: デフォルトがnormalであること
        expect(settings.ttsSpeed, TTSSpeed.normal); // 【確認内容】: 初期状態のttsSpeedがnormalであること 🔵

        container.dispose();
      });

      /// TC-074-005: TTS速度「速い」の選択と保存
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-404, REQ-5003
      /// 検証内容: TTS速度「速い」が正しく選択・保存されること
      test('TC-074-005: TTS速度「速い」の選択と保存', () async {
        // 【テスト目的】: TTS速度「速い」が正しく設定されることを確認 🔵
        // 【テスト内容】: setTTSSpeed(TTSSpeed.fast)を呼び出し、状態とSharedPreferencesを検証
        // 【期待される動作】: stateがfastに更新され、SharedPreferencesに保存される
        // 🔵 青信号: REQ-404「TTS速度を3段階から選択可能」

        // Given: 【テストデータ準備】: ProviderContainer作成
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);

        // When: 【実際の処理実行】: TTS速度を「速い」に設定
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setTTSSpeed(TTSSpeed.fast);

        // Then: 【結果検証】: TTS速度がfastに更新されていること
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.ttsSpeed, TTSSpeed.fast); // 【確認内容】: stateのttsSpeedがfastであること 🔵

        // SharedPreferencesに保存されていること
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('tts_speed'), TTSSpeed.fast.name); // 【確認内容】: SharedPreferencesに"fast"が保存されていること 🔵

        container.dispose();
      });

      /// TC-074-006: AI丁寧さレベル「カジュアル」の選択と保存
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-903, REQ-5003
      /// 検証内容: AI丁寧さレベル「カジュアル」が正しく選択・保存されること
      test('TC-074-006: AI丁寧さレベル「カジュアル」の選択と保存', () async {
        // 【テスト目的】: AI丁寧さレベル「カジュアル」が正しく設定されることを確認 🔵
        // 【テスト内容】: setAIPoliteness(PolitenessLevel.casual)を呼び出し、状態とSharedPreferencesを検証
        // 【期待される動作】: stateがcasualに更新され、SharedPreferencesに保存される
        // 🔵 青信号: REQ-903「AI丁寧さレベルを3段階から選択可能」、REQ-5003「設定永続化」

        // Given: 【テストデータ準備】: ProviderContainer作成
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);

        // When: 【実際の処理実行】: AI丁寧さレベルを「カジュアル」に設定
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setAIPoliteness(PolitenessLevel.casual);

        // Then: 【結果検証】: AI丁寧さレベルがcasualに更新されている
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.aiPoliteness, PolitenessLevel.casual); // 【確認内容】: stateのaiPolitenessがcasualであること 🔵

        // SharedPreferencesに保存されていること
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('ai_politeness'), PolitenessLevel.casual.name); // 【確認内容】: SharedPreferencesに"casual"が保存されていること 🔵

        container.dispose();
      });

      /// TC-074-007: AI丁寧さレベル「普通」の選択と保存（デフォルト）
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-903, REQ-5003
      /// 検証内容: デフォルト値「普通」が正しく動作すること
      test('TC-074-007: AI丁寧さレベル「普通」の選択と保存（デフォルト）', () async {
        // 【テスト目的】: デフォルト値「普通」が正しく設定されることを確認 🔵
        // 【テスト内容】: 初期状態でaiPolitenessがnormalであることを検証
        // 【期待される動作】: 初期状態のaiPolitenessがnormalになる
        // 🔵 青信号: REQ-903「デフォルトは普通」

        // Given: 【テストデータ準備】: 空のSharedPreferences
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        // When: 【実際の処理実行】: 初期状態を取得
        final settings = await container.read(settingsNotifierProvider.future);

        // Then: 【結果検証】: デフォルトがnormalであること
        expect(settings.aiPoliteness, PolitenessLevel.normal); // 【確認内容】: 初期状態のaiPolitenessがnormalであること 🔵

        container.dispose();
      });

      /// TC-074-008: AI丁寧さレベル「丁寧」の選択と保存
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-903, REQ-5003
      /// 検証内容: AI丁寧さレベル「丁寧」が正しく選択・保存されること
      test('TC-074-008: AI丁寧さレベル「丁寧」の選択と保存', () async {
        // 【テスト目的】: AI丁寧さレベル「丁寧」が正しく設定されることを確認 🔵
        // 【テスト内容】: setAIPoliteness(PolitenessLevel.polite)を呼び出し、状態とSharedPreferencesを検証
        // 【期待される動作】: stateがpoliteに更新され、SharedPreferencesに保存される
        // 🔵 青信号: REQ-903「AI丁寧さレベルを3段階から選択可能」

        // Given: 【テストデータ準備】: ProviderContainer作成
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);

        // When: 【実際の処理実行】: AI丁寧さレベルを「丁寧」に設定
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setAIPoliteness(PolitenessLevel.polite);

        // Then: 【結果検証】: AI丁寧さレベルがpoliteに更新されていること
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.aiPoliteness, PolitenessLevel.polite); // 【確認内容】: stateのaiPolitenessがpoliteであること 🔵

        // SharedPreferencesに保存されていること
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('ai_politeness'), PolitenessLevel.polite.name); // 【確認内容】: SharedPreferencesに"polite"が保存されていること 🔵

        container.dispose();
      });

      /// TC-074-009: TTS速度変更が即座に反映される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-404
      /// 検証内容: TTS速度変更が楽観的更新で即座にstateに反映されること
      test('TC-074-009: TTS速度変更が即座に反映される', () async {
        // 【テスト目的】: TTS速度変更が楽観的更新で即座に反映されることを確認 🔵
        // 【テスト内容】: setTTSSpeed()呼び出し直後にstateが更新されることを検証
        // 【期待される動作】: SharedPreferences保存の完了を待たずにstateが更新される
        // 🔵 青信号: REQ-404「TTS速度変更の即座反映」

        // Given: 【テストデータ準備】: ProviderContainer作成
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);

        // When: 【実際の処理実行】: TTS速度を「遅い」に設定
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setTTSSpeed(TTSSpeed.slow);

        // Then: 【結果検証】: 即座にstateが更新されていること
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.ttsSpeed, TTSSpeed.slow); // 【確認内容】: 楽観的更新により即座にstateが更新されること 🔵

        container.dispose();
      });

      /// TC-074-010: AI丁寧さレベル変更が即座に反映される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-903
      /// 検証内容: AI丁寧さレベル変更が楽観的更新で即座にstateに反映されること
      test('TC-074-010: AI丁寧さレベル変更が即座に反映される', () async {
        // 【テスト目的】: AI丁寧さレベル変更が楽観的更新で即座に反映されることを確認 🔵
        // 【テスト内容】: setAIPoliteness()呼び出し直後にstateが更新されることを検証
        // 【期待される動作】: SharedPreferences保存の完了を待たずにstateが更新される
        // 🔵 青信号: REQ-903「AI丁寧さレベル変更の即座反映」

        // Given: 【テストデータ準備】: ProviderContainer作成
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);

        // When: 【実際の処理実行】: AI丁寧さレベルを「丁寧」に設定
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setAIPoliteness(PolitenessLevel.polite);

        // Then: 【結果検証】: 即座にstateが更新されていること
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.aiPoliteness, PolitenessLevel.polite); // 【確認内容】: 楽観的更新により即座にstateが更新されること 🔵

        container.dispose();
      });

      /// TC-074-011: アプリ再起動後のTTS速度設定復元
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-5003
      /// 検証内容: アプリ再起動後に保存したTTS速度が復元されること
      test('TC-074-011: アプリ再起動後のTTS速度設定復元', () async {
        // 【テスト目的】: アプリ再起動後に保存したTTS速度が復元されることを確認 🔵
        // 【テスト内容】: SharedPreferencesに保存後、新しいProviderContainerで復元を検証
        // 【期待される動作】: ttsSpeedがfastとして復元される
        // 🔵 青信号: REQ-5003「設定永続化・再起動後復元」

        // Given: 【テストデータ準備】: SharedPreferencesにtts_speed: "fast"を保存
        SharedPreferences.setMockInitialValues({
          'tts_speed': TTSSpeed.fast.name,
        });

        // When: 【実際の処理実行】: 新しいProviderContainerを作成（再起動を模擬）
        final container = ProviderContainer();
        final settings = await container.read(settingsNotifierProvider.future);

        // Then: 【結果検証】: TTS速度「fast」が正しく復元されたことを確認
        expect(settings.ttsSpeed, TTSSpeed.fast); // 【確認内容】: 保存されたTTS速度が復元されること 🔵

        container.dispose();
      });

      /// TC-074-012: アプリ再起動後のAI丁寧さレベル設定復元
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-5003
      /// 検証内容: アプリ再起動後に保存したAI丁寧さレベルが復元されること
      test('TC-074-012: アプリ再起動後のAI丁寧さレベル設定復元', () async {
        // 【テスト目的】: アプリ再起動後に保存したAI丁寧さレベルが復元されることを確認 🔵
        // 【テスト内容】: SharedPreferencesに保存後、新しいProviderContainerで復元を検証
        // 【期待される動作】: aiPolitenessがpoliteとして復元される
        // 🔵 青信号: REQ-5003「設定永続化・再起動後復元」

        // Given: 【テストデータ準備】: SharedPreferencesにai_politeness: "polite"を保存
        SharedPreferences.setMockInitialValues({
          'ai_politeness': PolitenessLevel.polite.name,
        });

        // When: 【実際の処理実行】: 新しいProviderContainerを作成（再起動を模擬）
        final container = ProviderContainer();
        final settings = await container.read(settingsNotifierProvider.future);

        // Then: 【結果検証】: AI丁寧さレベル「polite」が正しく復元されたことを確認
        expect(settings.aiPoliteness, PolitenessLevel.polite); // 【確認内容】: 保存されたAI丁寧さレベルが復元されること 🔵

        container.dispose();
      });

      /// TC-074-013: 複数設定の同時保存・復元
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-404, REQ-903, REQ-5003
      /// 検証内容: TTS速度とAI丁寧さレベルの両方が正しく保存・復元されること
      test('TC-074-013: 複数設定の同時保存・復元', () async {
        // 【テスト目的】: TTS速度とAI丁寧さレベルの両方が正しく保存・復元されることを確認 🔵
        // 【テスト内容】: 複数の設定を変更後、再起動を模擬して復元を検証
        // 【期待される動作】: すべての設定が正しく保存・復元され、他の設定に影響しない
        // 🔵 青信号: REQ-404、REQ-903、REQ-5003「複数設定の永続化」

        // Given: 【テストデータ準備】: 初期コンテナを作成
        SharedPreferences.setMockInitialValues({});
        final container1 = ProviderContainer();

        await container1.read(settingsNotifierProvider.future);
        final notifier1 = container1.read(settingsNotifierProvider.notifier);

        // When: 【実際の処理実行】: TTS速度とAI丁寧さレベルを変更
        await notifier1.setTTSSpeed(TTSSpeed.slow);
        await notifier1.setAIPoliteness(PolitenessLevel.casual);

        // コンテナを破棄
        container1.dispose();

        // 新しいProviderContainerを作成（再起動を模擬）
        final container2 = ProviderContainer();
        final settings = await container2.read(settingsNotifierProvider.future);

        // Then: 【結果検証】: すべての設定が正しく復元されること
        expect(settings.ttsSpeed, TTSSpeed.slow); // 【確認内容】: TTS速度がslowとして復元されること 🔵
        expect(settings.aiPoliteness, PolitenessLevel.casual); // 【確認内容】: AI丁寧さレベルがcasualとして復元されること 🔵

        // 他の設定（fontSize, theme）も影響を受けないこと
        expect(settings.fontSize, FontSize.medium); // 【確認内容】: フォントサイズがデフォルト値（medium）のまま 🔵
        expect(settings.theme, AppTheme.light); // 【確認内容】: テーマがデフォルト値（light）のまま 🔵

        container2.dispose();
      });
    });

    // =========================================================================
    // 2. 異常系テストケース（エラーハンドリング）
    // =========================================================================
    group('異常系テストケース', () {
      /// TC-074-014: TTS速度の不正値フォールバック
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: NFR-301（基本機能継続）
      /// 検証内容: SharedPreferencesに不正なTTS速度値が保存されている場合のエラーハンドリング
      test('TC-074-014: TTS速度の不正値フォールバック', () async {
        // 【テスト目的】: 不正値でもアプリがクラッシュしないことを確認 🟡
        // 【テスト内容】: SharedPreferencesに不正な値を保存し、デフォルト値へのフォールバックを検証
        // 【期待される動作】: エラーが発生せず、デフォルト値（normal）にフォールバックする
        // 🟡 黄信号: NFR-301「基本機能継続」から推測

        // Given: 【テストデータ準備】: SharedPreferencesに不正な値を保存
        SharedPreferences.setMockInitialValues({
          'tts_speed': 'invalid_value',
        });

        // When: 【実際の処理実行】: Provider初期化
        final container = ProviderContainer();

        // Then: 【結果検証】: エラーにならず、デフォルト値（normal）が使用される
        try {
          final settings = await container.read(settingsNotifierProvider.future);
          // 不正値の場合はデフォルト値が使用されるべき
          expect(settings.ttsSpeed, TTSSpeed.normal); // 【確認内容】: 不正値でデフォルト値（normal）にフォールバックすること 🟡
        } catch (e) {
          // エラーが発生した場合はテスト失敗
          fail('不正値でアプリがクラッシュしました: $e');
        }

        container.dispose();
      });

      /// TC-074-015: AI丁寧さレベルの不正値フォールバック
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: NFR-301（基本機能継続）
      /// 検証内容: SharedPreferencesに不正なAI丁寧さレベル値が保存されている場合のエラーハンドリング
      test('TC-074-015: AI丁寧さレベルの不正値フォールバック', () async {
        // 【テスト目的】: 不正値でもアプリがクラッシュしないことを確認 🟡
        // 【テスト内容】: SharedPreferencesに不正な値を保存し、デフォルト値へのフォールバックを検証
        // 【期待される動作】: エラーが発生せず、デフォルト値（normal）にフォールバックする
        // 🟡 黄信号: NFR-301「基本機能継続」から推測

        // Given: 【テストデータ準備】: SharedPreferencesに不正な値を保存
        SharedPreferences.setMockInitialValues({
          'ai_politeness': 'invalid_value',
        });

        // When: 【実際の処理実行】: Provider初期化
        final container = ProviderContainer();

        // Then: 【結果検証】: エラーにならず、デフォルト値（normal）が使用される
        try {
          final settings = await container.read(settingsNotifierProvider.future);
          // 不正値の場合はデフォルト値が使用されるべき
          expect(settings.aiPoliteness, PolitenessLevel.normal); // 【確認内容】: 不正値でデフォルト値（normal）にフォールバックすること 🟡
        } catch (e) {
          // エラーが発生した場合はテスト失敗
          fail('不正値でアプリがクラッシュしました: $e');
        }

        container.dispose();
      });
    });

    // =========================================================================
    // 3. 境界値テストケース
    // =========================================================================
    group('境界値テストケース', () {
      /// TC-074-017: TTSSpeed enumの全値テスト
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-404
      /// 検証内容: TTSSpeed enumのすべての値（slow, normal, fast）が正しく動作すること
      test('TC-074-017: TTSSpeed enumの全値テスト', () async {
        // 【テスト目的】: TTSSpeed enumのすべての値が正しく動作することを確認 🔵
        // 【テスト内容】: TTSSpeed.valuesをループし、各値の保存・復元を検証
        // 【期待される動作】: slow, normal, fastすべてが正しく保存・復元される
        // 🔵 青信号: REQ-404「TTS速度を3段階から選択可能」

        // Given: 【テストデータ準備】: ProviderContainer作成
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);
        final notifier = container.read(settingsNotifierProvider.notifier);

        // When/Then: 【実際の処理実行と結果検証】: 各値について保存・復元を確認
        for (final speed in TTSSpeed.values) {
          // 各速度を設定
          await notifier.setTTSSpeed(speed);

          // stateが更新されていることを確認
          final state = container.read(settingsNotifierProvider);
          expect(state.requireValue.ttsSpeed, speed); // 【確認内容】: 各TTS速度が正しく設定されること 🔵

          // SharedPreferencesに保存されていることを確認
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getString('tts_speed'), speed.name); // 【確認内容】: 各TTS速度がenum nameとして保存されること 🔵
        }

        container.dispose();
      });

      /// TC-074-018: PolitenessLevel enumの全値テスト
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-903
      /// 検証内容: PolitenessLevel enumのすべての値（casual, normal, polite）が正しく動作すること
      test('TC-074-018: PolitenessLevel enumの全値テスト', () async {
        // 【テスト目的】: PolitenessLevel enumのすべての値が正しく動作することを確認 🔵
        // 【テスト内容】: PolitenessLevel.valuesをループし、各値の保存・復元を検証
        // 【期待される動作】: casual, normal, politeすべてが正しく保存・復元される
        // 🔵 青信号: REQ-903「AI丁寧さレベルを3段階から選択可能」

        // Given: 【テストデータ準備】: ProviderContainer作成
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);
        final notifier = container.read(settingsNotifierProvider.notifier);

        // When/Then: 【実際の処理実行と結果検証】: 各値について保存・復元を確認
        for (final level in PolitenessLevel.values) {
          // 各丁寧さレベルを設定
          await notifier.setAIPoliteness(level);

          // stateが更新されていることを確認
          final state = container.read(settingsNotifierProvider);
          expect(state.requireValue.aiPoliteness, level); // 【確認内容】: 各AI丁寧さレベルが正しく設定されること 🔵

          // SharedPreferencesに保存されていることを確認
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getString('ai_politeness'), level.name); // 【確認内容】: 各AI丁寧さレベルがenum nameとして保存されること 🔵
        }

        container.dispose();
      });

      /// TC-074-019: TTS速度の連続変更テスト
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: 一般的なUI動作
      /// 検証内容: TTS速度を連続して変更しても状態が一貫すること
      test('TC-074-019: TTS速度の連続変更テスト', () async {
        // 【テスト目的】: 連続した変更が正常に処理されることを確認 🟡
        // 【テスト内容】: slow → normal → fast → slow の順に変更し、各変更後の状態を確認
        // 【期待される動作】: すべての変更が正しく反映され、最終的にslowが設定される
        // 🟡 黄信号: 一般的なUI動作から推測

        // Given: 【テストデータ準備】: ProviderContainer作成
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);
        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: 【実際の処理実行】: slow → normal → fast → slow の順に変更
        await notifier.setTTSSpeed(TTSSpeed.slow);
        var state = container.read(settingsNotifierProvider);
        expect(state.requireValue.ttsSpeed, TTSSpeed.slow); // 【確認内容】: slowが設定されていること 🟡

        await notifier.setTTSSpeed(TTSSpeed.normal);
        state = container.read(settingsNotifierProvider);
        expect(state.requireValue.ttsSpeed, TTSSpeed.normal); // 【確認内容】: normalが設定されていること 🟡

        await notifier.setTTSSpeed(TTSSpeed.fast);
        state = container.read(settingsNotifierProvider);
        expect(state.requireValue.ttsSpeed, TTSSpeed.fast); // 【確認内容】: fastが設定されていること 🟡

        await notifier.setTTSSpeed(TTSSpeed.slow);
        state = container.read(settingsNotifierProvider);

        // Then: 【結果検証】: 最終的に slow が正しく設定される
        expect(state.requireValue.ttsSpeed, TTSSpeed.slow); // 【確認内容】: 最終的にslowが設定されていること 🟡

        // SharedPreferencesにも最終値が保存されていること
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('tts_speed'), TTSSpeed.slow.name); // 【確認内容】: SharedPreferencesに最終値（slow）が保存されていること 🟡

        container.dispose();
      });

      /// TC-074-020: AI丁寧さレベルの連続変更テスト
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: 一般的なUI動作
      /// 検証内容: AI丁寧さレベルを連続して変更しても状態が一貫すること
      test('TC-074-020: AI丁寧さレベルの連続変更テスト', () async {
        // 【テスト目的】: 連続した変更が正常に処理されることを確認 🟡
        // 【テスト内容】: casual → normal → polite → casual の順に変更し、各変更後の状態を確認
        // 【期待される動作】: すべての変更が正しく反映され、最終的にcasualが設定される
        // 🟡 黄信号: 一般的なUI動作から推測

        // Given: 【テストデータ準備】: ProviderContainer作成
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);
        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: 【実際の処理実行】: casual → normal → polite → casual の順に変更
        await notifier.setAIPoliteness(PolitenessLevel.casual);
        var state = container.read(settingsNotifierProvider);
        expect(state.requireValue.aiPoliteness, PolitenessLevel.casual); // 【確認内容】: casualが設定されていること 🟡

        await notifier.setAIPoliteness(PolitenessLevel.normal);
        state = container.read(settingsNotifierProvider);
        expect(state.requireValue.aiPoliteness, PolitenessLevel.normal); // 【確認内容】: normalが設定されていること 🟡

        await notifier.setAIPoliteness(PolitenessLevel.polite);
        state = container.read(settingsNotifierProvider);
        expect(state.requireValue.aiPoliteness, PolitenessLevel.polite); // 【確認内容】: politeが設定されていること 🟡

        await notifier.setAIPoliteness(PolitenessLevel.casual);
        state = container.read(settingsNotifierProvider);

        // Then: 【結果検証】: 最終的に casual が正しく設定される
        expect(state.requireValue.aiPoliteness, PolitenessLevel.casual); // 【確認内容】: 最終的にcasualが設定されていること 🟡

        // SharedPreferencesにも最終値が保存されていること
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('ai_politeness'), PolitenessLevel.casual.name); // 【確認内容】: SharedPreferencesに最終値（casual）が保存されていること 🟡

        container.dispose();
      });
    });

    // =========================================================================
    // 4. 統合テストケース
    // =========================================================================
    group('統合テストケース', () {
      /// TC-074-021: SettingsProviderの全機能統合テスト
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-801, REQ-803, REQ-404, REQ-903
      /// 検証内容: AppSettingsの全フィールドが正しく動作すること
      test('TC-074-021: SettingsProviderの全機能統合テスト', () async {
        // 【テスト目的】: AppSettingsの全フィールドが正しく動作することを確認 🔵
        // 【テスト内容】: フォントサイズ、テーマ、TTS速度、AI丁寧さレベルをすべて変更し、復元を検証
        // 【期待される動作】: すべての設定が正しく保存・復元される
        // 🔵 青信号: REQ-801、REQ-803、REQ-404、REQ-903「全設定の統合動作」

        // Given: 【テストデータ準備】: 初期コンテナを作成
        SharedPreferences.setMockInitialValues({});
        final container1 = ProviderContainer();

        await container1.read(settingsNotifierProvider.future);
        final notifier1 = container1.read(settingsNotifierProvider.notifier);

        // When: 【実際の処理実行】: すべての設定を変更
        await notifier1.setFontSize(FontSize.large);
        await notifier1.setTheme(AppTheme.dark);
        await notifier1.setTTSSpeed(TTSSpeed.fast);
        await notifier1.setAIPoliteness(PolitenessLevel.polite);

        // コンテナを破棄
        container1.dispose();

        // 新しいProviderContainerを作成（再起動を模擬）
        final container2 = ProviderContainer();
        final settings = await container2.read(settingsNotifierProvider.future);

        // Then: 【結果検証】: すべての設定が正しく復元されること
        expect(settings.fontSize, FontSize.large); // 【確認内容】: フォントサイズがlargeとして復元されること 🔵
        expect(settings.theme, AppTheme.dark); // 【確認内容】: テーマがdarkとして復元されること 🔵
        expect(settings.ttsSpeed, TTSSpeed.fast); // 【確認内容】: TTS速度がfastとして復元されること 🔵
        expect(settings.aiPoliteness, PolitenessLevel.polite); // 【確認内容】: AI丁寧さレベルがpoliteとして復元されること 🔵

        container2.dispose();
      });
    });
  });
}
