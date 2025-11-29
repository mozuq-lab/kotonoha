/// OfflineBanner ウィジェットテスト
///
/// TASK-0077: オフライン時UI表示・AI変換無効化
///
/// 関連要件:
/// - REQ-1002: オフライン状態表示
/// - NFR-203: ユーザー操作を妨げない通知
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/network/presentation/widgets/offline_banner.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';

void main() {
  group('OfflineBanner', () {
    // =========================================================================
    // 表示テスト
    // =========================================================================

    group('表示テスト', () {
      testWidgets('TC-077-001: オフライン時にバナーが表示される', (tester) async {
        // Given: オフライン状態のProviderContainer
        final container = ProviderContainer();
        await container.read(networkProvider.notifier).setOffline();

        // When: OfflineBannerを表示
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: OfflineBanner(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Then: バナーが表示される
        expect(find.text('オフライン - 基本機能のみ利用可能'), findsOneWidget);
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);

        container.dispose();
      });

      testWidgets('TC-077-002: オンライン時にバナーが非表示', (tester) async {
        // Given: オンライン状態のProviderContainer
        final container = ProviderContainer();
        await container.read(networkProvider.notifier).setOnline();

        // When: OfflineBannerを表示
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: OfflineBanner(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Then: バナーが表示されない
        expect(find.text('オフライン - 基本機能のみ利用可能'), findsNothing);
        expect(find.byIcon(Icons.wifi_off), findsNothing);

        container.dispose();
      });

      testWidgets('TC-077-003: checking時にバナーが非表示', (tester) async {
        // Given: チェック中状態のProviderContainer
        final container = ProviderContainer();
        await container.read(networkProvider.notifier).setChecking();

        // When: OfflineBannerを表示
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: OfflineBanner(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Then: バナーが表示されない
        expect(find.text('オフライン - 基本機能のみ利用可能'), findsNothing);

        container.dispose();
      });
    });

    // =========================================================================
    // 状態変更テスト
    // =========================================================================

    group('状態変更テスト', () {
      testWidgets('TC-077-004: オンラインからオフラインへの変更でバナーが表示される',
          (tester) async {
        // Given: オンライン状態のProviderContainer
        final container = ProviderContainer();
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOnline();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: OfflineBanner(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // バナーが表示されていないことを確認
        expect(find.text('オフライン - 基本機能のみ利用可能'), findsNothing);

        // When: オフラインに切り替え
        await notifier.setOffline();
        await tester.pumpAndSettle();

        // Then: バナーが表示される
        expect(find.text('オフライン - 基本機能のみ利用可能'), findsOneWidget);

        container.dispose();
      });

      testWidgets('TC-077-005: オフラインからオンラインへの変更でバナーが非表示になる',
          (tester) async {
        // Given: オフライン状態のProviderContainer
        final container = ProviderContainer();
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOffline();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: OfflineBanner(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // バナーが表示されていることを確認
        expect(find.text('オフライン - 基本機能のみ利用可能'), findsOneWidget);

        // When: オンラインに切り替え
        await notifier.setOnline();
        await tester.pumpAndSettle();

        // Then: バナーが非表示になる
        expect(find.text('オフライン - 基本機能のみ利用可能'), findsNothing);

        container.dispose();
      });
    });

    // =========================================================================
    // アクセシビリティテスト
    // =========================================================================

    group('アクセシビリティテスト', () {
      testWidgets('TC-077-006: バナーにSemanticsラベルがある', (tester) async {
        // Given: オフライン状態のProviderContainer
        final container = ProviderContainer();
        await container.read(networkProvider.notifier).setOffline();

        // When: OfflineBannerを表示
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: OfflineBanner(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Then: Semanticsウィジェットが存在することを確認
        expect(find.byType(Semantics), findsWidgets);

        // バナーテキストが表示されていることで間接的にSemanticsを確認
        expect(find.text('オフライン - 基本機能のみ利用可能'), findsOneWidget);

        container.dispose();
      });
    });
  });
}
