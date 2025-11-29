/// エラーダイアログ ウィジェットテスト
///
/// TASK-0078: エラーUI・エラーメッセージ実装
///
/// 関連要件:
/// - NFR-204: 分かりやすい日本語エラーメッセージ
/// - EDGE-001: ネットワークエラー時の再試行オプション
/// - EDGE-002: AI変換エラー時のフォールバック
/// - EDGE-004: TTS再生エラー時のメッセージ
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/widgets/error_dialog.dart';

void main() {
  group('ErrorDialog', () {
    // =========================================================================
    // 基本表示テスト
    // =========================================================================

    group('基本表示テスト', () {
      testWidgets('TC-078-001: エラーダイアログにタイトルとメッセージが表示される', (tester) async {
        // When: エラーダイアログを表示
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showErrorDialog(
                  context: context,
                  title: 'エラー',
                  message: 'エラーが発生しました',
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        );

        // ダイアログを表示
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Then: タイトルとメッセージが表示される
        expect(find.text('エラー'), findsOneWidget);
        expect(find.text('エラーが発生しました'), findsOneWidget);
      });

      testWidgets('TC-078-002: OKボタンでダイアログが閉じる', (tester) async {
        var dialogClosed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await showErrorDialog(
                    context: context,
                    title: 'エラー',
                    message: 'エラーが発生しました',
                  );
                  dialogClosed = true;
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        );

        // ダイアログを表示
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // OKボタンをタップ
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Then: ダイアログが閉じる
        expect(find.text('エラーが発生しました'), findsNothing);
        expect(dialogClosed, isTrue);
      });
    });

    // =========================================================================
    // 再試行オプションテスト
    // =========================================================================

    group('再試行オプションテスト', () {
      testWidgets('TC-078-003: 再試行ボタンが表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showErrorDialog(
                  context: context,
                  title: 'ネットワークエラー',
                  message: '接続できませんでした',
                  showRetry: true,
                  onRetry: () {},
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Then: 再試行ボタンが表示される
        expect(find.text('再試行'), findsOneWidget);
      });

      testWidgets('TC-078-004: 再試行ボタンタップでコールバックが呼ばれる', (tester) async {
        var retryPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showErrorDialog(
                  context: context,
                  title: 'ネットワークエラー',
                  message: '接続できませんでした',
                  showRetry: true,
                  onRetry: () {
                    retryPressed = true;
                  },
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // 再試行ボタンをタップ
        await tester.tap(find.text('再試行'));
        await tester.pumpAndSettle();

        // Then: コールバックが呼ばれる
        expect(retryPressed, isTrue);
      });
    });
  });

  // ===========================================================================
  // ErrorSnackBar テスト
  // ===========================================================================

  group('ErrorSnackBar', () {
    testWidgets('TC-078-005: エラースナックバーが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showErrorSnackBar(
                  context: context,
                  message: 'エラーが発生しました',
                ),
                child: const Text('Show SnackBar'),
              ),
            ),
          ),
        ),
      );

      // スナックバーを表示
      await tester.tap(find.text('Show SnackBar'));
      await tester.pump();

      // Then: スナックバーが表示される
      expect(find.text('エラーが発生しました'), findsOneWidget);
    });

    testWidgets('TC-078-006: スナックバーに再試行ボタンが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showErrorSnackBar(
                  context: context,
                  message: 'エラーが発生しました',
                  showRetry: true,
                  onRetry: () {},
                ),
                child: const Text('Show SnackBar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pump();

      // Then: 再試行ボタンが表示される
      expect(find.text('再試行'), findsOneWidget);
    });
  });

  // ===========================================================================
  // NetworkErrorDialog テスト
  // ===========================================================================

  group('NetworkErrorDialog', () {
    testWidgets('TC-078-007: ネットワークエラーダイアログが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showNetworkErrorDialog(
                context: context,
                onRetry: () {},
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Then: 適切なメッセージが表示される
      expect(find.textContaining('ネットワーク'), findsWidgets);
      expect(find.text('再試行'), findsOneWidget);
    });
  });

  // ===========================================================================
  // AIConversionErrorDialog テスト
  // ===========================================================================

  group('AIConversionErrorDialog', () {
    testWidgets('TC-078-008: AI変換エラーダイアログが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showAIConversionErrorDialog(
                context: context,
                originalText: '元のテキスト',
                onUseOriginal: () {},
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Then: 適切なメッセージと元のテキストを使用ボタンが表示される
      expect(find.textContaining('AI変換'), findsWidgets);
      // 「元のテキストを使用」ボタンが表示される
      expect(find.text('元のテキストを使用'), findsOneWidget);
    });

    testWidgets('TC-078-009: 元のテキストを使用ボタンでコールバックが呼ばれる', (tester) async {
      var useOriginalPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showAIConversionErrorDialog(
                context: context,
                originalText: '元のテキスト',
                onUseOriginal: () {
                  useOriginalPressed = true;
                },
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 元のテキストを使用ボタンをタップ
      await tester.tap(find.text('元のテキストを使用'));
      await tester.pumpAndSettle();

      // Then: コールバックが呼ばれる
      expect(useOriginalPressed, isTrue);
    });
  });

  // ===========================================================================
  // TTSErrorDialog テスト
  // ===========================================================================

  group('TTSErrorDialog', () {
    testWidgets('TC-078-010: TTS再生エラーダイアログが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showTTSErrorDialog(
                context: context,
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Then: 適切なメッセージが表示される
      expect(find.textContaining('読み上げ'), findsWidgets);
    });
  });

  // ===========================================================================
  // 日本語メッセージテスト (NFR-204)
  // ===========================================================================

  group('日本語メッセージテスト', () {
    testWidgets('TC-078-011: エラーメッセージが日本語で表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showNetworkErrorDialog(
                context: context,
                onRetry: () {},
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Then: 日本語のメッセージが含まれている
      // 英語のテキストは含まれない
      expect(find.textContaining('Network'), findsNothing);
      expect(find.textContaining('Error'), findsNothing);
    });
  });
}
