/// TTSButtonウィジェット テスト
///
/// TASK-0050: TTS読み上げ中断機能
/// テストケース: TC-050-001〜TC-050-009
///
/// テスト対象: lib/features/tts/presentation/widgets/tts_button.dart
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
import '../../../../mocks/mock_flutter_tts.dart';

/// TTSNotifierを作成するヘルパー関数（テスト用）
///
/// モックされたFlutterTtsを使用するTTSNotifierを作成する。
TTSNotifier createTestTTSNotifier(MockFlutterTts mockFlutterTts) {
  final service = TTSService(tts: mockFlutterTts);
  return TTSNotifier(service: service);
}

void main() {
  group('TTSButtonウィジェットテスト', () {
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
      when(() => mockFlutterTts.setSpeechRate(any()))
          .thenAnswer((_) async => 1);
      when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);
    });

    // =========================================================================
    // 1. 正常系テストケース（UI表示）
    // =========================================================================
    group('UI表示テスト', () {
      /// TC-050-001: アイドル状態で「読み上げ」ボタンが表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-402, REQ-3003
      /// 検証内容: TTSがidle状態の時、読み上げボタンが表示されること
      testWidgets('TC-050-001: アイドル状態で「読み上げ」ボタンが表示されることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: TTSがidle状態の時、読み上げボタンが表示されることを確認 🔵
        // 【テスト内容】: TTSButtonウィジェットをレンダリングし、「読み上げ」ラベルが表示されることを検証
        // 【期待される動作】: 「読み上げ」ラベルのボタンがレンダリングされる
        // 🔵 青信号: REQ-402「読み上げボタンを明確に表示」、REQ-3003に基づく

        // Given: 【テストデータ準備】: idle状態のTTSProviderでラップしたTTSButtonを構築
        // 【初期条件設定】: アプリ起動直後の初期状態
        final container = ProviderContainer(
          overrides: [
            ttsProvider
                .overrideWith((ref) => createTestTTSNotifier(mockFlutterTts)),
          ],
        );

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

        // Then: 【結果検証】: 「読み上げ」ボタンが表示されていることを確認
        // 【期待値確認】: REQ-402「読み上げボタンを明確に表示」に基づく
        // 【品質保証】: ユーザーが読み上げを開始できることを保証
        expect(find.text('読み上げ'),
            findsOneWidget); // 【確認内容】: 「読み上げ」ラベルが表示されていることを確認 🔵

        container.dispose();
      });

      /// TC-050-002: 読み上げ中は「停止」ボタンに切り替わる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-3003
      /// 検証内容: TTSがspeaking状態の時、停止ボタンが表示されること
      testWidgets('TC-050-002: 読み上げ中は「停止」ボタンに切り替わることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: TTSがspeaking状態の時、停止ボタンが表示されることを確認 🔵
        // 【テスト内容】: speaking状態でTTSButtonをレンダリングし、「停止」ラベルが表示されることを検証
        // 【期待される動作】: ボタンラベルが「停止」に変わる
        // 🔵 青信号: REQ-3003「読み上げ実行中状態では停止ボタンとして表示」に基づく

        // Given: 【テストデータ準備】: speaking状態のTTSProviderでラップしたTTSButtonを構築
        // 【初期条件設定】: 読み上げ中の状態
        final container = ProviderContainer(
          overrides: [
            ttsProvider
                .overrideWith((ref) => createTestTTSNotifier(mockFlutterTts)),
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

        // Then: 【結果検証】: 「停止」ボタンが表示されていることを確認
        // 【期待値確認】: REQ-3003「読み上げ実行中状態では停止ボタンとして表示」に基づく
        // 【品質保証】: ユーザーが読み上げを中断できることを保証
        expect(
            find.text('停止'), findsOneWidget); // 【確認内容】: 「停止」ラベルが表示されていることを確認 🔵

        container.dispose();
      });

      /// TC-050-003: 読み上げ完了後は「読み上げ」ボタンに戻る
      ///
      /// 優先度: P0（必須）
      /// 検証内容: 読み上げ完了後にボタンが元の状態に戻ること
      testWidgets('TC-050-003: 読み上げ完了後は「読み上げ」ボタンに戻ることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: 読み上げ完了後にボタンが元の状態に戻ることを確認 🔵
        // 【テスト内容】: speaking→completed→idleの状態遷移後、「読み上げ」ラベルに戻ることを検証
        // 【期待される動作】: 状態がidle/completedに遷移するとボタンが「読み上げ」に戻る
        // 🔵 青信号: tts_state.dart状態遷移定義に基づく

        // Given: 【テストデータ準備】: completedハンドラをモックして状態を制御
        // 【初期条件設定】: 読み上げ完了後の状態
        final container = ProviderContainer(
          overrides: [
            ttsProvider
                .overrideWith((ref) => createTestTTSNotifier(mockFlutterTts)),
          ],
        );

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

        // Then: 【結果検証】: idle状態（完了後）で「読み上げ」ボタンが表示されていることを確認
        // 【期待値確認】: 完了後に再び読み上げ可能な状態になること
        // 【品質保証】: 再度読み上げが可能なことを保証
        expect(find.text('読み上げ'),
            findsOneWidget); // 【確認内容】: 「読み上げ」ラベルが表示されていることを確認 🔵

        container.dispose();
      });

      /// TC-050-004: ボタンサイズが44px×44px以上である
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: REQ-5001
      /// 検証内容: アクセシビリティ要件を満たすボタンサイズ
      testWidgets('TC-050-004: ボタンサイズが44px×44px以上であることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: アクセシビリティ要件を満たすボタンサイズであることを確認 🟡
        // 【テスト内容】: TTSButtonのサイズが最低44px×44px以上であることを検証
        // 【期待される動作】: ボタンのタップ領域が最低44pxを確保
        // 🟡 黄信号: REQ-5001「タップターゲット44px×44px以上」から推測

        // Given: 【テストデータ準備】: TTSButtonウィジェットをレンダリング
        // 【初期条件設定】: 標準表示状態
        final container = ProviderContainer(
          overrides: [
            ttsProvider
                .overrideWith((ref) => createTestTTSNotifier(mockFlutterTts)),
          ],
        );

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

        // Then: 【結果検証】: ボタンサイズが44px×44px以上であることを確認
        // 【期待値確認】: REQ-5001「タップターゲット44px×44px以上」に基づく
        // 【品質保証】: 高齢者や運動機能に制限のあるユーザーが操作しやすいこと
        final buttonFinder = find.byType(TTSButton);
        expect(buttonFinder, findsOneWidget);

        final buttonSize = tester.getSize(buttonFinder);
        expect(buttonSize.width,
            greaterThanOrEqualTo(44)); // 【確認内容】: 幅が44px以上であることを確認 🟡
        expect(buttonSize.height,
            greaterThanOrEqualTo(44)); // 【確認内容】: 高さが44px以上であることを確認 🟡

        container.dispose();
      });

      /// TC-050-005: ボタンに適切なSemantics（アクセシビリティラベル）が設定されている
      ///
      /// 優先度: P1（高優先度）
      /// 検証内容: スクリーンリーダー対応の確認
      testWidgets('TC-050-005: ボタンにSemanticsが設定されていることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: スクリーンリーダー対応のSemanticsが設定されていることを確認 🟡
        // 【テスト内容】: TTSButtonにSemanticsウィジェットでlabelが設定されていることを検証
        // 【期待される動作】: Semanticsウィジェットにlabelが設定されている
        // 🟡 黄信号: tech-stack.md「Semanticsウィジェット使用」に基づく

        // Given: 【テストデータ準備】: TTSButtonウィジェットをレンダリング
        // 【初期条件設定】: 標準表示状態
        final container = ProviderContainer(
          overrides: [
            ttsProvider
                .overrideWith((ref) => createTestTTSNotifier(mockFlutterTts)),
          ],
        );

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

        // Then: 【結果検証】: Semanticsが設定されていることを確認
        // 【期待値確認】: アクセシビリティ対応
        // 【品質保証】: スクリーンリーダーが適切に読み上げられること
        final semantics = tester.getSemantics(find.byType(TTSButton));
        expect(semantics.label,
            isNotEmpty); // 【確認内容】: Semanticsラベルが設定されていることを確認 🟡

        container.dispose();
      });
    });

    // =========================================================================
    // 2. 正常系テストケース（状態管理）
    // =========================================================================
    group('状態管理テスト', () {
      /// TC-050-006: 読み上げボタンタップでTTS読み上げが開始される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-401
      /// 検証内容: ボタンタップがTTSNotifier.speak()を呼び出すこと
      testWidgets('TC-050-006: 読み上げボタンタップでTTS読み上げが開始されることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: ボタンタップがTTSNotifier.speak()を呼び出すことを確認 🔵
        // 【テスト内容】: 読み上げボタンをタップし、speak()が呼ばれることを検証
        // 【期待される動作】: speak()が呼ばれ、状態がspeakingに遷移
        // 🔵 青信号: REQ-401「入力欄のテキストをTTSで読み上げる」に基づく

        // Given: 【テストデータ準備】: idle状態のTTSProviderでラップしたTTSButtonを構築
        // 【初期条件設定】: アプリ起動直後の初期状態
        var onSpeakCalled = false;
        final container = ProviderContainer(
          overrides: [
            ttsProvider
                .overrideWith((ref) => createTestTTSNotifier(mockFlutterTts)),
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
                  onSpeak: () {
                    onSpeakCalled = true;
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // When: 【実際の処理実行】: 読み上げボタンをタップ
        // 【処理内容】: ユーザーが読み上げボタンをタップした場合を模擬
        await tester.tap(find.text('読み上げ'));
        await tester.pumpAndSettle();

        // Then: 【結果検証】: onSpeakコールバックが呼ばれたことを確認
        // 【期待値確認】: REQ-401「入力欄のテキストをTTSで読み上げる」に基づく
        // 【品質保証】: UIアクションがビジネスロジックに正しく伝達されること
        expect(onSpeakCalled, isTrue); // 【確認内容】: onSpeakコールバックが呼ばれたことを確認 🔵

        container.dispose();
      });

      /// TC-050-007: 停止ボタンタップでTTS読み上げが中断される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-403
      /// 検証内容: 停止ボタンタップがTTSNotifier.stop()を呼び出すこと
      testWidgets('TC-050-007: 停止ボタンタップでTTS読み上げが中断されることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: 停止ボタンタップがTTSNotifier.stop()を呼び出すことを確認 🔵
        // 【テスト内容】: speaking状態で停止ボタンをタップし、stop()が呼ばれることを検証
        // 【期待される動作】: stop()が呼ばれ、状態がstoppedに遷移
        // 🔵 青信号: REQ-403「読み上げ中の停止・中断機能」に基づく

        // Given: 【テストデータ準備】: speaking状態のTTSProviderでラップしたTTSButtonを構築
        // 【初期条件設定】: 読み上げ中の状態
        final container = ProviderContainer(
          overrides: [
            ttsProvider
                .overrideWith((ref) => createTestTTSNotifier(mockFlutterTts)),
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
        // 【処理内容】: ユーザーが読み上げを中断したい場合を模擬
        await tester.tap(find.text('停止'));
        await tester.pumpAndSettle();

        // Then: 【結果検証】: TTS停止が呼ばれたことを確認
        // 【期待値確認】: REQ-403「読み上げ中の停止・中断機能」に基づく
        // 【品質保証】: 読み上げが即座に停止すること
        verify(() => mockFlutterTts.stop())
            .called(1); // 【確認内容】: stop()が呼ばれたことを確認 🔵
        expect(container.read(ttsProvider).state,
            TTSState.stopped); // 【確認内容】: 状態がstoppedになったことを確認 🔵

        container.dispose();
      });

      /// TC-050-008: 停止後にidleに自動遷移する
      ///
      /// 優先度: P0（必須）
      /// 検証内容: stopped状態からidle状態への自動遷移
      testWidgets('TC-050-008: 停止後にidleに自動遷移することを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: stopped状態からidle状態への自動遷移を確認 🔵
        // 【テスト内容】: 停止後、短時間でidle状態に戻ることを検証
        // 【期待される動作】: stopped後、短時間でidleに戻る
        // 🔵 青信号: tts_state.dart状態遷移定義に基づく

        // Given: 【テストデータ準備】: speaking状態のTTSProviderでラップしたTTSButtonを構築
        // 【初期条件設定】: 読み上げ中の状態
        final container = ProviderContainer(
          overrides: [
            ttsProvider
                .overrideWith((ref) => createTestTTSNotifier(mockFlutterTts)),
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

        // When: 【実際の処理実行】: 停止ボタンをタップ
        // 【処理内容】: stop()を呼び出す
        await tester.tap(find.text('停止'));
        await tester.pumpAndSettle();

        // Then: 【結果検証】: 状態がstopped（またはidle）になっていることを確認
        // 【期待値確認】: tts_state.dart状態遷移定義に基づく
        // 【品質保証】: 次の読み上げが可能な状態に戻ること
        final state = container.read(ttsProvider).state;
        expect(
            state,
            anyOf(TTSState.stopped,
                TTSState.idle)); // 【確認内容】: 状態がstopped/idleであることを確認 🔵

        container.dispose();
      });

      /// TC-050-009: 状態変更がRiverpodで正しく監視される
      ///
      /// 優先度: P0（必須）
      /// 検証内容: 状態変更がConsumerWidgetに通知されること
      testWidgets('TC-050-009: 状態変更がRiverpodで正しく監視されることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: 状態変更がConsumerWidgetに通知されることを確認 🔵
        // 【テスト内容】: container.listen()で状態変更がキャプチャできることを検証
        // 【期待される動作】: container.listen()で状態変更がキャプチャできる
        // 🔵 青信号: 既存テストパターン（TC-048-022）に基づく

        // Given: 【テストデータ準備】: 状態変更をキャプチャするリスナーを設定
        // 【初期条件設定】: 状態変更監視の準備
        final container = ProviderContainer(
          overrides: [
            ttsProvider
                .overrideWith((ref) => createTestTTSNotifier(mockFlutterTts)),
          ],
        );

        // TTSを初期化
        final notifier = container.read(ttsProvider.notifier);
        await notifier.initialize();

        final stateChanges = <TTSState>[];
        container.listen<TTSServiceState>(
          ttsProvider,
          (previous, next) {
            stateChanges.add(next.state);
          },
        );

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

        // When: 【実際の処理実行】: speak() → stop()の一連の操作
        // 【処理内容】: 状態遷移のシナリオを実行
        await tester.tap(find.text('読み上げ'));
        await tester.pumpAndSettle();

        // Then: 【結果検証】: 状態変更リストにspeakingが記録されることを確認
        // 【期待値確認】: Riverpodの状態管理パターン
        // 【品質保証】: UIが状態変更に追従すること
        expect(stateChanges,
            contains(TTSState.speaking)); // 【確認内容】: 状態変更がリスナーに通知されたことを確認 🔵

        container.dispose();
      });
    });
  });
}
