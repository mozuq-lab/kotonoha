/// TTS読み上げ中断機能 統合テスト
///
/// TASK-0050: TTS読み上げ中断機能
/// テストケース: TC-050-010〜TC-050-017
///
/// テスト対象: エンドツーエンドのフロー（TTSButton → TTSProvider → TTSService）
///
/// 【TDD Redフェーズ】: TTSButtonウィジェットが未実装、テストが失敗するはず
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/tts/presentation/widgets/tts_button.dart';
import '../mocks/mock_flutter_tts.dart';

void main() {
  group('TTS読み上げ中断機能 統合テスト', () {
    late MockFlutterTts mockFlutterTts;

    setUpAll(() {
      // Mocktailのフォールバック値を登録
      registerFallbackValue('');
      registerFallbackValue(0.0);
    });

    setUp(() {
      // 【テスト前準備】: 各テストが独立して実行できるよう、クリーンな状態から開始
      // 【環境初期化】: モックFlutterTtsを作成
      mockFlutterTts = MockFlutterTts();

      // モックのデフォルト動作を設定
      when(() => mockFlutterTts.setLanguage(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.setSpeechRate(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);
    });

    // =========================================================================
    // 3. 異常系テストケース
    // =========================================================================
    group('異常系テスト', () {
      /// TC-050-010: アイドル状態で停止ボタンをタップしてもエラーにならない
      ///
      /// 優先度: P1（高優先度）
      /// 検証内容: idle状態でstop()が呼ばれた場合の冪等性
      testWidgets('TC-050-010: アイドル状態で停止操作をしてもエラーにならないことを確認', (WidgetTester tester) async {
        // 【テスト目的】: idle状態でstop()が呼ばれた場合でもエラーにならないことを確認 🟡
        // 【テスト内容】: idle状態でstop()を呼び出し、エラーが発生しないことを検証
        // 【期待される動作】: エラーなし、状態はidleのまま（またはstopped→idleに遷移）
        // 🟡 黄信号: 防御的プログラミングの原則に基づく

        // Given: 【テストデータ準備】: idle状態のTTSProviderを構築
        // 【初期条件設定】: 読み上げ中でない状態
        final container = ProviderContainer(
          overrides: [
            ttsServiceProvider.overrideWithValue(
              TTSService(tts: mockFlutterTts),
            ),
          ],
        );

        // TTSを初期化（idleの状態）
        final notifier = container.read(ttsProvider.notifier);
        await notifier.initialize();

        // When: 【実際の処理実行】: idle状態でstop()を呼び出す
        // 【処理内容】: 読み上げ中でないのに停止を要求する場合を模擬
        // 【実際の発生シナリオ】: UIの遅延で状態とボタンがずれた場合
        await notifier.stop();

        // Then: 【結果検証】: エラーが発生しないことを確認
        // 【期待値確認】: 冪等性が確保されている
        // 【品質保証】: アプリはクラッシュしない
        final state = container.read(ttsProvider).state;
        expect(state, anyOf(TTSState.idle, TTSState.stopped)); // 【確認内容】: エラーなく状態が維持されることを確認 🟡

        container.dispose();
      });

      /// TC-050-011: 連続した停止ボタンタップが安全に処理される
      ///
      /// 優先度: P1（高優先度）
      /// 検証内容: 停止ボタンを連打した場合のUIの安全性
      testWidgets('TC-050-011: 連続した停止操作が安全に処理されることを確認', (WidgetTester tester) async {
        // 【テスト目的】: 停止ボタンを連打しても安全に処理されることを確認 🟡
        // 【テスト内容】: stop()を2回連続で呼び出し、エラーが発生しないことを検証
        // 【期待される動作】: 1回目で停止、2回目以降は無視
        // 🟡 黄信号: 既存テストパターン（TC-048-028）に基づく

        // Given: 【テストデータ準備】: speaking状態のTTSProviderを構築
        // 【初期条件設定】: 読み上げ中の状態
        final container = ProviderContainer(
          overrides: [
            ttsServiceProvider.overrideWithValue(
              TTSService(tts: mockFlutterTts),
            ),
          ],
        );

        // TTSを初期化して読み上げを開始
        final notifier = container.read(ttsProvider.notifier);
        await notifier.initialize();
        await notifier.speak('長いテキスト...');

        // When: 【実際の処理実行】: stop()を2回連続で呼び出す
        // 【処理内容】: ユーザーが反応を確認できず連打した場合を模擬
        await notifier.stop();
        await notifier.stop();

        // Then: 【結果検証】: エラーが発生せず、状態がstoppedであることを確認
        // 【期待値確認】: 冪等性が確保されている
        // 【品質保証】: アプリの状態が破綻しない
        expect(container.read(ttsProvider).state, TTSState.stopped); // 【確認内容】: 状態がstoppedのまま維持されることを確認 🟡

        container.dispose();
      });

      /// TC-050-012: TTS停止エラー時も基本機能が継続動作する
      ///
      /// 優先度: P0（必須）
      /// 関連要件: NFR-301
      /// 検証内容: stop()呼び出し時にエラーが発生した場合の堅牢性
      testWidgets('TC-050-012: TTS停止エラー時も基本機能が継続動作することを確認', (WidgetTester tester) async {
        // 【テスト目的】: stop()呼び出し時にエラーが発生しても基本機能が継続することを確認 🔵
        // 【テスト内容】: stop()が例外をスローする設定で、アプリがクラッシュしないことを検証
        // 【期待される動作】: エラー状態になるが、アプリはクラッシュしない
        // 🔵 青信号: NFR-301「重大なエラーでも基本機能は継続」に基づく

        // Given: 【テストデータ準備】: stop()でエラーをスローするモックを設定
        // 【初期条件設定】: OSレベルのTTSエラーが発生する状況を模擬
        when(() => mockFlutterTts.stop()).thenThrow(Exception('TTS停止エラー'));

        final container = ProviderContainer(
          overrides: [
            ttsServiceProvider.overrideWithValue(
              TTSService(tts: mockFlutterTts),
            ),
          ],
        );

        // TTSを初期化して読み上げを開始
        final notifier = container.read(ttsProvider.notifier);
        await notifier.initialize();
        await notifier.speak('テスト');

        // When: 【実際の処理実行】: stop()を呼び出す（エラーが発生）
        // 【処理内容】: システムリソース不足などのエラー状況を模擬
        await notifier.stop();

        // Then: 【結果検証】: アプリがクラッシュせず、状態がerrorになることを確認
        // 【期待値確認】: NFR-301「重大なエラーでも基本機能は継続」に基づく
        // 【品質保証】: 文字盤入力などの基本機能は継続動作
        final state = container.read(ttsProvider).state;
        expect(state, anyOf(TTSState.error, TTSState.stopped, TTSState.idle)); // 【確認内容】: 状態がerror/stopped/idleのいずれかであることを確認 🔵

        container.dispose();
      });
    });

    // =========================================================================
    // 4. 境界値テストケース
    // =========================================================================
    group('境界値テスト', () {
      /// TC-050-013: 読み上げ開始直後（100ms以内）の停止が正常に処理される
      ///
      /// 優先度: P1（高優先度）
      /// 検証内容: 状態遷移の境界（speaking直後のstop）
      testWidgets('TC-050-013: 読み上げ開始直後の停止が正常に処理されることを確認', (WidgetTester tester) async {
        // 【テスト目的】: 読み上げ開始直後の停止が正常に処理されることを確認 🟡
        // 【テスト内容】: speak()の直後にstop()を呼び出し、正常に処理されることを検証
        // 【期待される動作】: 停止が正常に処理され、idle状態に戻る
        // 🟡 黄信号: 防御的プログラミングの原則に基づく

        // Given: 【テストデータ準備】: TTSProviderを構築
        // 【初期条件設定】: 正常な状態
        final container = ProviderContainer(
          overrides: [
            ttsServiceProvider.overrideWithValue(
              TTSService(tts: mockFlutterTts),
            ),
          ],
        );

        // TTSを初期化
        final notifier = container.read(ttsProvider.notifier);
        await notifier.initialize();

        // When: 【実際の処理実行】: speak() → 即時stop()
        // 【処理内容】: 誤タップで読み上げを開始した場合の即座キャンセルを模擬
        await notifier.speak('テスト');
        await notifier.stop();

        // Then: 【結果検証】: 停止が正常に処理され、stopped/idle状態になることを確認
        // 【期待値確認】: speak→stopの順序が保証される
        // 【品質保証】: 高速な状態遷移でも安定動作
        final state = container.read(ttsProvider).state;
        expect(state, anyOf(TTSState.stopped, TTSState.idle)); // 【確認内容】: 正常に停止されたことを確認 🟡

        // stop()が呼ばれたことを確認
        verify(() => mockFlutterTts.stop()).called(1); // 【確認内容】: stop()が呼ばれたことを確認 🟡

        container.dispose();
      });

      /// TC-050-014: 長いテキスト（1000文字）の読み上げ中の停止
      ///
      /// 優先度: P0（必須）
      /// 関連要件: EDGE-101
      /// 検証内容: 入力バッファ最大値での停止
      testWidgets('TC-050-014: 長いテキスト（1000文字）の読み上げ中の停止が正常に処理されることを確認', (WidgetTester tester) async {
        // 【テスト目的】: 長いテキストの読み上げ中でも停止が正常に効くことを確認 🔵
        // 【テスト内容】: 1000文字のテキストを読み上げ中にstop()を呼び出し、即座に停止することを検証
        // 【期待される動作】: 読み上げが即座に停止する
        // 🔵 青信号: EDGE-101（1000文字制限）に基づく

        // Given: 【テストデータ準備】: 1000文字のテキストを準備
        // 【初期条件設定】: 最大文字数のテキストを読み上げ中
        final container = ProviderContainer(
          overrides: [
            ttsServiceProvider.overrideWithValue(
              TTSService(tts: mockFlutterTts),
            ),
          ],
        );

        // TTSを初期化して1000文字のテキストを読み上げ開始
        final notifier = container.read(ttsProvider.notifier);
        await notifier.initialize();

        final longText = 'あ' * 1000;
        await notifier.speak(longText);

        // When: 【実際の処理実行】: 途中で停止
        // 【処理内容】: 長文の読み上げを途中でキャンセル
        await notifier.stop();

        // Then: 【結果検証】: 読み上げが即座に停止することを確認
        // 【期待値確認】: テキスト長に関わらず停止が効く
        // 【品質保証】: 極端な条件下でも安定動作
        expect(container.read(ttsProvider).state, TTSState.stopped); // 【確認内容】: 状態がstoppedになったことを確認 🔵
        verify(() => mockFlutterTts.stop()).called(1); // 【確認内容】: stop()が呼ばれたことを確認 🔵

        container.dispose();
      });
    });

    // =========================================================================
    // 5. 統合テストケース
    // =========================================================================
    group('統合テスト', () {
      /// TC-050-015: 読み上げ→停止→再読み上げの一連のフロー
      ///
      /// 優先度: P0（必須）
      /// 検証内容: 一連の操作フローが正常に動作すること
      testWidgets('TC-050-015: 読み上げ→停止→再読み上げの一連のフローが正常に動作することを確認', (WidgetTester tester) async {
        // 【テスト目的】: 一連の操作フローが正常に動作することを確認 🔵
        // 【テスト内容】: speak("A") → stop() → speak("B")の一連の操作が正常に動作することを検証
        // 【期待される動作】: 停止後に再度読み上げが可能
        // 🔵 青信号: requirements.md「パターン1」に基づく

        // Given: 【テストデータ準備】: TTSProviderを構築
        // 【初期条件設定】: 正常な状態
        final container = ProviderContainer(
          overrides: [
            ttsServiceProvider.overrideWithValue(
              TTSService(tts: mockFlutterTts),
            ),
          ],
        );

        // TTSを初期化
        final notifier = container.read(ttsProvider.notifier);
        await notifier.initialize();

        // モックの呼び出し履歴をクリア
        clearInteractions(mockFlutterTts);

        // When: 【実際の処理実行】: speak("A") → stop() → speak("B")
        // 【処理内容】: 読み上げを中断して別のテキストを読み上げるシナリオ
        await notifier.speak('テキストA');
        await notifier.stop();
        await notifier.speak('テキストB');

        // Then: 【結果検証】: 両方のspeak()が正常に実行されたことを確認
        // 【期待値確認】: 基本的なユースケースの確認
        // 【品質保証】: 状態遷移が正しく行われること
        verify(() => mockFlutterTts.speak('テキストA')).called(1); // 【確認内容】: テキストAが読み上げられたことを確認 🔵
        verify(() => mockFlutterTts.stop()).called(greaterThanOrEqualTo(1)); // 【確認内容】: 停止が呼ばれたことを確認 🔵
        verify(() => mockFlutterTts.speak('テキストB')).called(1); // 【確認内容】: テキストBが読み上げられたことを確認 🔵
        expect(container.read(ttsProvider).state, TTSState.speaking); // 【確認内容】: 最終状態がspeakingであることを確認 🔵

        container.dispose();
      });

      /// TC-050-016: UIボタンタップからTTS停止までの統合フロー
      ///
      /// 優先度: P0（必須）
      /// 検証内容: ウィジェットテストでボタン→Provider→TTSServiceの連携
      testWidgets('TC-050-016: UIボタンタップからTTS停止までの統合フローが正常に動作することを確認', (WidgetTester tester) async {
        // 【テスト目的】: ボタン→Provider→TTSServiceの連携が正常に動作することを確認 🔵
        // 【テスト内容】: WidgetTester.tap(停止ボタン)でTTSService.stop()が呼ばれることを検証
        // 【期待される動作】: ボタンタップでTTSが実際に停止する
        // 🔵 青信号: 既存統合テストパターンに基づく

        // Given: 【テストデータ準備】: speaking状態のTTSProviderでラップしたTTSButtonを構築
        // 【初期条件設定】: 読み上げ中の状態
        final container = ProviderContainer(
          overrides: [
            ttsServiceProvider.overrideWithValue(
              TTSService(tts: mockFlutterTts),
            ),
          ],
        );

        // TTSを初期化して読み上げを開始
        final notifier = container.read(ttsProvider.notifier);
        await notifier.initialize();
        await notifier.speak('テスト');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: TTSButton(
                  text: 'こんにちは',
                  onSpeak: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // モックの呼び出し履歴をクリア
        clearInteractions(mockFlutterTts);

        // When: 【実際の処理実行】: 停止ボタンをタップ
        // 【処理内容】: ユーザー操作のシミュレーション
        await tester.tap(find.text('停止'));
        await tester.pumpAndSettle();

        // Then: 【結果検証】: TTSService.stop()が呼ばれたことを確認
        // 【期待値確認】: UI→ロジックの連携確認
        // 【品質保証】: 各レイヤーが正しく連携すること
        verify(() => mockFlutterTts.stop()).called(1); // 【確認内容】: stop()が呼ばれたことを確認 🔵

        container.dispose();
      });

      /// TC-050-017: 状態変更に応じたボタン表示更新の統合確認
      ///
      /// 優先度: P0（必須）
      /// 関連要件: NFR-003
      /// 検証内容: 状態変更→UI更新のリアクティブな連携
      testWidgets('TC-050-017: 状態変更に応じたボタン表示更新が正常に動作することを確認', (WidgetTester tester) async {
        // 【テスト目的】: 状態変更がボタン表示に即座に反映されることを確認 🔵
        // 【テスト内容】: TTSStateの変更がボタンラベルの切り替えにつながることを検証
        // 【期待される動作】: TTSStateの変更がボタン表示に即座に反映
        // 🔵 青信号: NFR-003（100ms以内応答）に基づく

        // Given: 【テストデータ準備】: idle状態のTTSProviderでラップしたTTSButtonを構築
        // 【初期条件設定】: アプリ起動直後の初期状態
        final container = ProviderContainer(
          overrides: [
            ttsServiceProvider.overrideWithValue(
              TTSService(tts: mockFlutterTts),
            ),
          ],
        );

        // TTSを初期化
        final notifier = container.read(ttsProvider.notifier);
        await notifier.initialize();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: TTSButton(
                  text: 'こんにちは',
                  onSpeak: () async {
                    await notifier.speak('こんにちは');
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 【結果検証】: 初期状態で「読み上げ」ボタンが表示されていることを確認
        expect(find.text('読み上げ'), findsOneWidget); // 【確認内容】: 初期状態で「読み上げ」が表示されていることを確認 🔵

        // When: 【実際の処理実行】: 読み上げを開始（状態がspeakingに変更）
        // 【処理内容】: Provider状態の変更
        await tester.tap(find.text('読み上げ'));
        await tester.pumpAndSettle();

        // Then: 【結果検証】: 状態変更後、「停止」ボタンに切り替わったことを確認
        // 【期待値確認】: Riverpodのリアクティブ更新
        // 【品質保証】: 状態変更がUIに100ms以内に反映されること
        expect(find.text('停止'), findsOneWidget); // 【確認内容】: speaking状態で「停止」が表示されていることを確認 🔵

        container.dispose();
      });
    });
  });
}
