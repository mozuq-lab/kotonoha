/// エラーダイアログ ウィジェットテスト
/// 分かりやすい日本語エラーメッセージ
/// ネットワークエラー時の再試行オプション
/// AI変換エラー時のフォールバック
/// TTS再生エラー時のメッセージ
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/widgets/error_dialog.dart';

void main() {
  // ErrorSnackBar テスト

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

  // TTSErrorDialog テスト

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
}
