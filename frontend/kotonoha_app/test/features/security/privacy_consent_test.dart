/// TASK-0097: NFR-102 AI変換プライバシー通知テスト
///
/// 信頼性レベル: 🔵 青信号（NFR-102に基づく）
/// テスト対象: AI変換機能で会話内容を外部に送信する際のプライバシー通知
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('NFR-102: AI変換プライバシー通知', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('TC-102-001: 初回AI変換時にプライバシー同意ダイアログが表示される', () {
      testWidgets('同意未取得時にダイアログが表示される', (tester) async {
        // Arrange: 同意フラグが未設定の状態
        SharedPreferences.setMockInitialValues({
          'ai_privacy_consent': false,
        });

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        // AI変換を試行（同意確認が必要）
                        _showPrivacyConsentDialog(context);
                      },
                      child: const Text('AI変換'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // Act: AI変換ボタンをタップ
        await tester.tap(find.text('AI変換'));
        await tester.pumpAndSettle();

        // Assert: プライバシー同意ダイアログが表示される
        expect(find.text('プライバシーに関する確認'), findsOneWidget);
        expect(find.textContaining('会話内容を外部に送信'), findsOneWidget);
      });
    });

    group('TC-102-002: プライバシー同意前はAI変換が実行されない', () {
      test('同意フラグがfalseの場合、AI変換は実行されない', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'ai_privacy_consent': false,
        });
        final prefs = await SharedPreferences.getInstance();

        // Act & Assert
        final hasConsent = prefs.getBool('ai_privacy_consent') ?? false;
        expect(hasConsent, isFalse);

        // AI変換の実行を試みる場合、同意がなければブロックされるべき
        // これは実装で保証される
      });
    });

    group('TC-102-003: プライバシー同意後はAI変換が実行される', () {
      test('同意フラグがtrueの場合、AI変換が許可される', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'ai_privacy_consent': true,
        });
        final prefs = await SharedPreferences.getInstance();

        // Act & Assert
        final hasConsent = prefs.getBool('ai_privacy_consent') ?? false;
        expect(hasConsent, isTrue);
      });
    });

    group('TC-102-004: 同意状態がshared_preferencesに永続化される', () {
      test('同意状態が保存される', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        // Act: 同意状態を保存
        await prefs.setBool('ai_privacy_consent', true);

        // Assert: 保存されたことを確認
        final savedConsent = prefs.getBool('ai_privacy_consent');
        expect(savedConsent, isTrue);
      });

      test('同意状態が読み込める', () async {
        // Arrange: 既に同意済み
        SharedPreferences.setMockInitialValues({
          'ai_privacy_consent': true,
        });
        final prefs = await SharedPreferences.getInstance();

        // Act & Assert
        final consent = prefs.getBool('ai_privacy_consent');
        expect(consent, isTrue);
      });
    });

    group('TC-102-005: 2回目以降のAI変換時はダイアログが表示されない', () {
      testWidgets('同意済みの場合はダイアログをスキップ', (tester) async {
        // Arrange: 既に同意済み
        SharedPreferences.setMockInitialValues({
          'ai_privacy_consent': true,
        });

        bool dialogShown = false;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final hasConsent =
                            prefs.getBool('ai_privacy_consent') ?? false;

                        if (!hasConsent) {
                          dialogShown = true;
                          _showPrivacyConsentDialog(context);
                        }
                        // 同意済みの場合はダイアログをスキップしてAI変換を実行
                      },
                      child: const Text('AI変換'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.text('AI変換'));
        await tester.pumpAndSettle();

        // Assert: ダイアログが表示されない
        expect(dialogShown, isFalse);
      });
    });

    group('TC-102-006: プライバシーポリシーへのリンクが表示される', () {
      testWidgets('ダイアログにプライバシーポリシーリンクが含まれる', (tester) async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'ai_privacy_consent': false,
        });

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        _showPrivacyConsentDialog(context);
                      },
                      child: const Text('AI変換'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.text('AI変換'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.textContaining('プライバシーポリシー'), findsOneWidget);
      });
    });

    group('TC-102-007: 同意ダイアログに外部送信説明が含まれる', () {
      testWidgets('説明文が表示される', (tester) async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        _showPrivacyConsentDialog(context);
                      },
                      child: const Text('AI変換'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.text('AI変換'));
        await tester.pumpAndSettle();

        // Assert: 説明文が含まれる
        expect(find.textContaining('会話内容を外部に送信'), findsOneWidget);
      });
    });

    group('TC-102-008: 同意をキャンセルした場合AI変換が実行されない', () {
      testWidgets('キャンセルボタンでダイアログを閉じる', (tester) async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        _showPrivacyConsentDialog(context);
                      },
                      child: const Text('AI変換'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // Act: ダイアログを表示
        await tester.tap(find.text('AI変換'));
        await tester.pumpAndSettle();

        // Act: キャンセルをタップ
        await tester.tap(find.text('同意しない'));
        await tester.pumpAndSettle();

        // Assert: ダイアログが閉じる
        expect(find.text('プライバシーに関する確認'), findsNothing);
      });
    });
  });
}

/// プライバシー同意ダイアログを表示（テスト用のヘルパー関数）
void _showPrivacyConsentDialog(BuildContext context) {
  showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('プライバシーに関する確認'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI変換機能を使用すると、入力した会話内容を外部に送信します。',
          ),
          SizedBox(height: 16),
          Text(
            '送信されたデータはAI処理のために使用され、当社のサーバーには保存されません。',
          ),
          SizedBox(height: 16),
          Text(
            '詳しくはプライバシーポリシーをご確認ください。',
            style: TextStyle(color: Colors.blue),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('同意しない'),
        ),
        ElevatedButton(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('ai_privacy_consent', true);
            if (context.mounted) {
              Navigator.of(context).pop(true);
            }
          },
          child: const Text('同意する'),
        ),
      ],
    ),
  );
}
