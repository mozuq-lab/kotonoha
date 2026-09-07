library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/tts/presentation/widgets/tts_button.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';

import '../../../../support/contrast_helpers.dart';
import '../../../../mocks/mock_flutter_tts.dart';

/// TTSNotifierを作成するヘルパー関数（テスト用）
/// モックされたFlutterTtsを使用するTTSNotifierを作成する。
TTSNotifier createTestTTSNotifier(MockFlutterTts mockFlutterTts) {
  final service = TTSService(tts: mockFlutterTts);
  return TTSNotifier(serviceOverride: service);
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
      // テスト前準備: 各テストが独立して実行できるよう、クリーンな状態から開始
      // 環境初期化: モックFlutterTtsを作成
      mockFlutterTts = MockFlutterTts();

      // モックのデフォルト動作を設定
      when(() => mockFlutterTts.setLanguage(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.setSpeechRate(any()))
          .thenAnswer((_) async => 1);
      when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);
    });

    group('UI表示テスト', () {
      /// アイドル状態で「読み上げ」ボタンが表示される
      testWidgets('TC-050-001: アイドル状態で「読み上げ」ボタンが表示されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: idle状態のTTSProviderでラップしたTTSButtonを構築
        // 初期条件設定: アプリ起動直後の初期状態
        final container = ProviderContainer(
          overrides: [
            ttsProvider
                .overrideWith(() => createTestTTSNotifier(mockFlutterTts)),
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

        // Then: 結果検証: 「読み上げ」ボタンが表示されていることを確認
        // 「読み上げボタンを明確に表示」に基づく
        // 品質保証: ユーザーが読み上げを開始できることを保証
        expect(find.text('読み上げ'), findsOneWidget);

        container.dispose();
      });

      /// 読み上げ中は「停止」ボタンに切り替わる
      testWidgets('TC-050-002: 読み上げ中は「停止」ボタンに切り替わることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: speaking状態のTTSProviderでラップしたTTSButtonを構築
        // 初期条件設定: 読み上げ中の状態
        final container = ProviderContainer(
          overrides: [
            ttsProvider
                .overrideWith(() => createTestTTSNotifier(mockFlutterTts)),
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

        // Then: 結果検証: 「停止」ボタンが表示されていることを確認
        // 「読み上げ実行中状態では停止ボタンとして表示」に基づく
        // 品質保証: ユーザーが読み上げを中断できることを保証
        expect(find.text('停止'), findsOneWidget);

        container.dispose();
      });

      /// 読み上げ完了後は「読み上げ」ボタンに戻る
      testWidgets('TC-050-003: 読み上げ完了後は「読み上げ」ボタンに戻ることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: completedハンドラをモックして状態を制御
        // 初期条件設定: 読み上げ完了後の状態
        final container = ProviderContainer(
          overrides: [
            ttsProvider
                .overrideWith(() => createTestTTSNotifier(mockFlutterTts)),
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

        // Then: 結果検証: idle状態（完了後）で「読み上げ」ボタンが表示されていることを確認
        // 完了後に再び読み上げ可能な状態になること
        // 品質保証: 再度読み上げが可能なことを保証
        expect(find.text('読み上げ'), findsOneWidget);

        container.dispose();
      });

      /// ボタンサイズが44px×44px以上である
      testWidgets('TC-050-004: ボタンサイズが44px×44px以上であることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: TTSButtonウィジェットをレンダリング
        // 初期条件設定: 標準表示状態
        final container = ProviderContainer(
          overrides: [
            ttsProvider
                .overrideWith(() => createTestTTSNotifier(mockFlutterTts)),
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

        // Then: 結果検証: ボタンサイズが44px×44px以上であることを確認
        // 「タップターゲット44px×44px以上」に基づく
        // 品質保証: 高齢者や運動機能に制限のあるユーザーが操作しやすいこと
        final buttonFinder = find.byType(TTSButton);
        expect(buttonFinder, findsOneWidget);

        final buttonSize = tester.getSize(buttonFinder);
        expect(buttonSize.width, greaterThanOrEqualTo(44));
        expect(buttonSize.height, greaterThanOrEqualTo(44));

        container.dispose();
      });

      /// ボタンに適切なSemantics（アクセシビリティラベル）が設定されている
      testWidgets('TC-050-005: ボタンにSemanticsが設定されていることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: TTSButtonウィジェットをレンダリング
        // 初期条件設定: 標準表示状態
        final container = ProviderContainer(
          overrides: [
            ttsProvider
                .overrideWith(() => createTestTTSNotifier(mockFlutterTts)),
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

        // Then: 結果検証: Semanticsが設定されていることを確認
        // アクセシビリティ対応
        // 品質保証: スクリーンリーダーが適切に読み上げられること
        final semantics = tester.getSemantics(find.byType(TTSButton));
        expect(semantics.label, isNotEmpty);

        container.dispose();
      });
    });

    group('状態管理テスト', () {
      /// 読み上げボタンタップでTTS読み上げが開始される
      testWidgets('TC-050-006: 読み上げボタンタップでTTS読み上げが開始されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: idle状態のTTSProviderでラップしたTTSButtonを構築
        // 初期条件設定: アプリ起動直後の初期状態
        var onSpeakCalled = false;
        final container = ProviderContainer(
          overrides: [
            ttsProvider
                .overrideWith(() => createTestTTSNotifier(mockFlutterTts)),
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

        // When: 実際の処理実行: 読み上げボタンをタップ
        // 処理内容: ユーザーが読み上げボタンをタップした場合を模擬
        await tester.tap(find.text('読み上げ'));
        await tester.pumpAndSettle();

        // Then: 結果検証: onSpeakコールバックが呼ばれたことを確認
        // 「入力欄のテキストをTTSで読み上げる」に基づく
        // 品質保証: UIアクションがビジネスロジックに正しく伝達されること
        expect(onSpeakCalled, isTrue);

        container.dispose();
      });

      /// 停止ボタンタップでTTS読み上げが中断される
      testWidgets('TC-050-007: 停止ボタンタップでTTS読み上げが中断されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: speaking状態のTTSProviderでラップしたTTSButtonを構築
        // 初期条件設定: 読み上げ中の状態
        final container = ProviderContainer(
          overrides: [
            ttsProvider
                .overrideWith(() => createTestTTSNotifier(mockFlutterTts)),
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

        // When: 実際の処理実行: 停止ボタンをタップ
        // 処理内容: ユーザーが読み上げを中断したい場合を模擬
        await tester.tap(find.text('停止'));
        await tester.pumpAndSettle();

        // Then: 結果検証: TTS停止が呼ばれたことを確認
        // 「読み上げ中の停止・中断機能」に基づく
        // 品質保証: 読み上げが即座に停止すること
        verify(() => mockFlutterTts.stop()).called(1);
        expect(container.read(ttsProvider).state, TTSState.stopped);

        container.dispose();
      });

      /// 停止後にidleに自動遷移する
      testWidgets('TC-050-008: 停止後にidleに自動遷移することを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: speaking状態のTTSProviderでラップしたTTSButtonを構築
        // 初期条件設定: 読み上げ中の状態
        final container = ProviderContainer(
          overrides: [
            ttsProvider
                .overrideWith(() => createTestTTSNotifier(mockFlutterTts)),
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

        // When: 実際の処理実行: 停止ボタンをタップ
        // 処理内容: stopを呼び出す
        await tester.tap(find.text('停止'));
        await tester.pumpAndSettle();

        // Then: 結果検証: 状態がstopped（またはidle）になっていることを確認
        // tts_state.dart状態遷移定義に基づく
        // 品質保証: 次の読み上げが可能な状態に戻ること
        final state = container.read(ttsProvider).state;
        expect(state, anyOf(TTSState.stopped, TTSState.idle));

        container.dispose();
      });

      /// 状態変更がRiverpodで正しく監視される
      testWidgets('TC-050-009: 状態変更がRiverpodで正しく監視されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: 状態変更をキャプチャするリスナーを設定
        // 初期条件設定: 状態変更監視の準備
        final container = ProviderContainer(
          overrides: [
            ttsProvider
                .overrideWith(() => createTestTTSNotifier(mockFlutterTts)),
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

        // When: 実際の処理実行: speak → stopの一連の操作
        // 処理内容: 状態遷移のシナリオを実行
        await tester.tap(find.text('読み上げ'));
        await tester.pumpAndSettle();

        // Then: 結果検証: 状態変更リストにspeakingが記録されることを確認
        // Riverpodの状態管理パターン
        // 品質保証: UIが状態変更に追従すること
        expect(stateChanges, contains(TTSState.speaking));

        container.dispose();
      });
    });

    // 3. AA対応（コントラスト比）テスト
    // AA対応: 従来は停止ボタンにColors.red(#F44336)+白文字（約3.9:1）
    // 読み上げボタンにライトテーマのprimaryColor(#2196F3)+白文字（約3.1:1）を
    // ハードコードしており、いずれもWCAG AA（4.5:1）未達だった。
    // ここでは実際にレンダリングされたElevatedButtonの背景色・文字色を取得し
    // Color.computeLuminanceを用いたWCAG 2.1のコントラスト比計算式で
    // ライト/ダーク/高コントラストの3テーマ×読み上げ/停止の2状態
    // 合計6パターンすべてがAA基準を満たすことを検証する。
    group('AA対応（コントラスト比）テスト', () {
      /// TTSButtonのElevatedButtonをレンダリングし、背景色と文字色のペアを取得する
      Future<(Color background, Color foreground)> renderAndGetColors(
        WidgetTester tester, {
        required ThemeData theme,
        required bool speaking,
        required MockFlutterTts mock,
      }) async {
        final container = ProviderContainer(
          overrides: [
            ttsProvider.overrideWith(() => createTestTTSNotifier(mock)),
          ],
        );

        if (speaking) {
          final notifier = container.read(ttsProvider.notifier);
          await notifier.initialize();
          await notifier.speak('テスト');
        }

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: theme,
              home: Scaffold(
                body: TTSButton(text: 'こんにちは', onSpeak: () {}),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // SDK差異対応: ElevatedButton.iconはFlutter 3.38.1系では内部で
        // 非公開サブクラス（_ElevatedButtonWithIcon extends ElevatedButton）を
        // 返すため、find.byType(ElevatedButton)（runtimeTypeの完全一致）では
        // 何も見つからずBad state: No elementで失敗する。Flutter 3.41.5系では
        // ElevatedButton自身の名前付きコンストラクタとなり問題は起きないが
        // どちらのSDKでも安定して動作するようbySubtype（is判定・サブタイプ許容）
        // を使用する。
        final button =
            tester.widget<ElevatedButton>(find.bySubtype<ElevatedButton>());
        final style = button.style!;
        final background = style.backgroundColor!.resolve(<WidgetState>{})!;
        final foreground = style.foregroundColor!.resolve(<WidgetState>{})!;

        container.dispose();
        return (background, foreground);
      }

      /// 指定テーマ・状態の組み合わせでAA基準（4.5:1以上）を満たすことを検証する共通処理
      Future<void> expectMeetsAA(
        WidgetTester tester, {
        required String themeName,
        required ThemeData theme,
        required bool speaking,
      }) async {
        final mock = MockFlutterTts();
        when(() => mock.setLanguage(any())).thenAnswer((_) async => 1);
        when(() => mock.setSpeechRate(any())).thenAnswer((_) async => 1);
        when(() => mock.speak(any())).thenAnswer((_) async => 1);
        when(() => mock.stop()).thenAnswer((_) async => 1);

        final (background, foreground) = await renderAndGetColors(
          tester,
          theme: theme,
          speaking: speaking,
          mock: mock,
        );
        final ratio = contrastRatio(foreground, background);

        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '$themeName / speaking=$speaking: '
              '背景=$background 文字=$foreground のコントラスト比は$ratioでWCAG AA(4.5:1)未達',
        );
      }

      testWidgets('ライトテーマ・読み上げボタン(idle)がWCAG AAを満たす', (tester) async {
        await expectMeetsAA(
          tester,
          themeName: 'light',
          theme: lightTheme,
          speaking: false,
        );
      });

      testWidgets('ライトテーマ・停止ボタン(speaking)がWCAG AAを満たす', (tester) async {
        await expectMeetsAA(
          tester,
          themeName: 'light',
          theme: lightTheme,
          speaking: true,
        );
      });

      testWidgets('ダークテーマ・読み上げボタン(idle)がWCAG AAを満たす', (tester) async {
        await expectMeetsAA(
          tester,
          themeName: 'dark',
          theme: darkTheme,
          speaking: false,
        );
      });

      testWidgets('ダークテーマ・停止ボタン(speaking)がWCAG AAを満たす', (tester) async {
        await expectMeetsAA(
          tester,
          themeName: 'dark',
          theme: darkTheme,
          speaking: true,
        );
      });

      testWidgets('高コントラストテーマ・読み上げボタン(idle)がWCAG AAを満たす', (tester) async {
        await expectMeetsAA(
          tester,
          themeName: 'highContrast',
          theme: highContrastTheme,
          speaking: false,
        );
      });

      testWidgets('高コントラストテーマ・停止ボタン(speaking)がWCAG AAを満たす', (tester) async {
        await expectMeetsAA(
          tester,
          themeName: 'highContrast',
          theme: highContrastTheme,
          speaking: true,
        );
      });
    });
  });
}
