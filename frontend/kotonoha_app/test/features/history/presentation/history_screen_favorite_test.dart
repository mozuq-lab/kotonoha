/// 履歴画面からお気に入り追加機能テスト
///
/// TASK-0066: お気に入り追加・削除・並び替え機能
/// 【TDD Redフェーズ】: 失敗するテストを作成
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
/// 関連要件: REQ-701, REQ-2002
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kotonoha_app/features/history/presentation/history_screen.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart';
import 'package:kotonoha_app/features/history/domain/models/history.dart';
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/features/favorite/domain/models/favorite.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';

// =========================================================================
// テストヘルパー関数
// =========================================================================

/// テスト用の履歴データを生成
History createTestHistory({
  required String id,
  required String content,
  DateTime? createdAt,
  HistoryType type = HistoryType.manualInput,
}) {
  return History(
    id: id,
    content: content,
    createdAt: createdAt ?? DateTime.now(),
    type: type,
  );
}

// =========================================================================
// モッククラス
// =========================================================================

/// TTSNotifierのモック
class MockTTSNotifier extends Mock implements TTSNotifier {
  MockTTSNotifier() {
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

  @override
  bool updateShouldNotify(TTSServiceState old, TTSServiceState current) {
    return old != current;
  }
}

// =========================================================================
// テストヘルパー - プロバイダーオーバーライド
// =========================================================================

/// HistoryProviderをモック状態でオーバーライド
Override historyProviderOverride(HistoryState mockState) {
  return historyProvider.overrideWith((ref) {
    final notifier = HistoryNotifier();
    notifier.state = mockState;
    return notifier;
  });
}

// =========================================================================
// テストスイート
// =========================================================================

void main() {
  group('履歴画面 お気に入り追加機能テスト', () {
    /// TC-066-010: 履歴画面 長押しメニュー表示
    ///
    /// 優先度: P0 必須
    /// 関連要件: REQ-701
    /// 検証内容: 履歴項目を長押しするとコンテキストメニューが表示される
    testWidgets('TC-066-010: 履歴項目を長押しするとコンテキストメニューが表示される',
        (WidgetTester tester) async {
      // 【テスト目的】: 長押しによるコンテキストメニュー表示の確認 🔵
      // 【テスト内容】: 履歴項目を長押しすると「お気に入りに追加」オプションが表示される
      // 【期待される動作】: コンテキストメニューに「お気に入りに追加」が表示される

      // Given: 履歴データを準備する
      final testHistory = createTestHistory(
        id: 'test_1',
        content: 'こんにちは',
      );
      final mockState = HistoryState(histories: [testHistory]);

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

      // When: 履歴項目を長押しする
      await tester.longPress(find.text('こんにちは'));
      await tester.pumpAndSettle();

      // Then: コンテキストメニューが表示される
      expect(
        find.text('お気に入りに追加'),
        findsOneWidget,
        reason: '長押し時に「お気に入りに追加」メニューが表示される必要がある',
      );
    });

    /// TC-066-011: 履歴画面 お気に入り追加成功
    ///
    /// 優先度: P0 必須
    /// 関連要件: REQ-701
    /// 検証内容: 「お気に入りに追加」タップでお気に入りに追加される
    testWidgets('TC-066-011: 「お気に入りに追加」タップでお気に入りに追加される',
        (WidgetTester tester) async {
      // 【テスト目的】: お気に入り追加機能の確認 🔵
      // 【テスト内容】: メニューから「お気に入りに追加」をタップするとお気に入りに追加される
      // 【期待される動作】: スナックバーに成功メッセージが表示される

      // Given: 履歴データを準備する
      final testHistory = createTestHistory(
        id: 'test_1',
        content: 'こんにちは',
      );
      final mockHistoryState = HistoryState(histories: [testHistory]);

      final mockTTSNotifier = MockTTSNotifier();
      when(() => mockTTSNotifier.speak(any())).thenAnswer((_) async {});
      when(() => mockTTSNotifier.stop()).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyProviderOverride(mockHistoryState),
            ttsProvider.overrideWith((ref) => mockTTSNotifier),
          ],
          child: const MaterialApp(
            home: HistoryScreen(),
          ),
        ),
      );

      // When: 履歴項目を長押しし、「お気に入りに追加」をタップする
      await tester.longPress(find.text('こんにちは'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('お気に入りに追加'));
      await tester.pumpAndSettle();

      // Then: スナックバーに成功メッセージが表示される
      expect(
        find.text('お気に入りに追加しました'),
        findsOneWidget,
        reason: 'お気に入り追加成功時にスナックバーが表示される必要がある',
      );
    });

    /// TC-066-012: 履歴画面 重複追加エラーメッセージ
    ///
    /// 優先度: P0 必須
    /// 関連要件: REQ-701
    /// 検証内容: 既に登録済みの場合エラーメッセージが表示される
    testWidgets('TC-066-012: 既に登録済みの場合「既にお気に入りに登録されています」が表示される',
        (WidgetTester tester) async {
      // 【テスト目的】: 重複追加防止の確認 🔵
      // 【テスト内容】: 同一内容が既にお気に入りに存在する場合、エラーメッセージが表示される
      // 【期待される動作】: スナックバーに重複メッセージが表示される

      // Given: 履歴データとお気に入りに同じテキストを準備する
      final testHistory = createTestHistory(
        id: 'history_1',
        content: 'こんにちは',
      );
      final mockHistoryState = HistoryState(histories: [testHistory]);

      // お気に入りにも同じテキストが存在
      final mockFavoriteState = FavoriteState(
        favorites: [
          Favorite(
            id: 'fav_1',
            content: 'こんにちは',
            createdAt: DateTime.now(),
            displayOrder: 0,
          ),
        ],
      );

      final mockTTSNotifier = MockTTSNotifier();
      when(() => mockTTSNotifier.speak(any())).thenAnswer((_) async {});
      when(() => mockTTSNotifier.stop()).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyProviderOverride(mockHistoryState),
            favoriteProvider.overrideWith((ref) {
              final notifier = FavoriteNotifier();
              notifier.state = mockFavoriteState;
              return notifier;
            }),
            ttsProvider.overrideWith((ref) => mockTTSNotifier),
          ],
          child: const MaterialApp(
            home: HistoryScreen(),
          ),
        ),
      );

      // When: 履歴項目を長押しし、「お気に入りに追加」をタップする
      await tester.longPress(find.text('こんにちは'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('お気に入りに追加'));
      await tester.pumpAndSettle();

      // Then: スナックバーに重複メッセージが表示される
      expect(
        find.text('既にお気に入りに登録されています'),
        findsOneWidget,
        reason: '重複時にエラーメッセージが表示される必要がある',
      );
    });
  });
}
