/// TASK-0058: オフライン動作確認 - UIコンポーネントテスト
///
/// 関連要件: REQ-1002, REQ-3004, EDGE-001
/// フェーズ: TDD Red（失敗するテストの作成）
///
/// このテストは、オフライン状態のUI表示（インジケーター、通知）と
/// AI変換ボタンの視覚的無効化を検証します。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';
import 'package:kotonoha_app/features/network/domain/models/network_state.dart';

void main() {
  group('TASK-0058: オフライン動作確認 - UIコンポーネントテスト', () {
    // =========================================================================
    // 4. オフライン表示インジケーターテスト
    // =========================================================================

    group('4. オフライン表示インジケーターテスト', () {
      /// TC-058-032: オフライン時に「オフライン」インジケーターが表示される
      ///
      /// 優先度: P0
      /// 関連要件: REQ-1002, EDGE-001
      /// 信頼性レベル: 🔵
      ///
      /// 注: このテストは実際のインジケーターウィジェット実装後に動作します
      testWidgets('TC-058-032: オフライン時に「オフライン」インジケーターが表示される',
          (WidgetTester tester) async {
        // Given: NetworkStateがofflineのProviderContainer
        final container = ProviderContainer();
        await container.read(networkProvider.notifier).setOffline();

        // When: オフラインインジケーターウィジェットを表示
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    final networkState = ref.watch(networkProvider);

                    // 注: 実際のOfflineIndicatorウィジェットの実装後、
                    // ここでOfflineIndicatorウィジェットを使用する予定
                    // 現時点では、ネットワーク状態をTextで表示するだけ
                    return Center(
                      child: Text(
                        networkState == NetworkState.offline
                            ? 'オフライン - 基本機能のみ利用可能'
                            : '',
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Then: 「オフライン」インジケーターが表示される
        expect(find.textContaining('オフライン'), findsOneWidget,
            reason: 'オフライン時は「オフライン」インジケーターが表示される必要がある');

        // Cleanup
        container.dispose();
      });

      /// TC-058-033: オフライン時に「基本機能のみ利用可能」メッセージが表示される
      ///
      /// 優先度: P0
      /// 関連要件: REQ-1002
      /// 信頼性レベル: 🔵
      testWidgets('TC-058-033: オフライン時に「基本機能のみ利用可能」メッセージが表示される',
          (WidgetTester tester) async {
        // Given: NetworkStateがofflineのProviderContainer
        final container = ProviderContainer();
        await container.read(networkProvider.notifier).setOffline();

        // When: オフラインインジケーターウィジェットを表示
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    final networkState = ref.watch(networkProvider);

                    return Center(
                      child: Text(
                        networkState == NetworkState.offline
                            ? 'オフライン - 基本機能のみ利用可能'
                            : '',
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Then: 「基本機能のみ利用可能」メッセージが表示される
        expect(find.textContaining('基本機能のみ利用可能'), findsOneWidget,
            reason: 'オフライン時は「基本機能のみ利用可能」メッセージが表示される必要がある');

        // Cleanup
        container.dispose();
      });

      /// TC-058-034: オンライン時にオフラインインジケーターが非表示
      ///
      /// 優先度: P0
      /// 関連要件: REQ-1002
      /// 信頼性レベル: 🔵
      testWidgets('TC-058-034: オンライン時にオフラインインジケーターが非表示',
          (WidgetTester tester) async {
        // Given: NetworkStateがonlineのProviderContainer
        final container = ProviderContainer();
        await container.read(networkProvider.notifier).setOnline();

        // When: オフラインインジケーターウィジェットを表示
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    final networkState = ref.watch(networkProvider);

                    return Center(
                      child: Text(
                        networkState == NetworkState.offline
                            ? 'オフライン - 基本機能のみ利用可能'
                            : '',
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Then: オフラインインジケーターが表示されない
        expect(find.textContaining('オフライン'), findsNothing,
            reason: 'オンライン時はオフラインインジケーターが表示されない必要がある');

        // Cleanup
        container.dispose();
      });

      /// TC-058-035: オフライン通知がユーザー操作を妨げない
      ///
      /// 優先度: P0
      /// 関連要件: NFR-203
      /// 信頼性レベル: 🔵
      testWidgets('TC-058-035: オフライン通知がユーザー操作を妨げない',
          (WidgetTester tester) async {
        // Given: NetworkStateがofflineのProviderContainer
        final container = ProviderContainer();
        await container.read(networkProvider.notifier).setOffline();

        var buttonPressed = false;

        // When: オフラインインジケーターとボタンを含む画面を表示
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    // オフラインインジケーター（画面上部）
                    Consumer(
                      builder: (context, ref, child) {
                        final networkState = ref.watch(networkProvider);
                        return networkState == NetworkState.offline
                            ? Container(
                                color: Colors.grey[300],
                                padding: const EdgeInsets.all(8),
                                child: const Text('オフライン - 基本機能のみ利用可能'),
                              )
                            : const SizedBox.shrink();
                      },
                    ),
                    // テストボタン
                    Expanded(
                      child: Center(
                        child: ElevatedButton(
                          key: const Key('test_button'),
                          onPressed: () {
                            buttonPressed = true;
                          },
                          child: const Text('テストボタン'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Then: オフラインインジケーターが表示される
        expect(find.textContaining('オフライン'), findsOneWidget);

        // And: ボタンがタップ可能
        await tester.tap(find.byKey(const Key('test_button')));
        await tester.pumpAndSettle();

        expect(buttonPressed, true,
            reason: 'オフラインインジケーターが表示されていてもボタンはタップ可能である必要がある');

        // Cleanup
        container.dispose();
      });
    });

    // =========================================================================
    // 5. オンライン復帰通知テスト
    // =========================================================================

    group('5. オンライン復帰通知テスト', () {
      /// TC-058-036: オンライン復帰時に「オンラインに戻りました」通知が表示される
      ///
      /// 優先度: P1
      /// 関連要件: EDGE-001
      /// 信頼性レベル: 🔵
      ///
      /// 注: このテストは実際の通知ウィジェット実装後に動作します
      testWidgets('TC-058-036: オンライン復帰時に「オンラインに戻りました」通知が表示される',
          (WidgetTester tester) async {
        // Given: NetworkStateがofflineのProviderContainer
        final container = ProviderContainer();
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOffline();

        // When: オンライン復帰通知ウィジェットを表示
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: _OnlineRecoveryTestWidget(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // When: オンラインに復帰
        await notifier.setOnline();
        await tester.pumpAndSettle();

        // Then: 「オンラインに戻りました」通知が表示される
        expect(find.textContaining('オンラインに戻りました'), findsOneWidget,
            reason: 'オンライン復帰時は「オンラインに戻りました」通知が表示される必要がある');

        // Cleanup
        container.dispose();
      });

      /// TC-058-037: オンライン復帰時に「AI変換が利用可能です」メッセージが表示される
      ///
      /// 優先度: P1
      /// 関連要件: EDGE-001
      /// 信頼性レベル: 🔵
      testWidgets('TC-058-037: オンライン復帰時に「AI変換が利用可能です」メッセージが表示される',
          (WidgetTester tester) async {
        // Given: NetworkStateがofflineのProviderContainer
        final container = ProviderContainer();
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOffline();

        // When: オンライン復帰通知ウィジェットを表示
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: _OnlineRecoveryTestWidget(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // When: オンラインに復帰
        await notifier.setOnline();
        await tester.pumpAndSettle();

        // Then: 「AI変換が利用可能です」メッセージが表示される
        expect(find.textContaining('AI変換が利用可能です'), findsOneWidget,
            reason: 'オンライン復帰時は「AI変換が利用可能です」メッセージが表示される必要がある');

        // Cleanup
        container.dispose();
      });

      /// TC-058-038: オンライン復帰通知がユーザー操作を妨げない
      ///
      /// 優先度: P1
      /// 関連要件: NFR-203
      /// 信頼性レベル: 🔵
      testWidgets('TC-058-038: オンライン復帰通知がユーザー操作を妨げない',
          (WidgetTester tester) async {
        // Given: NetworkStateがofflineのProviderContainer
        final container = ProviderContainer();
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOffline();

        var buttonPressed = false;

        // When: オンライン復帰通知とボタンを含む画面を表示
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: _OnlineRecoveryWithButtonTestWidget(
                  onButtonPressed: () {
                    buttonPressed = true;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // When: オンラインに復帰
        await notifier.setOnline();
        await tester.pumpAndSettle();

        // Then: オンライン復帰通知が表示される
        expect(find.textContaining('オンラインに戻りました'), findsOneWidget);

        // And: ボタンがタップ可能
        await tester.tap(find.byKey(const Key('test_button')));
        await tester.pumpAndSettle();

        expect(buttonPressed, true,
            reason: 'オンライン復帰通知が表示されていてもボタンはタップ可能である必要がある');

        // Cleanup
        container.dispose();
      });
    });

    // =========================================================================
    // 7. AI変換ボタンの視覚的無効化テスト
    // =========================================================================

    group('7. AI変換ボタンの視覚的無効化テスト', () {
      /// TC-058-AI-001: オフライン時にAI変換ボタンの視覚的無効化（カスタムテスト）
      ///
      /// 優先度: P0
      /// 関連要件: REQ-1002, REQ-3004
      /// 信頼性レベル: 🔵
      ///
      /// 注: このテストは実際のAI変換ボタンウィジェット実装後に動作します
      testWidgets('TC-058-AI-001: オフライン時にAI変換ボタンの視覚的無効化（カスタムテスト）',
          (WidgetTester tester) async {
        // Given: NetworkStateがofflineのProviderContainer
        final container = ProviderContainer();
        await container.read(networkProvider.notifier).setOffline();

        // When: AI変換ボタンを含む画面を表示
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final networkNotifier =
                          ref.read(networkProvider.notifier);
                      final isAIAvailable =
                          networkNotifier.isAIConversionAvailable;

                      // 注: 実際のAI変換ボタンウィジェットの実装後、
                      // ここでAIConversionButtonウィジェットを使用する予定
                      // 現時点では、シンプルなElevatedButtonで代用
                      return ElevatedButton(
                        key: const Key('ai_conversion_button'),
                        onPressed: isAIAvailable ? () {} : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isAIAvailable ? Colors.blue : Colors.grey,
                        ),
                        child: const Text('AI変換'),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Then: AI変換ボタンが無効化されている
        final aiButton = tester.widget<ElevatedButton>(
            find.byKey(const Key('ai_conversion_button')));
        expect(aiButton.onPressed, isNull,
            reason: 'オフライン時はAI変換ボタンのonPressedがnullである必要がある（無効化）');

        // Cleanup
        container.dispose();
      });

      /// TC-058-AI-002: オンライン時にAI変換ボタンの視覚的有効化（カスタムテスト）
      ///
      /// 優先度: P0
      /// 関連要件: REQ-1002
      /// 信頼性レベル: 🔵
      testWidgets('TC-058-AI-002: オンライン時にAI変換ボタンの視覚的有効化（カスタムテスト）',
          (WidgetTester tester) async {
        // Given: NetworkStateがonlineのProviderContainer
        final container = ProviderContainer();
        await container.read(networkProvider.notifier).setOnline();

        // When: AI変換ボタンを含む画面を表示
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Consumer(
                    builder: (context, ref, child) {
                      // ref.watch()を使用してNetworkStateの変更を監視
                      final networkState = ref.watch(networkProvider);
                      final isAIAvailable = networkState == NetworkState.online;

                      return ElevatedButton(
                        key: const Key('ai_conversion_button'),
                        onPressed: isAIAvailable ? () {} : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isAIAvailable ? Colors.blue : Colors.grey,
                        ),
                        child: const Text('AI変換'),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Then: AI変換ボタンが有効化されている
        final aiButton = tester.widget<ElevatedButton>(
            find.byKey(const Key('ai_conversion_button')));
        expect(aiButton.onPressed, isNotNull,
            reason: 'オンライン時はAI変換ボタンのonPressedがnullでない必要がある（有効化）');

        // Cleanup
        container.dispose();
      });

      /// TC-058-AI-003: ネットワーク状態変更でボタンが動的に更新（カスタムテスト）
      ///
      /// 優先度: P0
      /// 関連要件: REQ-1002
      /// 信頼性レベル: 🔵
      testWidgets('TC-058-AI-003: ネットワーク状態変更でボタンが動的に更新（カスタムテスト）',
          (WidgetTester tester) async {
        // Given: NetworkStateがonlineのProviderContainer
        final container = ProviderContainer();
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOnline();

        // When: AI変換ボタンを含む画面を表示
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Consumer(
                    builder: (context, ref, child) {
                      // ref.watch()を使用してNetworkStateの変更を監視
                      final networkState = ref.watch(networkProvider);
                      final isAIAvailable = networkState == NetworkState.online;

                      return ElevatedButton(
                        key: const Key('ai_conversion_button'),
                        onPressed: isAIAvailable ? () {} : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isAIAvailable ? Colors.blue : Colors.grey,
                        ),
                        child: const Text('AI変換'),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Then: オンライン時はボタンが有効
        var aiButton = tester.widget<ElevatedButton>(
            find.byKey(const Key('ai_conversion_button')));
        expect(aiButton.onPressed, isNotNull, reason: 'オンライン時はボタンが有効');

        // When: オフラインに切り替え
        await notifier.setOffline();
        await tester.pumpAndSettle();

        // Then: ボタンが無効化される
        aiButton = tester.widget<ElevatedButton>(
            find.byKey(const Key('ai_conversion_button')));
        expect(aiButton.onPressed, isNull, reason: 'オフライン時はボタンが無効');

        // When: 再度オンラインに切り替え
        await notifier.setOnline();
        await tester.pumpAndSettle();

        // Then: ボタンが再度有効化される
        aiButton = tester.widget<ElevatedButton>(
            find.byKey(const Key('ai_conversion_button')));
        expect(aiButton.onPressed, isNotNull, reason: '再度オンライン時はボタンが有効');

        // Cleanup
        container.dispose();
      });
    });
  });
}

/// テスト用ヘルパーウィジェット: オンライン復帰通知を表示するStatefulWidget
class _OnlineRecoveryTestWidget extends StatefulWidget {
  const _OnlineRecoveryTestWidget();

  @override
  State<_OnlineRecoveryTestWidget> createState() =>
      _OnlineRecoveryTestWidgetState();
}

class _OnlineRecoveryTestWidgetState extends State<_OnlineRecoveryTestWidget> {
  String? _notificationMessage;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        ref.listen<NetworkState>(
          networkProvider,
          (previous, next) {
            if (previous == NetworkState.offline &&
                next == NetworkState.online) {
              setState(() {
                _notificationMessage = 'オンラインに戻りました。AI変換が利用可能です';
              });
            }
          },
        );

        return Center(
          child: Text(_notificationMessage ?? ''),
        );
      },
    );
  }
}

/// テスト用ヘルパーウィジェット: オンライン復帰通知とボタンを含むStatefulWidget
class _OnlineRecoveryWithButtonTestWidget extends StatefulWidget {
  final VoidCallback onButtonPressed;

  const _OnlineRecoveryWithButtonTestWidget({
    required this.onButtonPressed,
  });

  @override
  State<_OnlineRecoveryWithButtonTestWidget> createState() =>
      _OnlineRecoveryWithButtonTestWidgetState();
}

class _OnlineRecoveryWithButtonTestWidgetState
    extends State<_OnlineRecoveryWithButtonTestWidget> {
  String? _notificationMessage;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        ref.listen<NetworkState>(
          networkProvider,
          (previous, next) {
            if (previous == NetworkState.offline &&
                next == NetworkState.online) {
              setState(() {
                _notificationMessage = 'オンラインに戻りました。AI変換が利用可能です';
              });
            }
          },
        );

        return Column(
          children: [
            // 通知メッセージ（画面上部に表示）
            if (_notificationMessage != null)
              Container(
                color: Colors.green[300],
                padding: const EdgeInsets.all(8),
                child: Text(_notificationMessage!),
              ),
            // テストボタン
            Expanded(
              child: Center(
                child: ElevatedButton(
                  key: const Key('test_button'),
                  onPressed: widget.onButtonPressed,
                  child: const Text('テストボタン'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
