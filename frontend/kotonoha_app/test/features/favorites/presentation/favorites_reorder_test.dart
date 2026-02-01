/// お気に入り並び替え機能テスト
///
/// TASK-0066: お気に入り追加・削除・並び替え機能
/// 【TDD Redフェーズ】: 失敗するテストを作成
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
/// 関連要件: REQ-703
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

/// テスト用のお気に入りデータを生成
Favorite createTestFavorite({
  required String id,
  required String content,
  DateTime? createdAt,
  int displayOrder = 0,
}) {
  return Favorite(
    id: id,
    content: content,
    createdAt: createdAt ?? DateTime.now(),
    displayOrder: displayOrder,
  );
}

// =========================================================================
// モッククラス
// =========================================================================

/// TTSNotifierのモック
class MockTTSNotifier extends TTSNotifier with Mock {
  @override
  TTSServiceState build() => const TTSServiceState(
        state: TTSState.idle,
        currentSpeed: TTSSpeed.normal,
      );
}

// =========================================================================
// テスト用Notifierサブクラス
// =========================================================================

/// build()で初期状態を返すFavoriteNotifierのテスト用サブクラス
class _TestFavoriteNotifier extends FavoriteNotifier {
  final FavoriteState _initialState;
  _TestFavoriteNotifier(this._initialState);
  @override
  FavoriteState build() => _initialState;
}

// =========================================================================
// テストヘルパー - プロバイダーオーバーライド
// =========================================================================

/// FavoriteProviderをモック状態でオーバーライド
favoriteProviderOverride(FavoriteState mockState) {
  return favoriteProvider.overrideWith(() => _TestFavoriteNotifier(mockState));
}

// =========================================================================
// テストスイート
// =========================================================================

void main() {
  group('お気に入り並び替え機能テスト', () {
    /// TC-066-020: お気に入り画面 編集モードトグル
    ///
    /// 優先度: P0 必須
    /// 関連要件: REQ-703
    /// 検証内容: 編集ボタンタップで編集モードに入る
    testWidgets('TC-066-020: 編集ボタンタップで編集モードに入り、ドラッグハンドルが表示される',
        (WidgetTester tester) async {
      // 【テスト目的】: 編集モードトグルの確認 🔵
      // 【テスト内容】: 編集ボタンをタップすると編集モードに入る
      // 【期待される動作】: ドラッグハンドルが表示される

      // Given: お気に入りデータを準備する
      final favorites = [
        createTestFavorite(id: 'test_1', content: 'お気に入り1', displayOrder: 0),
        createTestFavorite(id: 'test_2', content: 'お気に入り2', displayOrder: 1),
        createTestFavorite(id: 'test_3', content: 'お気に入り3', displayOrder: 2),
      ];
      final mockState = FavoriteState(favorites: favorites);

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

      // When: 編集ボタンをタップする
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Then: ドラッグハンドル（Icons.drag_handle）が表示される
      expect(
        find.byIcon(Icons.drag_handle),
        findsNWidgets(3),
        reason: '編集モード時にドラッグハンドルが表示される必要がある',
      );
    });

    /// TC-066-021: お気に入り画面 ドラッグ&ドロップ並び替え
    ///
    /// 優先度: P0 必須
    /// 関連要件: REQ-703
    /// 検証内容: ドラッグ&ドロップで順序が変更される
    testWidgets('TC-066-021: ドラッグ&ドロップで順序が変更される', (WidgetTester tester) async {
      // 【テスト目的】: ドラッグ&ドロップ並び替えの確認 🔵
      // 【テスト内容】: 項目をドラッグ&ドロップで並び替えできる
      // 【期待される動作】: 順序が変更され、UIに反映される

      // Given: お気に入りデータを準備する
      final favorites = [
        createTestFavorite(id: 'test_1', content: 'お気に入り1', displayOrder: 0),
        createTestFavorite(id: 'test_2', content: 'お気に入り2', displayOrder: 1),
        createTestFavorite(id: 'test_3', content: 'お気に入り3', displayOrder: 2),
      ];
      final mockState = FavoriteState(favorites: favorites);

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

      // 編集モードに入る
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // When: 1番目の項目を3番目にドラッグ
      // ReorderableListViewのドラッグテストはハンドルを使用する
      final firstDragHandle = find.byIcon(Icons.drag_handle).first;

      // ドラッグ開始
      final gesture = await tester.startGesture(
        tester.getCenter(firstDragHandle),
      );

      // 下に移動（2項目分）
      await gesture.moveBy(const Offset(0, 150));
      await tester.pumpAndSettle();

      // ドラッグ終了
      await gesture.up();
      await tester.pumpAndSettle();

      // Then: ReorderableListViewが使用されていることを確認
      expect(
        find.byType(ReorderableListView),
        findsOneWidget,
        reason: 'ReorderableListViewが使用されている必要がある',
      );
    });

    /// TC-066-022: お気に入り画面 編集モード終了
    ///
    /// 優先度: P0 必須
    /// 関連要件: REQ-703
    /// 検証内容: 編集モード終了でドラッグハンドルが非表示になる
    testWidgets('TC-066-022: 編集モード終了でドラッグハンドルが非表示になる',
        (WidgetTester tester) async {
      // 【テスト目的】: 編集モード終了の確認 🔵
      // 【テスト内容】: 完了ボタンをタップすると編集モードが終了する
      // 【期待される動作】: ドラッグハンドルが非表示になる

      // Given: お気に入りデータを準備する
      final favorites = [
        createTestFavorite(id: 'test_1', content: 'お気に入り1', displayOrder: 0),
        createTestFavorite(id: 'test_2', content: 'お気に入り2', displayOrder: 1),
      ];
      final mockState = FavoriteState(favorites: favorites);

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

      // 編集モードに入る
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // ドラッグハンドルが表示されていることを確認
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));

      // When: 完了ボタン（Icons.check）をタップする
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      // Then: ドラッグハンドルが非表示になる
      expect(
        find.byIcon(Icons.drag_handle),
        findsNothing,
        reason: '編集モード終了時にドラッグハンドルが非表示になる必要がある',
      );
    });

    /// TC-066-023: 編集ボタンが表示される（お気に入りが存在する場合）
    ///
    /// 優先度: P0 必須
    /// 関連要件: REQ-703
    /// 検証内容: お気に入りが存在する場合に編集ボタンが表示される
    testWidgets('TC-066-023: お気に入りが存在する場合、編集ボタンが表示される',
        (WidgetTester tester) async {
      // 【テスト目的】: 編集ボタン表示条件の確認 🔵
      // 【テスト内容】: お気に入りが2件以上存在する場合に編集ボタンが表示される
      // 【期待される動作】: Icons.editボタンが表示される

      // Given: お気に入りデータを準備する（2件以上）
      final favorites = [
        createTestFavorite(id: 'test_1', content: 'お気に入り1', displayOrder: 0),
        createTestFavorite(id: 'test_2', content: 'お気に入り2', displayOrder: 1),
      ];
      final mockState = FavoriteState(favorites: favorites);

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

      // Then: 編集ボタンが表示される
      expect(
        find.byIcon(Icons.edit),
        findsOneWidget,
        reason: 'お気に入りが2件以上存在する場合、編集ボタンが表示される必要がある',
      );
    });

    /// TC-066-024: お気に入りが1件のみの場合、編集ボタンが非表示
    ///
    /// 優先度: P1 重要
    /// 関連要件: REQ-703
    /// 検証内容: お気に入りが1件のみの場合、編集ボタンが非表示
    testWidgets('TC-066-024: お気に入りが1件のみの場合、編集ボタンが非表示',
        (WidgetTester tester) async {
      // 【テスト目的】: 編集ボタン非表示条件の確認 🟡
      // 【テスト内容】: お気に入りが1件のみの場合は並び替え不要なので編集ボタンが非表示
      // 【期待される動作】: Icons.editボタンが表示されない

      // Given: お気に入りデータを準備する（1件のみ）
      final favorites = [
        createTestFavorite(id: 'test_1', content: 'お気に入り1', displayOrder: 0),
      ];
      final mockState = FavoriteState(favorites: favorites);

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

      // Then: 編集ボタンが表示されない
      expect(
        find.byIcon(Icons.edit),
        findsNothing,
        reason: 'お気に入りが1件のみの場合、編集ボタンが非表示である必要がある',
      );
    });

    /// TC-066-025: 空状態では編集ボタンが非表示
    ///
    /// 優先度: P1 重要
    /// 関連要件: REQ-703
    /// 検証内容: お気に入りが0件の場合、編集ボタンが非表示
    testWidgets('TC-066-025: お気に入りが0件の場合、編集ボタンが非表示',
        (WidgetTester tester) async {
      // 【テスト目的】: 空状態での編集ボタン非表示確認 🟡
      // 【テスト内容】: お気に入りが0件の場合は編集ボタンが非表示
      // 【期待される動作】: Icons.editボタンが表示されない

      // Given: 空のお気に入りリスト
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

      // Then: 編集ボタンが表示されない
      expect(
        find.byIcon(Icons.edit),
        findsNothing,
        reason: 'お気に入りが0件の場合、編集ボタンが非表示である必要がある',
      );
    });
  });
}
