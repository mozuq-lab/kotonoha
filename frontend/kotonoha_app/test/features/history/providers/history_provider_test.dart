/// HistoryProvider テスト
///
/// TASK-0057: Riverpod Provider 構造設計
/// TC-057-001 〜 TC-057-012
///
/// 関連要件:
/// - REQ-601: 履歴の自動保存
/// - REQ-602: 履歴一覧表示（新しい順）
/// - REQ-603: 履歴の削除
/// - REQ-604: 履歴の検索
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart';
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';

void main() {
  group('HistoryProvider テスト', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // =========================================================================
    // 正常系テスト
    // =========================================================================

    group('正常系テスト', () {
      test('TC-057-001: 履歴を追加できる', () async {
        // Arrange
        final notifier = container.read(historyProvider.notifier);

        // Act
        await notifier.addHistory('こんにちは', HistoryType.manualInput);

        // Assert
        final state = container.read(historyProvider);
        expect(state.histories.length, 1);
        expect(state.histories.first.content, 'こんにちは');
        expect(state.histories.first.type, HistoryType.manualInput);
      });

      test('TC-057-002: 複数の履歴を追加できる', () async {
        // Arrange
        final notifier = container.read(historyProvider.notifier);

        // Act
        await notifier.addHistory('1番目', HistoryType.manualInput);
        await notifier.addHistory('2番目', HistoryType.preset);
        await notifier.addHistory('3番目', HistoryType.aiConverted);

        // Assert
        final state = container.read(historyProvider);
        expect(state.histories.length, 3);
      });

      test('TC-057-003: 履歴が新しい順で取得できる', () async {
        // Arrange
        final notifier = container.read(historyProvider.notifier);

        // Act
        await notifier.addHistory('1番目', HistoryType.manualInput);
        await Future.delayed(const Duration(milliseconds: 10));
        await notifier.addHistory('2番目', HistoryType.preset);
        await Future.delayed(const Duration(milliseconds: 10));
        await notifier.addHistory('3番目', HistoryType.aiConverted);

        // Assert
        final state = container.read(historyProvider);
        expect(state.histories.first.content, '3番目');
        expect(state.histories.last.content, '1番目');
      });

      test('TC-057-004: 履歴を削除できる', () async {
        // Arrange
        final notifier = container.read(historyProvider.notifier);
        await notifier.addHistory('削除対象', HistoryType.manualInput);
        final state = container.read(historyProvider);
        final id = state.histories.first.id;

        // Act
        await notifier.deleteHistory(id);

        // Assert
        final updatedState = container.read(historyProvider);
        expect(updatedState.histories.length, 0);
      });

      test('TC-057-005: 履歴を検索できる', () async {
        // Arrange
        final notifier = container.read(historyProvider.notifier);
        await notifier.addHistory('こんにちは', HistoryType.manualInput);
        await notifier.addHistory('おはよう', HistoryType.preset);
        await notifier.addHistory('こんばんは', HistoryType.aiConverted);

        // Act
        final results = notifier.searchHistory('こん');

        // Assert
        expect(results.length, 2);
        expect(results.any((h) => h.content == 'こんにちは'), true);
        expect(results.any((h) => h.content == 'こんばんは'), true);
      });

      test('TC-057-006: 履歴タイプを指定できる', () async {
        // Arrange
        final notifier = container.read(historyProvider.notifier);

        // Act & Assert - manualInput
        await notifier.addHistory('手動入力', HistoryType.manualInput);
        var state = container.read(historyProvider);
        expect(state.histories.last.type, HistoryType.manualInput);

        // Act & Assert - preset
        await notifier.addHistory('定型文', HistoryType.preset);
        state = container.read(historyProvider);
        expect(state.histories.first.type, HistoryType.preset);

        // Act & Assert - aiConverted
        await notifier.addHistory('AI変換', HistoryType.aiConverted);
        state = container.read(historyProvider);
        expect(state.histories.first.type, HistoryType.aiConverted);

        // Act & Assert - quickButton
        await notifier.addHistory('大ボタン', HistoryType.quickButton);
        state = container.read(historyProvider);
        expect(state.histories.first.type, HistoryType.quickButton);
      });
    });

    // =========================================================================
    // デフォルト値テスト
    // =========================================================================

    group('デフォルト値テスト', () {
      test('TC-057-007: 初期状態は空の履歴リスト', () {
        // Assert
        final state = container.read(historyProvider);
        expect(state.histories, isEmpty);
      });

      test('TC-057-008: 初期状態はローディングfalse', () {
        // Assert
        final state = container.read(historyProvider);
        expect(state.isLoading, false);
      });
    });

    // =========================================================================
    // 異常系テスト
    // =========================================================================

    group('異常系テスト', () {
      test('TC-057-009: 空文字の履歴は追加されない', () async {
        // Arrange
        final notifier = container.read(historyProvider.notifier);

        // Act
        await notifier.addHistory('', HistoryType.manualInput);

        // Assert
        final state = container.read(historyProvider);
        expect(state.histories.length, 0);
      });

      test('TC-057-010: 存在しないIDの削除は無視される', () async {
        // Arrange
        final notifier = container.read(historyProvider.notifier);
        await notifier.addHistory('テスト', HistoryType.manualInput);

        // Act
        await notifier.deleteHistory('non-existent-id');

        // Assert
        final state = container.read(historyProvider);
        expect(state.histories.length, 1);
      });

      test('TC-057-011: 検索結果が0件の場合', () async {
        // Arrange
        final notifier = container.read(historyProvider.notifier);
        await notifier.addHistory('こんにちは', HistoryType.manualInput);

        // Act
        final results = notifier.searchHistory('存在しないキーワード');

        // Assert
        expect(results, isEmpty);
      });

      test('TC-057-012: 履歴にUUIDが自動付与される', () async {
        // Arrange
        final notifier = container.read(historyProvider.notifier);

        // Act
        await notifier.addHistory('テスト', HistoryType.manualInput);

        // Assert
        final state = container.read(historyProvider);
        final id = state.histories.first.id;
        // UUID形式の正規表現パターン
        final uuidRegex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false,
        );
        expect(uuidRegex.hasMatch(id), true);
      });
    });
  });
}
