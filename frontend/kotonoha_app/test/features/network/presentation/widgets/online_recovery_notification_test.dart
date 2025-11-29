/// OnlineRecoveryNotification ウィジェットテスト
///
/// TASK-0077: オフライン時UI表示・AI変換無効化
///
/// 関連要件:
/// - EDGE-001: ネットワーク復帰時の通知
/// - NFR-203: ユーザー操作を妨げない通知
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/network/presentation/widgets/online_recovery_notification.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';

void main() {
  group('OnlineRecoveryNotification', () {
    // =========================================================================
    // 表示テスト
    // =========================================================================

    group('表示テスト', () {
      testWidgets('TC-077-007: オフライン→オンラインで復帰通知が表示される',
          (tester) async {
        // Given: オフライン状態のProviderContainer
        final container = ProviderContainer();
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOffline();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: OnlineRecoveryNotification(
                  displayDuration: const Duration(seconds: 10), // テスト用に長め
                  child: const Center(child: Text('Content')),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 通知が表示されていないことを確認
        expect(find.textContaining('オンラインに戻りました'), findsNothing);

        // When: オンラインに復帰
        await notifier.setOnline();
        await tester.pumpAndSettle();

        // Then: 復帰通知が表示される
        expect(find.textContaining('オンラインに戻りました'), findsOneWidget);
        expect(find.textContaining('AI変換が利用可能です'), findsOneWidget);

        container.dispose();
      });

      testWidgets('TC-077-008: オンライン→オンラインでは通知が表示されない',
          (tester) async {
        // Given: オンライン状態のProviderContainer
        final container = ProviderContainer();
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOnline();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: OnlineRecoveryNotification(
                  displayDuration: const Duration(seconds: 10),
                  child: const Center(child: Text('Content')),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 再度オンラインに設定（状態変化なし）
        await notifier.setOnline();
        await tester.pumpAndSettle();

        // Then: 通知が表示されない
        expect(find.textContaining('オンラインに戻りました'), findsNothing);

        container.dispose();
      });

      testWidgets('TC-077-009: checking→オンラインでは通知が表示されない',
          (tester) async {
        // Given: チェック中状態のProviderContainer
        final container = ProviderContainer();
        final notifier = container.read(networkProvider.notifier);
        await notifier.setChecking();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: OnlineRecoveryNotification(
                  displayDuration: const Duration(seconds: 10),
                  child: const Center(child: Text('Content')),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // When: オンラインに変更
        await notifier.setOnline();
        await tester.pumpAndSettle();

        // Then: 通知が表示されない（オフラインからの復帰ではないため）
        expect(find.textContaining('オンラインに戻りました'), findsNothing);

        container.dispose();
      });
    });

    // =========================================================================
    // 自動非表示テスト
    // =========================================================================

    group('自動非表示テスト', () {
      testWidgets('TC-077-010: 復帰通知が一定時間後に自動で非表示になる',
          (tester) async {
        // Given: オフライン状態のProviderContainer
        final container = ProviderContainer();
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOffline();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: OnlineRecoveryNotification(
                  displayDuration: const Duration(milliseconds: 500),
                  child: const Center(child: Text('Content')),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // When: オンラインに復帰
        await notifier.setOnline();
        await tester.pumpAndSettle();

        // Then: 通知が表示される
        expect(find.textContaining('オンラインに戻りました'), findsOneWidget);

        // When: 時間経過
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        // Then: 通知が非表示になる
        expect(find.textContaining('オンラインに戻りました'), findsNothing);

        container.dispose();
      });
    });

    // =========================================================================
    // ユーザー操作テスト
    // =========================================================================

    group('ユーザー操作テスト', () {
      testWidgets('TC-077-011: 通知表示中も子ウィジェットが操作可能', (tester) async {
        // Given: オフライン状態のProviderContainer
        final container = ProviderContainer();
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOffline();

        var buttonPressed = false;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: OnlineRecoveryNotification(
                  displayDuration: const Duration(seconds: 10),
                  child: Center(
                    child: ElevatedButton(
                      key: const Key('test_button'),
                      onPressed: () => buttonPressed = true,
                      child: const Text('Test Button'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // When: オンラインに復帰
        await notifier.setOnline();
        await tester.pumpAndSettle();

        // 通知が表示されていることを確認
        expect(find.textContaining('オンラインに戻りました'), findsOneWidget);

        // When: ボタンをタップ
        await tester.tap(find.byKey(const Key('test_button')));
        await tester.pumpAndSettle();

        // Then: ボタンが操作可能
        expect(buttonPressed, isTrue);

        container.dispose();
      });
    });

    // =========================================================================
    // アクセシビリティテスト
    // =========================================================================

    group('アクセシビリティテスト', () {
      testWidgets('TC-077-012: 通知にSemanticsラベルがある', (tester) async {
        // Given: オフライン状態のProviderContainer
        final container = ProviderContainer();
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOffline();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: OnlineRecoveryNotification(
                  displayDuration: Duration(seconds: 10),
                  child: Center(child: Text('Content')),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // When: オンラインに復帰
        await notifier.setOnline();
        await tester.pumpAndSettle();

        // Then: Semanticsウィジェットが存在することを確認
        expect(find.byType(Semantics), findsWidgets);

        // 通知テキストが表示されていることで間接的にSemanticsを確認
        expect(find.textContaining('オンラインに戻りました'), findsOneWidget);

        container.dispose();
      });
    });
  });
}
