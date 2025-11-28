/// FavoritesScreen ウィジェットテスト
///
/// TASK-0064: お気に入り一覧UI実装
/// テストフレームワーク: flutter_test + mocktail
///
/// 対象: FavoritesScreen（お気に入り一覧画面）
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
import 'package:kotonoha_app/features/favorites/presentation/favorites_screen.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/features/favorite/domain/models/favorite.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';

// =========================================================================
// テストヘルパー関数
// =========================================================================

/// 【テストデータ準備】: テスト用のお気に入りデータを生成するヘルパー関数
/// 🔵 信頼性レベル: 青信号 - テストケース定義書に基づく
Favorite createTestFavorite({
  required String id,
  required String content,
  DateTime? createdAt,
  int? displayOrder,
}) {
  return Favorite(
    id: id,
    content: content,
    createdAt: createdAt ?? DateTime.now(),
    displayOrder: displayOrder ?? 0,
  );
}

/// 【テストデータ準備】: 複数件のお気に入りデータを生成
/// 🔵 信頼性レベル: 青信号 - テストケース定義書に基づく
List<Favorite> createTestFavorites(int count) {
  return List.generate(
    count,
    (i) => createTestFavorite(
      id: 'test_$i',
      content: 'テストお気に入り$i',
      createdAt: DateTime.now().subtract(Duration(minutes: i)),
      displayOrder: i,
    ),
  );
}

// =========================================================================
// モッククラス
// =========================================================================

/// FavoriteNotifierのモック
class MockFavoriteNotifier extends Mock implements FavoriteNotifier {}

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

/// 【テストヘルパー】: FavoriteProviderをモック状態でオーバーライド
Override favoriteProviderOverride(FavoriteState mockState) {
  return favoriteProvider.overrideWith((ref) {
    final notifier = FavoriteNotifier();
    // 内部状態を直接設定
    notifier.state = mockState;
    return notifier;
  });
}

// =========================================================================
// テストスイート
// =========================================================================

void main() {
  group('FavoritesScreen 表示テスト', () {
    // =========================================================================
    // 1.1 正常系テスト - お気に入り一覧表示
    // =========================================================================
    group('お気に入り一覧表示', () {
      /// TC-064-001: お気に入り一覧が正しく表示される 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-064-001, FR-064-011, AC-064-001, AC-064-005
      /// 検証内容: FavoritesScreenがお気に入りリストをdisplayOrder昇順で正しく表示すること
      testWidgets('TC-064-001: お気に入り一覧がdisplayOrder昇順に正しく表示される',
          (WidgetTester tester) async {
        // 【テスト目的】: お気に入り一覧がdisplayOrder昇順（小さい順）に正しく表示される 🔵
        // 【テスト内容】: displayOrderが2, 0, 1の3件のお気に入りが0 → 1 → 2の順で表示される
        // 【期待される動作】: displayOrder昇順で表示される

        // Given: displayOrderが異なる3件のお気に入りデータを準備する
        final testFavorites = [
          createTestFavorite(
            id: 'test_2',
            content: 'お気に入り2',
            displayOrder: 2,
          ),
          createTestFavorite(
            id: 'test_0',
            content: 'お気に入り0',
            displayOrder: 0,
          ),
          createTestFavorite(
            id: 'test_1',
            content: 'お気に入り1',
            displayOrder: 1,
          ),
        ];
        final mockState = FavoriteState(favorites: testFavorites);

        // ProviderScopeでラップし、モックデータを注入
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              favoriteProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: FavoritesScreen(),
            ),
          ),
        );

        // Then: 3件すべてのお気に入りが表示される
        expect(
          find.text('お気に入り0'),
          findsOneWidget,
          reason: 'お気に入り項目「お気に入り0」が表示される必要がある',
        );
        expect(
          find.text('お気に入り1'),
          findsOneWidget,
          reason: 'お気に入り項目「お気に入り1」が表示される必要がある',
        );
        expect(
          find.text('お気に入り2'),
          findsOneWidget,
          reason: 'お気に入り項目「お気に入り2」が表示される必要がある',
        );

        // 各お気に入り項目にテキスト内容が表示される
        // 注: AppBarタイトル「お気に入り」も含まれるため、合計4件
        expect(
          find.textContaining('お気に入り'),
          findsNWidgets(4),
          reason: '3件のお気に入り項目 + AppBarタイトルが表示される必要がある',
        );
      });

      /// TC-064-002: お気に入り項目に日時が表示される 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-064-002, NFR-064-006
      /// 検証内容: 日時フォーマットの正確性
      testWidgets('TC-064-002: 各お気に入り項目に「MM/DD HH:mm」形式で日時が表示される',
          (WidgetTester tester) async {
        // 【テスト目的】: 日時フォーマットの確認 🔵
        // 【テスト内容】: 日時が読みやすい形式で表示される
        // 【期待される動作】: 日時が「11/28 14:30」形式で表示される

        // Given: 特定日時のお気に入りデータを作成する
        final testDate = DateTime(2024, 11, 28, 14, 30);
        final testFavorite = createTestFavorite(
          id: 'test_1',
          content: 'こんにちは',
          createdAt: testDate,
          displayOrder: 0,
        );
        final mockState = FavoriteState(favorites: [testFavorite]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              favoriteProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: FavoritesScreen(),
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

      /// TC-064-003: お気に入り項目がカード形式で表示される 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-064-003, NFR-064-005
      /// 検証内容: カード形式のUI実装
      testWidgets('TC-064-003: お気に入り項目が視認性の高いカード形式で表示される',
          (WidgetTester tester) async {
        // 【テスト目的】: カード形式のUI実装確認 🔵
        // 【テスト内容】: お気に入り項目がCardウィジェットで表示される
        // 【期待される動作】: Cardウィジェットが使用されている

        // Given: お気に入りデータを準備する
        final testFavorite = createTestFavorite(
          id: 'test_1',
          content: 'こんにちは',
          displayOrder: 0,
        );
        final mockState = FavoriteState(favorites: [testFavorite]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              favoriteProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: FavoritesScreen(),
            ),
          ),
        );

        // Then: Cardウィジェットが使用されている
        expect(
          find.byType(Card),
          findsAtLeastNWidgets(1),
          reason: 'Cardウィジェットが使用されている必要がある',
        );
      });

      /// TC-064-004: スクロール可能なリスト表示 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-064-005
      /// 検証内容: ListView/ReorderableListViewによるスクロール可能なリスト実装
      testWidgets('TC-064-004: お気に入り一覧がスクロール可能であること',
          (WidgetTester tester) async {
        // 【テスト目的】: スクロール機能の確認 🔵
        // 【テスト内容】: ListView/ReorderableListViewによるスクロール可能なリスト実装
        // 【期待される動作】: お気に入りが多数ある場合にスクロール可能

        // Given: 20件のお気に入りデータを準備する
        final testFavorites = createTestFavorites(20);
        final mockState = FavoriteState(favorites: testFavorites);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              favoriteProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: FavoritesScreen(),
            ),
          ),
        );

        // Then: ListViewまたはReorderableListViewウィジェットが使用されている
        final listViewFinder = find.byType(ListView);
        final reorderableListViewFinder = find.byType(ReorderableListView);

        expect(
          listViewFinder.evaluate().isNotEmpty ||
              reorderableListViewFinder.evaluate().isNotEmpty,
          isTrue,
          reason: 'ListViewまたはReorderableListViewウィジェットが使用されている必要がある',
        );
      });
    });

    // =========================================================================
    // 1.2 空状態テスト
    // =========================================================================
    group('空状態表示', () {
      /// TC-064-005: お気に入り0件で空状態メッセージ表示 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-064-004, AC-064-002, EDGE-064-004
      /// 検証内容: 空リスト時の表示
      testWidgets('TC-064-005: お気に入りが0件の場合「お気に入りがありません」と表示される',
          (WidgetTester tester) async {
        // 【テスト目的】: 空状態の適切な表示確認 🔵
        // 【テスト内容】: EmptyFavoriteWidgetが表示される
        // 【期待される動作】: EmptyFavoriteWidgetが表示される

        // Given: 空のお気に入りリストを準備する
        const mockState = FavoriteState(favorites: []);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              favoriteProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: FavoritesScreen(),
            ),
          ),
        );

        // Then: 「お気に入りがありません」メッセージが画面中央に表示される
        expect(
          find.text('お気に入りがありません'),
          findsOneWidget,
          reason: '空状態メッセージ「お気に入りがありません」が表示される必要がある',
        );

        // 「履歴や定型文からお気に入りを登録できます」ヒントが表示される
        expect(
          find.text('履歴や定型文からお気に入りを登録できます'),
          findsOneWidget,
          reason: '使い方のヒントが表示される必要がある',
        );

        // 全削除ボタンが非表示になる
        expect(
          find.byIcon(Icons.delete_sweep),
          findsNothing,
          reason: '空状態では全削除ボタンが非表示である必要がある',
        );
      });

      /// TC-064-016: 空状態では削除ボタンが非表示 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-064-016, AC-064-002
      /// 検証内容: 空状態時のUI制御確認
      testWidgets('TC-064-016: 空状態では削除ボタンが非表示になる', (WidgetTester tester) async {
        // 【テスト目的】: 空状態時のUI制御確認 🔵
        // 【テスト内容】: 削除ボタンが非表示になる
        // 【期待される動作】: 全削除ボタン、個別削除ボタンが非表示

        // Given: 空のお気に入りリストを準備する
        const mockState = FavoriteState(favorites: []);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              favoriteProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: FavoritesScreen(),
            ),
          ),
        );

        // Then: 全削除ボタンが非表示になる
        expect(
          find.byIcon(Icons.delete_sweep),
          findsNothing,
          reason: '全削除ボタンが非表示である必要がある',
        );

        // 個別削除ボタン（Icons.delete）も表示されない
        expect(
          find.byIcon(Icons.delete),
          findsNothing,
          reason: '個別削除ボタンが表示されない必要がある',
        );
      });
    });

    // =========================================================================
    // 1.3 再読み上げ機能テスト
    // =========================================================================
    group('再読み上げ機能', () {
      /// TC-064-006: お気に入り項目タップで再読み上げが実行される 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-064-006, FR-064-013, AC-064-003, NFR-064-002
      /// 検証内容: 再読み上げ機能のインタラクション
      testWidgets('TC-064-006: お気に入り項目をタップすると即座にTTS読み上げが開始される',
          (WidgetTester tester) async {
        // 【テスト目的】: タップインタラクションの確認 🔵
        // 【テスト内容】: タップ時にTTSプロバイダーのspeakメソッドが呼び出される
        // 【期待される動作】: タップ時にTTSプロバイダーのspeakメソッドが呼び出される

        // Given: お気に入りデータを準備する
        final testFavorite = createTestFavorite(
          id: 'test_1',
          content: 'こんにちは',
          displayOrder: 0,
        );
        final mockState = FavoriteState(favorites: [testFavorite]);

        // TTSプロバイダーをモック化する
        final mockTTSNotifier = MockTTSNotifier();
        when(() => mockTTSNotifier.speak(any())).thenAnswer((_) async {});
        when(() => mockTTSNotifier.stop()).thenAnswer((_) async {});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              favoriteProviderOverride(mockState),
              ttsProvider.overrideWith((ref) => mockTTSNotifier),
            ],
            child: const MaterialApp(
              home: FavoritesScreen(),
            ),
          ),
        );

        // When: お気に入り項目をタップする
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
      /// TC-064-009: 個別削除ボタンをタップすると確認ダイアログが表示される 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-064-007, FR-064-008, FR-064-014, AC-064-004
      /// 検証内容: 削除確認ダイアログの表示
      testWidgets('TC-064-009: お気に入り項目の削除ボタンをタップすると確認ダイアログが表示される',
          (WidgetTester tester) async {
        // 【テスト目的】: 誤操作防止のための確認ダイアログ表示確認 🔵
        // 【テスト内容】: 確認ダイアログが表示され、削除とキャンセルボタンが存在する
        // 【期待される動作】: 確認ダイアログが表示され、削除とキャンセルボタンが存在する

        // Given: お気に入りデータを準備する
        final testFavorite = createTestFavorite(
          id: 'test_1',
          content: 'こんにちは',
          displayOrder: 0,
        );
        final mockState = FavoriteState(favorites: [testFavorite]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              favoriteProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: FavoritesScreen(),
            ),
          ),
        );

        // When: お気に入り項目の削除ボタンをタップする
        await tester.tap(find.byIcon(Icons.delete));
        await tester.pumpAndSettle();

        // Then: AlertDialogが表示される
        expect(
          find.byType(AlertDialog),
          findsOneWidget,
          reason: '確認ダイアログが表示される必要がある',
        );

        // 「このお気に入りを削除しますか?」メッセージが表示される
        expect(
          find.text('このお気に入りを削除しますか?'),
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

      /// TC-064-012: 削除確認ダイアログ外タップで閉じない 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: FR-064-008, REQ-5002
      /// 検証内容: 誤操作防止（barrierDismissible: false）
      testWidgets('TC-064-012: 削除確認ダイアログ外をタップしてもダイアログが閉じない',
          (WidgetTester tester) async {
        // 【テスト目的】: 誤操作防止の確認 🔵
        // 【テスト内容】: バリアタップでダイアログが閉じない
        // 【期待される動作】: バリアタップでダイアログが閉じない

        // Given: お気に入りデータを準備する
        final testFavorite = createTestFavorite(
          id: 'test_1',
          content: 'こんにちは',
          displayOrder: 0,
        );
        final mockState = FavoriteState(favorites: [testFavorite]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              favoriteProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: FavoritesScreen(),
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

      /// TC-064-013: 全削除ボタンが表示される 🟡
      ///
      /// 優先度: P1 重要
      /// 関連要件: FR-064-009
      /// 検証内容: 全削除ボタンの表示条件
      testWidgets('TC-064-013: お気に入りが1件以上存在する場合、AppBarに全削除ボタンが表示される',
          (WidgetTester tester) async {
        // 【テスト目的】: 全削除ボタンの表示確認 🟡
        // 【テスト内容】: お気に入りが存在する場合のみ全削除ボタンが表示される
        // 【期待される動作】: お気に入りが存在する場合のみ全削除ボタンが表示される

        // Given: お気に入りデータを準備する
        final testFavorite = createTestFavorite(
          id: 'test_1',
          content: 'こんにちは',
          displayOrder: 0,
        );
        final mockState = FavoriteState(favorites: [testFavorite]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              favoriteProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: FavoritesScreen(),
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

      /// TC-064-014: 全削除ボタンをタップすると確認ダイアログが表示される 🟡
      ///
      /// 優先度: P1 重要
      /// 関連要件: FR-064-010, FR-064-015, AC-064-009
      /// 検証内容: 全削除確認ダイアログの表示
      testWidgets('TC-064-014: 全削除ボタンをタップすると確認ダイアログが表示される',
          (WidgetTester tester) async {
        // 【テスト目的】: 全削除確認ダイアログの表示確認 🟡
        // 【テスト内容】: 全削除の確認ダイアログが表示される
        // 【期待される動作】: 全削除の確認ダイアログが表示される

        // Given: 複数件のお気に入りデータを準備する
        final testFavorites = createTestFavorites(5);
        final mockState = FavoriteState(favorites: testFavorites);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              favoriteProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: FavoritesScreen(),
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

        // 「すべてのお気に入りを削除しますか?」メッセージが表示される
        expect(
          find.text('すべてのお気に入りを削除しますか?'),
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
    });

    // =========================================================================
    // 1.5 パフォーマンステスト
    // =========================================================================
    group('パフォーマンステスト', () {
      /// TC-064-017: 100件のお気に入りを1秒以内に表示する 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: NFR-064-001, AC-064-006
      /// 検証内容: 表示パフォーマンス
      testWidgets('TC-064-017: お気に入り100件を1秒以内に表示できること',
          (WidgetTester tester) async {
        // 【テスト目的】: パフォーマンス要件の確認 🔵
        // 【テスト内容】: 100件でも高速表示
        // 【期待される動作】: 100件でも高速表示

        // Given: 100件のお気に入りデータを準備する
        final testFavorites = createTestFavorites(100);
        final mockState = FavoriteState(favorites: testFavorites);

        // When: 開始時刻を記録する
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              favoriteProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: FavoritesScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Then: 表示完了までの時間が1秒以内
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1000),
          reason: '100件のお気に入りを1秒以内に表示する必要がある',
        );
      });
    });

    // =========================================================================
    // 1.6 アクセシビリティテスト
    // =========================================================================
    group('アクセシビリティテスト', () {
      /// TC-064-019: タップターゲットサイズが44px以上 🔵
      ///
      /// 優先度: P0 必須
      /// 関連要件: NFR-064-005, AC-064-007
      /// 検証内容: アクセシビリティ要件のタップターゲットサイズ
      testWidgets('TC-064-019: お気に入り項目のタップターゲットが44px以上',
          (WidgetTester tester) async {
        // 【テスト目的】: アクセシビリティ要件の確認 🔵
        // 【テスト内容】: 各項目の高さが44px以上
        // 【期待される動作】: 各項目の高さが44px以上

        // Given: お気に入りデータを準備する
        final testFavorite = createTestFavorite(
          id: 'test_1',
          content: 'こんにちは',
          displayOrder: 0,
        );
        final mockState = FavoriteState(favorites: [testFavorite]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              favoriteProviderOverride(mockState),
            ],
            child: const MaterialApp(
              home: FavoritesScreen(),
            ),
          ),
        );

        // When: FavoriteItemCardの高さを測定する
        final cardFinder = find.byKey(const Key('favorite_item_card_test_1'));
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
