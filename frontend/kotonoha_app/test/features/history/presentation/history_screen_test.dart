/// HistoryScreen ウィジェットテスト
///
/// TASK-0061: 履歴一覧UI実装
/// テストフレームワーク: flutter_test + mocktail
///
/// 対象: HistoryScreen（履歴一覧画面）
///
/// 【TDD Redフェーズ】: UIが未実装、テストが失敗するはず
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
class MockHistoryNotifier extends Mock implements HistoryNotifier {}

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

// =========================================================================
// テストスイート
// =========================================================================

void main() {
  setUpAll(() {
    // Mocktailのフォールバック値を登録
    registerFallbackValue(HistoryType.manualInput);
  });

  group('HistoryScreen 表示テスト', () {
    // =========================================================================
    // 1.1 正常系テスト - 履歴一覧表示
    // =========================================================================
    group('履歴一覧表示', () {
      /// TC-061-001: 履歴一覧が正しく表示される 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-061-001, AC-061-001
      /// 検証内容: HistoryScreenが履歴リストを正しく表示すること
      testWidgets('TC-061-001: 履歴一覧が時系列順（新しい順）に正しく表示される',
          (WidgetTester tester) async {
        // 【テスト目的】: 履歴一覧が時系列順（新しい順）に正しく表示される 🔵
        // 【テスト内容】: 5件の履歴データが新しい順でリスト形式で表示される
        // 【期待される動作】: 渡された履歴データが新しい順でリスト形式で表示される

        // Given: 5件の履歴データ（異なる日時）を準備する
        final testHistories = createTestHistories(5);
        final mockState = HistoryState(histories: testHistories);

        // ProviderScopeでラップし、モックデータを注入
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // Then: 5件すべての履歴が表示される
        for (int i = 0; i < 5; i++) {
          expect(
            find.text('テスト履歴$i'),
            findsOneWidget,
            reason: '履歴項目「テスト履歴$i」が表示される必要がある',
          );
        }

        // 各履歴項目にテキスト内容が表示される
        expect(
          find.textContaining('テスト履歴'),
          findsNWidgets(5),
          reason: '5件の履歴項目が表示される必要がある',
        );
      });

      /// TC-061-002: 履歴項目に日時が表示される 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-061-002, NFR-061-005
      /// 検証内容: 日時フォーマットの正確性
      testWidgets('TC-061-002: 各履歴項目に「MM/DD HH:mm」形式で日時が表示される',
          (WidgetTester tester) async {
        // 【テスト目的】: 日時フォーマットの確認 🔵
        // 【テスト内容】: 日時が読みやすい形式で表示される
        // 【期待される動作】: 日時が読みやすい形式で表示される

        // Given: 特定日時の履歴データを作成する
        final testDate = DateTime(2024, 11, 28, 14, 30);
        final testHistory = createTestHistory(
          id: 'test_1',
          content: 'こんにちは',
          type: HistoryType.manualInput,
          createdAt: testDate,
        );
        final mockState = HistoryState(histories: [testHistory]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // Then: 「11/28 14:30」と表示される
        expect(
          find.text('11/28 14:30'),
          findsOneWidget,
          reason: '日時が「MM/DD HH:mm」形式で表示される必要がある',
        );
      });

      /// TC-061-003: 履歴の種類アイコンが表示される 🟡
      ///
      /// 優先度: P1 重要
      /// 関連要件: NFR-061-008
      /// 検証内容: 履歴種類の視覚的区別
      testWidgets('TC-061-003: 各履歴項目に種類に応じたアイコンが表示される',
          (WidgetTester tester) async {
        // 【テスト目的】: 履歴種類の視覚的区別 🟡
        // 【テスト内容】: 履歴種類に応じたアイコンが表示される
        // 【期待される動作】: 履歴種類に応じたアイコンが表示される

        // Given: 異なる種類の履歴を作成する
        final testHistories = [
          createTestHistory(
            id: 'test_1',
            content: '文字盤入力',
            type: HistoryType.manualInput,
          ),
          createTestHistory(
            id: 'test_2',
            content: '定型文',
            type: HistoryType.preset,
          ),
          createTestHistory(
            id: 'test_3',
            content: 'AI変換結果',
            type: HistoryType.aiConverted,
          ),
          createTestHistory(
            id: 'test_4',
            content: '大ボタン',
            type: HistoryType.quickButton,
          ),
        ];
        final mockState = HistoryState(histories: testHistories);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // Then: 各アイコンの存在を確認する
        // 文字盤入力: キーボードアイコン
        expect(
          find.byIcon(Icons.keyboard),
          findsOneWidget,
          reason: '文字盤入力のキーボードアイコンが表示される必要がある',
        );

        // 定型文: リストアイコン
        expect(
          find.byIcon(Icons.list),
          findsOneWidget,
          reason: '定型文のリストアイコンが表示される必要がある',
        );

        // AI変換結果: AIアイコン
        expect(
          find.byIcon(Icons.auto_awesome),
          findsOneWidget,
          reason: 'AI変換結果のAIアイコンが表示される必要がある',
        );

        // 大ボタン: ボタンアイコン
        expect(
          find.byIcon(Icons.smart_button),
          findsOneWidget,
          reason: '大ボタンのボタンアイコンが表示される必要がある',
        );
      });

      /// TC-061-004: スクロール可能なリスト表示 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-061-005
      /// 検証内容: ListView.builderによるスクロール可能なリスト実装
      testWidgets('TC-061-004: 履歴一覧がスクロール可能であること',
          (WidgetTester tester) async {
        // 【テスト目的】: スクロール機能の確認 🔵
        // 【テスト内容】: ListView.builderによるスクロール可能なリスト実装
        // 【期待される動作】: 履歴が多数ある場合にスクロール可能

        // Given: 20件の履歴データを準備する
        final testHistories = createTestHistories(20);
        final mockState = HistoryState(histories: testHistories);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // Then: ListViewウィジェットが使用されている
        expect(
          find.byType(ListView),
          findsOneWidget,
          reason: 'ListViewウィジェットが使用されている必要がある',
        );
      });
    });

    // =========================================================================
    // 1.2 空状態テスト
    // =========================================================================
    group('空状態表示', () {
      /// TC-061-005: 履歴0件で空状態メッセージ表示 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-061-004, AC-061-002, EDGE-061-004
      /// 検証内容: 空リスト時の表示
      testWidgets('TC-061-005: 履歴が0件の場合「履歴がありません」と表示される',
          (WidgetTester tester) async {
        // 【テスト目的】: 空状態の適切な表示確認 🔵
        // 【テスト内容】: EmptyHistoryWidgetが表示される
        // 【期待される動作】: EmptyHistoryWidgetが表示される

        // Given: 空の履歴リストを準備する
        const mockState = HistoryState(histories: []);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // Then: 「履歴がありません」メッセージが画面中央に表示される
        expect(
          find.text('履歴がありません'),
          findsOneWidget,
          reason: '空状態メッセージ「履歴がありません」が表示される必要がある',
        );

        // 全削除ボタンが非表示になる
        expect(
          find.text('全削除'),
          findsNothing,
          reason: '空状態では全削除ボタンが非表示である必要がある',
        );
      });
    });

    // =========================================================================
    // 1.3 再読み上げ機能テスト
    // =========================================================================
    group('再読み上げ機能', () {
      /// TC-061-006: 履歴項目タップで再読み上げが実行される 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-061-006, AC-061-003
      /// 検証内容: 再読み上げ機能のインタラクション
      testWidgets('TC-061-006: 履歴項目をタップすると即座にTTS読み上げが開始される',
          (WidgetTester tester) async {
        // 【テスト目的】: タップインタラクションの確認 🔵
        // 【テスト内容】: タップ時にTTSプロバイダーのspeakメソッドが呼び出される
        // 【期待される動作】: タップ時にTTSプロバイダーのspeakメソッドが呼び出される

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

        // Then: TTSプロバイダーのspeakメソッドが1回呼び出される
        verify(() => mockTTSNotifier.speak('こんにちは')).called(1);
      });
    });

    // =========================================================================
    // 1.4 削除機能テスト
    // =========================================================================
    group('削除機能', () {
      /// TC-061-008: 個別削除ボタンをタップすると確認ダイアログが表示される 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-061-008, AC-061-004
      /// 検証内容: 削除確認ダイアログの表示
      testWidgets('TC-061-008: 履歴項目の削除ボタンをタップすると確認ダイアログが表示される',
          (WidgetTester tester) async {
        // 【テスト目的】: 誤操作防止のための確認ダイアログ表示確認 🔵
        // 【テスト内容】: 確認ダイアログが表示され、削除とキャンセルボタンが存在する
        // 【期待される動作】: 確認ダイアログが表示され、削除とキャンセルボタンが存在する

        // Given: 履歴データを準備する
        final testHistory = createTestHistory(
          id: 'test_1',
          content: 'こんにちは',
          type: HistoryType.manualInput,
        );
        final mockState = HistoryState(histories: [testHistory]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // When: 履歴項目の削除ボタンをタップする
        await tester.tap(find.byIcon(Icons.delete));
        await tester.pumpAndSettle();

        // Then: AlertDialogが表示される
        expect(
          find.byType(AlertDialog),
          findsOneWidget,
          reason: '確認ダイアログが表示される必要がある',
        );

        // 「この履歴を削除しますか?」メッセージが表示される
        expect(
          find.text('この履歴を削除しますか?'),
          findsOneWidget,
          reason: '確認メッセージが表示される必要がある',
        );

        // 「削除」ボタンが表示される
        expect(
          find.widgetWithText(TextButton, '削除'),
          findsOneWidget,
          reason: '削除ボタンが表示される必要がある',
        );

        // 「キャンセル」ボタンが表示される
        expect(
          find.widgetWithText(TextButton, 'キャンセル'),
          findsOneWidget,
          reason: 'キャンセルボタンが表示される必要がある',
        );
      });

      /// TC-061-011: 全削除ボタンが表示される 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-061-009
      /// 検証内容: 全削除ボタンの表示条件
      testWidgets('TC-061-011: 履歴が1件以上存在する場合、AppBarに全削除ボタンが表示される',
          (WidgetTester tester) async {
        // 【テスト目的】: 全削除ボタンの表示確認 🔵
        // 【テスト内容】: 履歴が存在する場合のみ全削除ボタンが表示される
        // 【期待される動作】: 履歴が存在する場合のみ全削除ボタンが表示される

        // Given: 履歴データを準備する
        final testHistory = createTestHistory(
          id: 'test_1',
          content: 'こんにちは',
          type: HistoryType.manualInput,
        );
        final mockState = HistoryState(histories: [testHistory]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // Then: AppBarのアクションエリアに全削除ボタン（またはアイコン）が表示される
        expect(
          find.byIcon(Icons.delete_sweep),
          findsOneWidget,
          reason: '全削除ボタンが表示される必要がある',
        );
      });

      /// TC-061-012: 全削除ボタンをタップすると確認ダイアログが表示される 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-061-010, AC-061-005
      /// 検証内容: 全削除確認ダイアログの表示
      testWidgets('TC-061-012: 全削除ボタンをタップすると確認ダイアログが表示される',
          (WidgetTester tester) async {
        // 【テスト目的】: 全削除確認ダイアログの表示確認 🔵
        // 【テスト内容】: 全削除の確認ダイアログが表示される
        // 【期待される動作】: 全削除の確認ダイアログが表示される

        // Given: 複数件の履歴データを準備する
        final testHistories = createTestHistories(5);
        final mockState = HistoryState(histories: testHistories);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // When: 全削除ボタンをタップする
        await tester.tap(find.byIcon(Icons.delete_sweep));
        await tester.pumpAndSettle();

        // Then: AlertDialogが表示される
        expect(
          find.byType(AlertDialog),
          findsOneWidget,
          reason: '確認ダイアログが表示される必要がある',
        );

        // 「すべての履歴を削除しますか?」メッセージが表示される
        expect(
          find.text('すべての履歴を削除しますか?'),
          findsOneWidget,
          reason: '確認メッセージが表示される必要がある',
        );

        // 「削除」ボタンが表示される
        expect(
          find.widgetWithText(TextButton, '削除'),
          findsOneWidget,
          reason: '削除ボタンが表示される必要がある',
        );

        // 「キャンセル」ボタンが表示される
        expect(
          find.widgetWithText(TextButton, 'キャンセル'),
          findsOneWidget,
          reason: 'キャンセルボタンが表示される必要がある',
        );
      });

      /// TC-061-015: 削除確認ダイアログ外タップで閉じない 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-061-008, REQ-5002
      /// 検証内容: 誤操作防止（barrierDismissible: false）
      testWidgets('TC-061-015: 削除確認ダイアログ外をタップしてもダイアログが閉じない',
          (WidgetTester tester) async {
        // 【テスト目的】: 誤操作防止の確認 🔵
        // 【テスト内容】: バリアタップでダイアログが閉じない
        // 【期待される動作】: バリアタップでダイアログが閉じない

        // Given: 履歴データを準備する
        final testHistory = createTestHistory(
          id: 'test_1',
          content: 'こんにちは',
          type: HistoryType.manualInput,
        );
        final mockState = HistoryState(histories: [testHistory]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // When: 削除ボタンをタップしてダイアログを表示する
        await tester.tap(find.byIcon(Icons.delete));
        await tester.pumpAndSettle();

        // ダイアログ外（バリア部分）をタップする
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // Then: ダイアログが閉じず、引き続き表示される
        expect(
          find.byType(AlertDialog),
          findsOneWidget,
          reason: 'ダイアログが閉じず、引き続き表示される必要がある',
        );
      });
    });

    // =========================================================================
    // 1.5 パフォーマンステスト
    // =========================================================================
    group('パフォーマンステスト', () {
      /// TC-061-016: 50件の履歴を1秒以内に表示する 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: NFR-061-001, AC-061-006
      /// 検証内容: 表示パフォーマンス
      testWidgets('TC-061-016: 履歴50件を1秒以内に表示できること',
          (WidgetTester tester) async {
        // 【テスト目的】: パフォーマンス要件の確認 🔵
        // 【テスト内容】: 上限件数でも高速表示
        // 【期待される動作】: 上限件数でも高速表示

        // Given: 50件の履歴データを準備する
        final testHistories = createTestHistories(50);
        final mockState = HistoryState(histories: testHistories);

        // When: 開始時刻を記録する
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Then: 表示完了までの時間が1秒以内
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1000),
          reason: '50件の履歴を1秒以内に表示する必要がある',
        );
      });
    });

    // =========================================================================
    // 1.6 アクセシビリティテスト
    // =========================================================================
    group('アクセシビリティテスト', () {
      /// TC-061-017: タップターゲットサイズが44px以上 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: NFR-061-004, AC-061-007
      /// 検証内容: アクセシビリティ要件のタップターゲットサイズ
      testWidgets('TC-061-017: 履歴項目のタップターゲットが44px以上',
          (WidgetTester tester) async {
        // 【テスト目的】: アクセシビリティ要件の確認 🔵
        // 【テスト内容】: 各項目の高さが44px以上
        // 【期待される動作】: 各項目の高さが44px以上

        // Given: 履歴データを準備する
        final testHistory = createTestHistory(
          id: 'test_1',
          content: 'こんにちは',
          type: HistoryType.manualInput,
        );
        final mockState = HistoryState(histories: [testHistory]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              historyProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: HistoryScreen(),
            ),
          ),
        );

        // When: HistoryItemCardの高さを測定する
        final cardFinder = find.byKey(const Key('history_item_card_test_1'));
        expect(cardFinder, findsOneWidget);

        final cardSize = tester.getSize(cardFinder);

        // Then: カードの高さが44px以上
        expect(
          cardSize.height,
          greaterThanOrEqualTo(44.0),
          reason: 'カードの高さが44px以上である必要がある',
        );
      });
    });
  });
}
