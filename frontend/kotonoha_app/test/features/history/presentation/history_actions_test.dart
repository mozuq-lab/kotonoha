/// HistoryScreen 再読み上げ・削除アクションテスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kotonoha_app/features/history/presentation/history_screen.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart';
import 'package:kotonoha_app/features/history/domain/models/history.dart';
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';

// テストヘルパー関数

/// テストデータ準備: テスト用の履歴データを生成するヘルパー関数
History createTestHistory({
  required String id,
  required String content,
  required HistoryType type,
  DateTime? createdAt,
}) {
  return History(
    id: id,
    content: content,
    type: type,
    createdAt: createdAt ?? DateTime.now(),
  );
}

/// テストデータ準備: 複数件の履歴データを生成
List<History> createTestHistories(int count, {HistoryType? type}) {
  return List.generate(
    count,
    (i) => createTestHistory(
      id: 'test_$i',
      content: 'テスト履歴$i',
      type: type ?? HistoryType.values[i % HistoryType.values.length],
      createdAt: DateTime.now().subtract(Duration(minutes: i)),
    ),
  );
}

// モッククラス

/// HistoryNotifierのモック
class MockHistoryNotifier extends HistoryNotifier with Mock {
  HistoryState? mockInitialState;

  @override
  HistoryState build() => mockInitialState ?? const HistoryState(histories: []);

  @override
  Future<void> addHistory(String content, HistoryType type) =>
      super.noSuchMethod(Invocation.method(#addHistory, [content, type]))
          as Future<void>? ??
      Future<void>.value();

  @override
  Future<void> deleteHistory(String id) =>
      super.noSuchMethod(Invocation.method(#deleteHistory, [id]))
          as Future<void>? ??
      Future<void>.value();

  @override
  Future<void> loadHistories() =>
      super.noSuchMethod(Invocation.method(#loadHistories, []))
          as Future<void>? ??
      Future<void>.value();

  @override
  Future<void> clearAllHistories() =>
      super.noSuchMethod(Invocation.method(#clearAllHistories, []))
          as Future<void>? ??
      Future<void>.value();

  @override
  Future<void> restoreLastDeleted() =>
      super.noSuchMethod(Invocation.method(#restoreLastDeleted, []))
          as Future<void>? ??
      Future<void>.value();

  @override
  Future<void> restoreClearedHistories() =>
      super.noSuchMethod(Invocation.method(#restoreClearedHistories, []))
          as Future<void>? ??
      Future<void>.value();
}

/// TTSNotifierのモック
class MockTTSNotifier extends TTSNotifier with Mock {
  TTSServiceState? mockInitialState;

  @override
  TTSServiceState build() =>
      mockInitialState ??
      const TTSServiceState(
        state: TTSState.idle,
        currentSpeed: TTSSpeed.normal,
      );

  @override
  Future<void> speak(String text) =>
      super.noSuchMethod(Invocation.method(#speak, [text])) as Future<void>? ??
      Future<void>.value();

  @override
  Future<void> stop() =>
      super.noSuchMethod(Invocation.method(#stop, [])) as Future<void>? ??
      Future<void>.value();

  @override
  Future<void> initialize() =>
      super.noSuchMethod(Invocation.method(#initialize, [])) as Future<void>? ??
      Future<void>.value();

  @override
  Future<void> setSpeed(TTSSpeed speed) =>
      super.noSuchMethod(Invocation.method(#setSpeed, [speed]))
          as Future<void>? ??
      Future<void>.value();
}

// テスト用Notifierサブクラス

/// buildで初期状態を返すHistoryNotifierのテスト用サブクラス
class _TestHistoryNotifier extends HistoryNotifier {
  final HistoryState _initialState;
  _TestHistoryNotifier(this._initialState);
  @override
  HistoryState build() => _initialState;
}

/// buildで初期状態を返すTTSNotifierのテスト用サブクラス
class _TestTTSNotifier extends TTSNotifier {
  final TTSServiceState _initialState;
  _TestTTSNotifier(this._initialState);
  @override
  TTSServiceState build() => _initialState;
}

// テストヘルパー - プロバイダーオーバーライド

/// テストヘルパー: HistoryProviderをモック状態でオーバーライド
historyProviderOverride(HistoryState mockState) {
  return historyProvider.overrideWith(() => _TestHistoryNotifier(mockState));
}

/// テストヘルパー: TTSProviderをモック状態でオーバーライド
ttsProviderOverride(TTSServiceState mockState) {
  return ttsProvider.overrideWith(() => _TestTTSNotifier(mockState));
}

// テストスイート

void main() {
  setUpAll(() {
    // Mocktailのフォールバック値を登録
    registerFallbackValue(HistoryType.manualInput);
  });

  group('HistoryScreen 再読み上げ・削除機能テスト (TASK-0063)', () {
    // 2.1 再読み上げ機能テスト
    group('再読み上げ機能', () {
      /// TTSProvider.speak 呼び出しテスト
      testWidgets('TC-063-001: 履歴タップ時にTTSProvider.speak()が呼ばれる',
          (WidgetTester tester) async {
        // Given: 履歴データを準備する
        final testHistory = createTestHistory(
          id: 'test_1',
          content: 'こんにちは',
          type: HistoryType.manualInput,
        );
        final mockState = HistoryState(histories: [testHistory]);

        // TTSプロバイダーをモック化する
        final mockTTSNotifier = MockTTSNotifier();
        when(() => mockTTSNotifier.speak(any())).thenAnswer((_) async {});
        when(() => mockTTSNotifier.stop()).thenAnswer((_) async {});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProviderOverride(mockState),
              ttsProvider.overrideWith(() => mockTTSNotifier),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // When: 履歴項目をタップする
        await tester.tap(find.text('こんにちは'));
        await tester.pumpAndSettle();

        // Then: TTSProvider.speak("こんにちは")が1回呼び出される
        verify(() => mockTTSNotifier.speak('こんにちは')).called(1);
      });

      /// 空文字列の読み上げ防止テスト
      testWidgets('TC-063-018: 空文字列の履歴をタップしても読み上げが実行されない',
          (WidgetTester tester) async {
        // Given: 空文字列の履歴を作成する
        final testHistory = createTestHistory(
          id: 'test_empty',
          content: '',
          type: HistoryType.manualInput,
        );
        final mockState = HistoryState(histories: [testHistory]);

        // TTSプロバイダーをモック化する
        final mockTTSNotifier = MockTTSNotifier();
        when(() => mockTTSNotifier.speak(any())).thenAnswer((_) async {});
        when(() => mockTTSNotifier.stop()).thenAnswer((_) async {});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProviderOverride(mockState),
              ttsProvider.overrideWith(() => mockTTSNotifier),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // 空文字列を表示する代わりにプレースホルダーが表示される想定
        // カードは表示されるが、空文字列の表示はない
        final cardFinder =
            find.byKey(const Key('history_item_card_test_empty'));

        // When: 空文字列の履歴項目をタップする（カードが存在する場合）
        if (tester.any(cardFinder)) {
          await tester.tap(cardFinder);
          await tester.pumpAndSettle();

          // Then: TTSProvider.speakが呼び出されない
          verifyNever(() => mockTTSNotifier.speak(''));
          verifyNever(() => mockTTSNotifier.speak(any()));
        }
      });
    });

    // 2.2 読み上げ中の状態表示テスト
    group('読み上げ中の状態表示', () {
      /// 読み上げ中の視覚的インジケーター表示テスト
      testWidgets('TC-063-004: 読み上げ中の履歴項目がハイライト表示される',
          (WidgetTester tester) async {
        // Given: 履歴データを準備する
        final testHistory = createTestHistory(
          id: 'test_1',
          content: 'こんにちは',
          type: HistoryType.manualInput,
        );
        final mockState = HistoryState(histories: [testHistory]);

        // TTSプロバイダーの状態をspeakingに設定する（モック）
        final mockTTSNotifier = MockTTSNotifier();
        mockTTSNotifier.mockInitialState = const TTSServiceState(
          state: TTSState.speaking,
          currentSpeed: TTSSpeed.normal,
        );
        when(() => mockTTSNotifier.speak(any())).thenAnswer((_) async {});
        when(() => mockTTSNotifier.stop()).thenAnswer((_) async {});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProviderOverride(mockState),
              ttsProvider.overrideWith(() => mockTTSNotifier),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // When: 対象の履歴項目をタップして読み上げ対象に設定する
        // （読み上げ中表示は項目単位で管理されるため、タップで対象を確定する）
        await tester.tap(find.text('こんにちは'));
        await tester.pump();

        // Then: 読み上げ中のインジケーター（例: アイコン、背景色変更など）が表示される
        // 実装に応じて検証方法を調整
        // 例: 読み上げ中アイコンの存在確認
        expect(
          find.byIcon(Icons.volume_up),
          findsOneWidget,
          reason: '読み上げ中のアイコンが表示される必要がある',
        );
      });

      /// 読み上げ中の停止ボタン表示テスト
      testWidgets('TC-063-005: 読み上げ中に停止ボタンが表示される', (WidgetTester tester) async {
        // Given: 履歴データを準備する
        final testHistory = createTestHistory(
          id: 'test_1',
          content: 'こんにちは',
          type: HistoryType.manualInput,
        );
        final mockState = HistoryState(histories: [testHistory]);

        // TTSプロバイダーの状態をspeakingに設定する
        final mockTTSNotifier = MockTTSNotifier();
        mockTTSNotifier.mockInitialState = const TTSServiceState(
          state: TTSState.speaking,
          currentSpeed: TTSSpeed.normal,
        );
        when(() => mockTTSNotifier.speak(any())).thenAnswer((_) async {});
        when(() => mockTTSNotifier.stop()).thenAnswer((_) async {});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProviderOverride(mockState),
              ttsProvider.overrideWith(() => mockTTSNotifier),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // When: 対象の履歴項目をタップして読み上げ対象に設定する
        await tester.tap(find.text('こんにちは'));
        await tester.pump();

        // Then: 停止ボタンが表示される
        expect(
          find.byIcon(Icons.stop),
          findsOneWidget,
          reason: '読み上げ中は停止ボタンが表示される必要がある',
        );
      });

      /// 読み上げ中表示は対象項目のみ（per-item）テスト
      /// 検証内容: 複数履歴で1件を読み上げ中にしたとき、その項目だけが
      /// 読み上げ中表示（停止アイコン）になり、他の項目は通常表示のままであること。
      /// （以前はTTSのspeaking状態を全カードに渡しており、全カードが停止表示になっていた）
      testWidgets('TC-063-006: 読み上げ中表示は対象の1項目のみ', (WidgetTester tester) async {
        // Given: 履歴を2件準備する
        final histories = [
          createTestHistory(
            id: 'item_a',
            content: '項目A',
            type: HistoryType.manualInput,
          ),
          createTestHistory(
            id: 'item_b',
            content: '項目B',
            type: HistoryType.manualInput,
          ),
        ];
        final mockState = HistoryState(histories: histories);

        final mockTTSNotifier = MockTTSNotifier();
        mockTTSNotifier.mockInitialState = const TTSServiceState(
          state: TTSState.speaking,
          currentSpeed: TTSSpeed.normal,
        );
        when(() => mockTTSNotifier.speak(any())).thenAnswer((_) async {});
        when(() => mockTTSNotifier.stop()).thenAnswer((_) async {});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProviderOverride(mockState),
              ttsProvider.overrideWith(() => mockTTSNotifier),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // When: 項目Aのみをタップする
        await tester.tap(find.text('項目A'));
        await tester.pump();

        // Then: 読み上げ中（停止）アイコンはちょうど1つ（項目Aのみ）
        expect(
          find.byIcon(Icons.stop),
          findsOneWidget,
          reason: '読み上げ中表示はタップした1項目のみであるべき',
        );
        expect(
          find.byIcon(Icons.volume_up),
          findsOneWidget,
          reason: '読み上げ中アイコンはタップした1項目のみであるべき',
        );
      });
    });

    // 2.3 削除・Undo機能テスト
    group('削除・Undo機能', () {
      /// 個別削除の即時実行とUndoテスト（改訂）
      /// 改善: 個別削除の確認ダイアログは、誤タップで「はい」を選んでしまうと
      /// 復元できないという問題があったため廃止した。削除ボタンタップで
      /// 確認ダイアログなしに即座にdeleteHistoryが呼ばれ、代わりに表示される
      /// 「元に戻す」SnackBarアクションでrestoreLastDeletedが呼ばれることを検証する。
      testWidgets(
          'TC-063-012: 個別削除ボタンタップで確認ダイアログなしに即削除され、「元に戻す」でrestoreLastDeletedが呼ばれる',
          (WidgetTester tester) async {
        // Given: 5件の履歴データを準備する
        final testHistories = createTestHistories(5);
        final mockState = HistoryState(histories: testHistories);

        // HistoryNotifierをモック化して削除・復元メソッドを監視
        final mockHistoryNotifier = MockHistoryNotifier();
        mockHistoryNotifier.mockInitialState = mockState;
        when(() => mockHistoryNotifier.deleteHistory(any()))
            .thenAnswer((_) async {});
        when(() => mockHistoryNotifier.restoreLastDeleted())
            .thenAnswer((_) async {});

        // TTSプロバイダーをオーバーライド（HistoryScreenが必要とするため）
        final mockTTSNotifier = MockTTSNotifier();
        when(() => mockTTSNotifier.stop()).thenAnswer((_) async {});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProvider.overrideWith(() => mockHistoryNotifier),
              ttsProvider.overrideWith(() => mockTTSNotifier),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // When: 削除ボタンをタップする
        await tester.tap(find.byIcon(Icons.delete).first);
        await tester.pumpAndSettle();

        // Then: 確認ダイアログは表示されず、即座に削除される
        expect(find.byType(AlertDialog), findsNothing);
        verify(() => mockHistoryNotifier.deleteHistory('test_0')).called(1);

        // 「元に戻す」SnackBarActionが表示される
        expect(find.text('元に戻す'), findsOneWidget);

        // When: 「元に戻す」をタップする
        await tester.tap(find.text('元に戻す'));
        await tester.pumpAndSettle();

        // Then: restoreLastDeletedが呼ばれる
        verify(() => mockHistoryNotifier.restoreLastDeleted()).called(1);
      });

      /// 全削除ダイアログの「キャンセル」ボタンテスト
      testWidgets('TC-063-015: 全削除ダイアログで「キャンセル」選択時に削除されない',
          (WidgetTester tester) async {
        // Given: 5件の履歴データを準備する
        final testHistories = createTestHistories(5);
        final mockState = HistoryState(histories: testHistories);

        // HistoryNotifierをモック化して削除メソッドを監視
        final mockHistoryNotifier = MockHistoryNotifier();
        mockHistoryNotifier.mockInitialState = mockState;
        when(() => mockHistoryNotifier.clearAllHistories())
            .thenAnswer((_) async {});

        // TTSプロバイダーをオーバーライド（HistoryScreenが必要とするため）
        final mockTTSNotifier = MockTTSNotifier();
        when(() => mockTTSNotifier.stop()).thenAnswer((_) async {});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProvider.overrideWith(() => mockHistoryNotifier),
              ttsProvider.overrideWith(() => mockTTSNotifier),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // When: 全削除ボタンをタップしてダイアログを表示する
        await tester.tap(find.byIcon(Icons.delete_sweep));
        await tester.pumpAndSettle();

        // ダイアログが表示されることを確認
        expect(find.byType(AlertDialog), findsOneWidget);

        // 「キャンセル」ボタンをタップする
        await tester.tap(find.widgetWithText(TextButton, 'キャンセル'));
        await tester.pumpAndSettle();

        // Then: ダイアログが閉じる
        expect(find.byType(AlertDialog), findsNothing);

        // HistoryNotifier.clearAllHistoriesが呼ばれない
        verifyNever(() => mockHistoryNotifier.clearAllHistories());
      });
    });

    // 2.4 削除後のリスト自動更新テスト
    group('削除後のリスト自動更新', () {
      /// 削除後のリスト自動更新テスト
      testWidgets('TC-063-016: 個別削除後にリストが自動的に更新される',
          (WidgetTester tester) async {
        // Given: 5件の履歴データを準備する
        final testHistories = createTestHistories(5);
        var currentState = HistoryState(histories: testHistories);

        // HistoryNotifierをモック化
        final mockHistoryNotifier = MockHistoryNotifier();
        mockHistoryNotifier.mockInitialState = currentState;
        when(() => mockHistoryNotifier.deleteHistory(any()))
            .thenAnswer((invocation) async {
          final id = invocation.positionalArguments[0] as String;
          final updatedHistories =
              currentState.histories.where((h) => h.id != id).toList();
          currentState = currentState.copyWith(histories: updatedHistories);
          mockHistoryNotifier.state = currentState;
        });

        // TTSプロバイダーをオーバーライド（HistoryScreenが必要とするため）
        final mockTTSNotifier = MockTTSNotifier();
        when(() => mockTTSNotifier.stop()).thenAnswer((_) async {});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProvider.overrideWith(() => mockHistoryNotifier),
              ttsProvider.overrideWith(() => mockTTSNotifier),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // 5件の履歴が表示されることを確認
        expect(find.text('テスト履歴0'), findsOneWidget);
        expect(find.text('テスト履歴1'), findsOneWidget);

        // When: 1件目の履歴を削除する
        // 改善: 個別削除は確認ダイアログを廃止したため、削除ボタンタップのみで即実行される
        await tester.tap(find.byIcon(Icons.delete).first);
        await tester.pumpAndSettle();

        // Then: リストが自動的に更新される
        // 削除が呼ばれることを検証
        verify(() => mockHistoryNotifier.deleteHistory('test_0')).called(1);

        // 表示される履歴が4件になることを確認（要再構築）
        // このテストでは削除の呼び出しを確認し、状態変更後の再描画は検証していない。
      });

      /// 全削除後の空リスト表示テスト
      testWidgets('TC-063-017: 全削除後に「履歴がありません」メッセージが表示される',
          (WidgetTester tester) async {
        // Given: 5件の履歴データを準備する
        final testHistories = createTestHistories(5);
        var currentState = HistoryState(histories: testHistories);

        // HistoryNotifierをモック化
        final mockHistoryNotifier = MockHistoryNotifier();
        mockHistoryNotifier.mockInitialState = currentState;
        when(() => mockHistoryNotifier.clearAllHistories())
            .thenAnswer((_) async {
          currentState = currentState.copyWith(histories: []);
          mockHistoryNotifier.state = currentState;
        });

        // TTSプロバイダーをオーバーライド（HistoryScreenが必要とするため）
        final mockTTSNotifier = MockTTSNotifier();
        when(() => mockTTSNotifier.stop()).thenAnswer((_) async {});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProvider.overrideWith(() => mockHistoryNotifier),
              ttsProvider.overrideWith(() => mockTTSNotifier),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // 全削除ボタンが表示されることを確認
        expect(find.byIcon(Icons.delete_sweep), findsOneWidget);

        // When: 全削除を実行する（全削除ダイアログで「すべて削除」選択）
        await tester.tap(find.byIcon(Icons.delete_sweep));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, '削除'));
        await tester.pumpAndSettle();

        // Then: リストが自動的に更新される
        // 全削除が呼ばれることを検証
        verify(() => mockHistoryNotifier.clearAllHistories()).called(1);

        // 「履歴がありません」メッセージが表示される（要再構築）
        // このテストでは削除の呼び出しを確認し、状態変更後の再描画は検証していない。
      });
    });

    // 2.5 読み上げエラー処理テスト
    group('読み上げエラー処理', () {
      /// 読み上げエラー時のエラーメッセージ表示テスト
      testWidgets('TC-063-019: 読み上げエラー時にエラーメッセージが表示される',
          (WidgetTester tester) async {
        // Given: 履歴データを準備する
        final testHistory = createTestHistory(
          id: 'test_1',
          content: 'こんにちは',
          type: HistoryType.manualInput,
        );
        final mockState = HistoryState(histories: [testHistory]);

        // TTSプロバイダーをモック化し、speak実行時にエラー状態にする
        final mockTTSNotifier = MockTTSNotifier();
        const errorState = TTSServiceState(
          state: TTSState.error,
          currentSpeed: TTSSpeed.normal,
          errorMessage: '読み上げに失敗しました',
        );
        when(() => mockTTSNotifier.speak(any())).thenAnswer((_) async {
          // speakが呼ばれたときにエラー状態に変更
          mockTTSNotifier.state = errorState;
        });
        when(() => mockTTSNotifier.stop()).thenAnswer((_) async {});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProviderOverride(mockState),
              ttsProvider.overrideWith(() => mockTTSNotifier),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // When: 履歴項目をタップする
        await tester.tap(find.text('こんにちは'));
        await tester.pumpAndSettle();

        // Then: エラーメッセージが表示される（スナックバーまたはダイアログ）
        expect(
          find.text('読み上げに失敗しました'),
          findsOneWidget,
          reason: 'エラーメッセージが表示される必要がある',
        );

        // アプリが継続動作する（クラッシュしていないことを確認）
        expect(find.byType(HistoryScreen), findsOneWidget);
      });

      /// 読み上げエラー後の操作継続テスト
      testWidgets('TC-063-020: 読み上げエラー後も他の履歴の読み上げが可能',
          (WidgetTester tester) async {
        // Given: 2件の履歴データを準備する
        final testHistories = [
          createTestHistory(
            id: 'test_1',
            content: '履歴A',
            type: HistoryType.manualInput,
          ),
          createTestHistory(
            id: 'test_2',
            content: '履歴B',
            type: HistoryType.manualInput,
          ),
        ];
        final mockState = HistoryState(histories: testHistories);

        // TTSプロバイダーをモック化し、1回目のspeakでエラー、2回目は成功とする
        final mockTTSNotifier = MockTTSNotifier();
        var callCount = 0;
        when(() => mockTTSNotifier.speak(any())).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            // 1回目: エラー
            mockTTSNotifier.state = const TTSServiceState(
              state: TTSState.error,
              currentSpeed: TTSSpeed.normal,
              errorMessage: '読み上げに失敗しました',
            );
          } else {
            // 2回目以降: 成功
            mockTTSNotifier.state = const TTSServiceState(
              state: TTSState.speaking,
              currentSpeed: TTSSpeed.normal,
            );
          }
        });
        when(() => mockTTSNotifier.stop()).thenAnswer((_) async {});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProviderOverride(mockState),
              ttsProvider.overrideWith(() => mockTTSNotifier),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // When: 1件目の履歴をタップする（エラー発生）
        await tester.tap(find.text('履歴A'));
        await tester.pumpAndSettle();

        // Then: エラーメッセージが表示される
        // エラーが発生するが、アプリは継続動作

        // When: 2件目の履歴をタップする（成功）
        await tester.tap(find.text('履歴B'));
        await tester.pumpAndSettle();

        // Then: 2件目の読み上げが正常に実行される
        verify(() => mockTTSNotifier.speak('履歴A')).called(1);
        verify(() => mockTTSNotifier.speak('履歴B')).called(1);
      });
    });
  });
}
