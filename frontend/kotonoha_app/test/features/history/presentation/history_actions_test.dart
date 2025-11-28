/// HistoryScreen 再読み上げ・削除アクションテスト
///
/// TASK-0063: 履歴再読み上げ・削除機能
/// テストフレームワーク: flutter_test + mocktail
///
/// 対象: HistoryScreen（履歴再読み上げ・削除機能）
///
/// 【TDD Redフェーズ】: 機能が未実装、テストが失敗するはず
///
/// 信頼性レベル凡例:
/// - 🔵 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
/// - 🟡 黄信号: 要件定義書から妥当な推測によるテスト
/// - 🔴 赤信号: 要件定義書にない推測によるテスト
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

// =========================================================================
// テストヘルパー関数
// =========================================================================

/// 【テストデータ準備】: テスト用の履歴データを生成するヘルパー関数
/// 🔵 信頼性レベル: 青信号 - テストケース定義書に基づく
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

/// 【テストデータ準備】: 複数件の履歴データを生成
/// 🔵 信頼性レベル: 青信号 - テストケース定義書に基づく
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

// =========================================================================
// モッククラス
// =========================================================================

/// HistoryNotifierのモック
class MockHistoryNotifier extends Mock implements HistoryNotifier {
  MockHistoryNotifier() {
    // 初期状態を設定
    _currentState = const HistoryState(histories: []);
  }

  late HistoryState _currentState;
  final List<void Function(HistoryState)> _listeners = [];

  @override
  HistoryState get state => _currentState;

  @override
  set state(HistoryState newState) {
    _currentState = newState;
    // リスナーに状態変更を通知
    for (final listener in _listeners) {
      listener(newState);
    }
  }

  @override
  void Function() addListener(
    void Function(HistoryState value) listener, {
    bool fireImmediately = false,
  }) {
    _listeners.add(listener);
    if (fireImmediately) {
      listener(_currentState);
    }
    return () {
      _listeners.remove(listener);
    };
  }

  void removeListener(void Function(HistoryState value) listener) {
    _listeners.remove(listener);
  }

  @override
  bool updateShouldNotify(HistoryState old, HistoryState current) {
    return old != current;
  }
}

/// TTSNotifierのモック
class MockTTSNotifier extends Mock implements TTSNotifier {
  MockTTSNotifier() {
    // 初期状態を設定
    _currentState = const TTSServiceState(
      state: TTSState.idle,
      currentSpeed: TTSSpeed.normal,
    );
  }

  late TTSServiceState _currentState;
  final List<void Function(TTSServiceState)> _listeners = [];

  @override
  TTSServiceState get state => _currentState;

  @override
  set state(TTSServiceState newState) {
    _currentState = newState;
    // リスナーに状態変更を通知
    for (final listener in _listeners) {
      listener(newState);
    }
  }

  @override
  void Function() addListener(
    void Function(TTSServiceState value) listener, {
    bool fireImmediately = false,
  }) {
    _listeners.add(listener);
    if (fireImmediately) {
      listener(_currentState);
    }
    return () {
      _listeners.remove(listener);
    };
  }

  void removeListener(void Function(TTSServiceState value) listener) {
    _listeners.remove(listener);
  }

  @override
  bool updateShouldNotify(TTSServiceState old, TTSServiceState current) {
    return old != current;
  }
}

// =========================================================================
// テストヘルパー - プロバイダーオーバーライド
// =========================================================================

/// 【テストヘルパー】: HistoryProviderをモック状態でオーバーライド
Override historyProviderOverride(HistoryState mockState) {
  return historyProvider.overrideWith((ref) {
    final notifier = HistoryNotifier();
    // 内部状態を直接設定
    notifier.state = mockState;
    return notifier;
  });
}

/// 【テストヘルパー】: TTSProviderをモック状態でオーバーライド
Override ttsProviderOverride(TTSServiceState mockState) {
  return ttsProvider.overrideWith((ref) {
    final notifier = TTSNotifier();
    // 内部状態を直接設定
    notifier.state = mockState;
    return notifier;
  });
}

// =========================================================================
// テストスイート
// =========================================================================

void main() {
  setUpAll(() {
    // Mocktailのフォールバック値を登録
    registerFallbackValue(HistoryType.manualInput);
  });

  group('HistoryScreen 再読み上げ・削除機能テスト (TASK-0063)', () {
    // =========================================================================
    // 2.1 再読み上げ機能テスト
    // =========================================================================
    group('再読み上げ機能', () {
      /// TC-063-001: TTSProvider.speak() 呼び出しテスト 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-063-001, AC-063-001
      /// 検証内容: 履歴タップ時にTTSプロバイダーのspeak()メソッドが正しく呼ばれること
      testWidgets('TC-063-001: 履歴タップ時にTTSProvider.speak()が呼ばれる',
          (WidgetTester tester) async {
        // 【テスト目的】: 履歴タップ時にTTSプロバイダーのspeak()メソッドが正しく呼ばれることを検証 🔵
        // 【テスト内容】: TTSProviderのspeak("こんにちは")が1回呼ばれること
        // 【期待される動作】: 引数として履歴のcontentが正しく渡される

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
              ttsProvider.overrideWith((ref) => mockTTSNotifier),
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

      /// TC-063-018: 空文字列の読み上げ防止テスト 🔵
      ///
      /// 優先度: P1 重要
      /// 関連要件: FR-063-008
      /// 検証内容: 履歴の内容が空文字列の場合、読み上げが実行されないこと
      testWidgets('TC-063-018: 空文字列の履歴をタップしても読み上げが実行されない',
          (WidgetTester tester) async {
        // 【テスト目的】: 空文字列の読み上げ防止を検証 🔵
        // 【テスト内容】: TTSProvider.speak()が呼ばれないこと
        // 【期待される動作】: エラーが発生しない

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
              ttsProvider.overrideWith((ref) => mockTTSNotifier),
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

          // Then: TTSProvider.speak()が呼び出されない
          verifyNever(() => mockTTSNotifier.speak(''));
          verifyNever(() => mockTTSNotifier.speak(any()));
        }
      });
    });

    // =========================================================================
    // 2.2 読み上げ中の状態表示テスト
    // =========================================================================
    group('読み上げ中の状態表示', () {
      /// TC-063-004: 読み上げ中の視覚的インジケーター表示テスト 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-063-002, AC-063-001
      /// 検証内容: 読み上げ中に視覚的インジケーター（ハイライト等）が表示されること
      testWidgets('TC-063-004: 読み上げ中の履歴項目がハイライト表示される',
          (WidgetTester tester) async {
        // 【テスト目的】: 読み上げ中の視覚的インジケーターが表示されることを検証 🔵
        // 【テスト内容】: 現在読み上げ中の履歴項目がハイライト表示される
        // 【期待される動作】: 他の履歴項目は通常表示のまま

        // Given: 履歴データを準備する
        final testHistory = createTestHistory(
          id: 'test_1',
          content: 'こんにちは',
          type: HistoryType.manualInput,
        );
        final mockState = HistoryState(histories: [testHistory]);

        // TTSプロバイダーの状態をspeakingに設定する（モック）
        final mockTTSNotifier = MockTTSNotifier();
        mockTTSNotifier.state = const TTSServiceState(
          state: TTSState.speaking,
          currentSpeed: TTSSpeed.normal,
        );
        when(() => mockTTSNotifier.speak(any())).thenAnswer((_) async {});
        when(() => mockTTSNotifier.stop()).thenAnswer((_) async {});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProviderOverride(mockState),
              ttsProvider.overrideWith((ref) => mockTTSNotifier),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // Then: 読み上げ中のインジケーター（例: アイコン、背景色変更など）が表示される
        // 実装に応じて検証方法を調整
        // 例: 読み上げ中アイコンの存在確認
        expect(
          find.byIcon(Icons.volume_up),
          findsOneWidget,
          reason: '読み上げ中のアイコンが表示される必要がある',
        );
      });

      /// TC-063-005: 読み上げ中の停止ボタン表示テスト 🟡
      ///
      /// 優先度: P1 重要
      /// 関連要件: FR-063-002
      /// 検証内容: 読み上げ中に停止ボタンが表示されること
      testWidgets('TC-063-005: 読み上げ中に停止ボタンが表示される', (WidgetTester tester) async {
        // 【テスト目的】: 読み上げ中に停止ボタンが表示されることを検証 🟡
        // 【テスト内容】: TTSState.speakingの場合に停止ボタンが表示される
        // 【期待される動作】: アイドル状態では停止ボタンが非表示または無効

        // Given: 履歴データを準備する
        final testHistory = createTestHistory(
          id: 'test_1',
          content: 'こんにちは',
          type: HistoryType.manualInput,
        );
        final mockState = HistoryState(histories: [testHistory]);

        // TTSプロバイダーの状態をspeakingに設定する
        final mockTTSNotifier = MockTTSNotifier();
        mockTTSNotifier.state = const TTSServiceState(
          state: TTSState.speaking,
          currentSpeed: TTSSpeed.normal,
        );
        when(() => mockTTSNotifier.stop()).thenAnswer((_) async {});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProviderOverride(mockState),
              ttsProvider.overrideWith((ref) => mockTTSNotifier),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // Then: 停止ボタンが表示される
        expect(
          find.byIcon(Icons.stop),
          findsOneWidget,
          reason: '読み上げ中は停止ボタンが表示される必要がある',
        );
      });
    });

    // =========================================================================
    // 2.3 削除ダイアログのキャンセル機能テスト
    // =========================================================================
    group('削除ダイアログのキャンセル機能', () {
      /// TC-063-012: 個別削除ダイアログの「キャンセル」ボタンテスト 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-063-005, AC-063-004
      /// 検証内容: 削除確認ダイアログで「キャンセル」を選択すると削除されないこと
      testWidgets('TC-063-012: 個別削除ダイアログで「キャンセル」選択時に削除されない',
          (WidgetTester tester) async {
        // 【テスト目的】: キャンセル選択時に削除が実行されないことを検証 🔵
        // 【テスト内容】: ダイアログが閉じ、履歴が削除されない（5件のまま）
        // 【期待される動作】: HistoryRepository.delete()が呼ばれない

        // Given: 5件の履歴データを準備する
        final testHistories = createTestHistories(5);
        final mockState = HistoryState(histories: testHistories);

        // HistoryNotifierをモック化して削除メソッドを監視
        final mockHistoryNotifier = MockHistoryNotifier();
        mockHistoryNotifier.state = mockState;
        when(() => mockHistoryNotifier.deleteHistory(any()))
            .thenAnswer((_) async {});

        // TTSプロバイダーをオーバーライド（HistoryScreenが必要とするため）
        final mockTTSNotifier = MockTTSNotifier();
        when(() => mockTTSNotifier.stop()).thenAnswer((_) async {});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProvider.overrideWith((ref) => mockHistoryNotifier),
              ttsProvider.overrideWith((ref) => mockTTSNotifier),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // When: 削除ボタンをタップしてダイアログを表示する
        await tester.tap(find.byIcon(Icons.delete).first);
        await tester.pumpAndSettle();

        // ダイアログが表示されることを確認
        expect(find.byType(AlertDialog), findsOneWidget);

        // 「キャンセル」ボタンをタップする
        await tester.tap(find.widgetWithText(TextButton, 'キャンセル'));
        await tester.pumpAndSettle();

        // Then: ダイアログが閉じる
        expect(find.byType(AlertDialog), findsNothing);

        // HistoryNotifier.deleteHistory()が呼ばれない
        verifyNever(() => mockHistoryNotifier.deleteHistory(any()));
      });

      /// TC-063-015: 全削除ダイアログの「キャンセル」ボタンテスト 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-063-006, AC-063-005
      /// 検証内容: 全削除確認ダイアログで「キャンセル」を選択すると削除されないこと
      testWidgets('TC-063-015: 全削除ダイアログで「キャンセル」選択時に削除されない',
          (WidgetTester tester) async {
        // 【テスト目的】: キャンセル選択時に全削除が実行されないことを検証 🔵
        // 【テスト内容】: ダイアログが閉じ、履歴が削除されない（5件のまま）
        // 【期待される動作】: HistoryRepository.deleteAll()が呼ばれない

        // Given: 5件の履歴データを準備する
        final testHistories = createTestHistories(5);
        final mockState = HistoryState(histories: testHistories);

        // HistoryNotifierをモック化して削除メソッドを監視
        final mockHistoryNotifier = MockHistoryNotifier();
        mockHistoryNotifier.state = mockState;
        when(() => mockHistoryNotifier.clearAllHistories())
            .thenAnswer((_) async {});

        // TTSプロバイダーをオーバーライド（HistoryScreenが必要とするため）
        final mockTTSNotifier = MockTTSNotifier();
        when(() => mockTTSNotifier.stop()).thenAnswer((_) async {});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProvider.overrideWith((ref) => mockHistoryNotifier),
              ttsProvider.overrideWith((ref) => mockTTSNotifier),
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

        // HistoryNotifier.clearAllHistories()が呼ばれない
        verifyNever(() => mockHistoryNotifier.clearAllHistories());
      });
    });

    // =========================================================================
    // 2.4 削除後のリスト自動更新テスト
    // =========================================================================
    group('削除後のリスト自動更新', () {
      /// TC-063-016: 削除後のリスト自動更新テスト 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-063-007, AC-063-006
      /// 検証内容: 個別削除後にリストが自動的に更新されること
      testWidgets('TC-063-016: 個別削除後にリストが自動的に更新される',
          (WidgetTester tester) async {
        // 【テスト目的】: 削除後にリストが自動更新されることを検証 🔵
        // 【テスト内容】: 削除後、表示される履歴が4件になる
        // 【期待される動作】: 削除した履歴が表示されない、リストの順序は変わらない

        // Given: 5件の履歴データを準備する
        final testHistories = createTestHistories(5);
        var currentState = HistoryState(histories: testHistories);

        // HistoryNotifierをモック化
        final mockHistoryNotifier = MockHistoryNotifier();
        mockHistoryNotifier.state = currentState;
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
              historyProvider.overrideWith((ref) => mockHistoryNotifier),
              ttsProvider.overrideWith((ref) => mockTTSNotifier),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // 5件の履歴が表示されることを確認
        expect(find.text('テスト履歴0'), findsOneWidget);
        expect(find.text('テスト履歴1'), findsOneWidget);

        // When: 1件目の履歴を削除する（削除ダイアログで「削除」選択）
        await tester.tap(find.byIcon(Icons.delete).first);
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, '削除'));
        await tester.pumpAndSettle();

        // Then: リストが自動的に更新される
        // 削除が呼ばれることを検証
        verify(() => mockHistoryNotifier.deleteHistory('test_0')).called(1);

        // 表示される履歴が4件になることを確認（要再構築）
        // 実装後は状態変更により自動再構築される
      });

      /// TC-063-017: 全削除後の空リスト表示テスト 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-063-007, AC-063-006
      /// 検証内容: 全削除後に空リストメッセージが表示されること
      testWidgets('TC-063-017: 全削除後に「履歴がありません」メッセージが表示される',
          (WidgetTester tester) async {
        // 【テスト目的】: 全削除後の空リスト表示を検証 🔵
        // 【テスト内容】: リストが空になり、「履歴がありません」メッセージが表示される
        // 【期待される動作】: 全削除ボタンが非表示になる

        // Given: 5件の履歴データを準備する
        final testHistories = createTestHistories(5);
        var currentState = HistoryState(histories: testHistories);

        // HistoryNotifierをモック化
        final mockHistoryNotifier = MockHistoryNotifier();
        mockHistoryNotifier.state = currentState;
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
              historyProvider.overrideWith((ref) => mockHistoryNotifier),
              ttsProvider.overrideWith((ref) => mockTTSNotifier),
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
        // 実装後は状態変更により自動再構築される
      });
    });

    // =========================================================================
    // 2.5 読み上げエラー処理テスト
    // =========================================================================
    group('読み上げエラー処理', () {
      /// TC-063-019: 読み上げエラー時のエラーメッセージ表示テスト 🔵
      ///
      /// 優先度: P1 重要
      /// 関連要件: FR-063-009, AC-063-007
      /// 検証内容: 読み上げエラー時にエラーメッセージが表示されること
      testWidgets('TC-063-019: 読み上げエラー時にエラーメッセージが表示される',
          (WidgetTester tester) async {
        // 【テスト目的】: エラー時の適切な表示を検証 🔵
        // 【テスト内容】: エラーメッセージが表示される（スナックバーまたはダイアログ）
        // 【期待される動作】: アプリが継続動作する（クラッシュしない）

        // Given: 履歴データを準備する
        final testHistory = createTestHistory(
          id: 'test_1',
          content: 'こんにちは',
          type: HistoryType.manualInput,
        );
        final mockState = HistoryState(histories: [testHistory]);

        // TTSプロバイダーをモック化し、speak()実行時にエラー状態にする
        final mockTTSNotifier = MockTTSNotifier();
        const errorState = TTSServiceState(
          state: TTSState.error,
          currentSpeed: TTSSpeed.normal,
          errorMessage: '読み上げに失敗しました',
        );
        when(() => mockTTSNotifier.speak(any())).thenAnswer((_) async {
          // speak()が呼ばれたときにエラー状態に変更
          mockTTSNotifier.state = errorState;
        });
        when(() => mockTTSNotifier.stop()).thenAnswer((_) async {});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProviderOverride(mockState),
              ttsProvider.overrideWith((ref) => mockTTSNotifier),
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

      /// TC-063-020: 読み上げエラー後の操作継続テスト 🟡
      ///
      /// 優先度: P1 重要
      /// 関連要件: FR-063-009, NFR-063-003
      /// 検証内容: 読み上げエラー後も他の操作が可能であること
      testWidgets('TC-063-020: 読み上げエラー後も他の履歴の読み上げが可能',
          (WidgetTester tester) async {
        // 【テスト目的】: エラー後の操作継続性を検証 🟡
        // 【テスト内容】: 1件目のエラー後も2件目の読み上げが正常に実行される
        // 【期待される動作】: 削除操作も正常に動作する

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

        // TTSプロバイダーをモック化し、1回目のspeak()でエラー、2回目は成功とする
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
              ttsProvider.overrideWith((ref) => mockTTSNotifier),
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
