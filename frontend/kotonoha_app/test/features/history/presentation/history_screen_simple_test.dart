/// HistoryScreen 簡易テスト
///
/// TASK-0061: 履歴一覧UI実装（TDD Redフェーズ）
/// 優先度P0のテストのみを実装
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/features/history/presentation/history_screen.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart';
import 'package:kotonoha_app/features/history/domain/models/history.dart';
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';

// テストヘルパー
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

// テスト用Notifier
/// build()で初期状態を返すことで、Riverpod 3.x互換にする
class TestHistoryNotifier extends HistoryNotifier {
  final HistoryState _initialState;
  TestHistoryNotifier(this._initialState);
  @override
  HistoryState build() => _initialState;
}

void main() {
  group('HistoryScreen P0 テスト', () {
    testWidgets('TC-061-001: 履歴一覧が表示される', (WidgetTester tester) async {
      // Given
      final testHistory = createTestHistory(
        id: 'test_1',
        content: 'こんにちは',
        type: HistoryType.manualInput,
      );
      final mockState = HistoryState(histories: [testHistory]);

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyProvider.overrideWith(() => TestHistoryNotifier(mockState)),
          ],
          child: const MaterialApp(
            home: HistoryScreen(),
          ),
        ),
      );

      // Then
      expect(find.text('こんにちは'), findsOneWidget);
    });

    testWidgets('TC-061-005: 空状態メッセージが表示される', (WidgetTester tester) async {
      // Given
      const mockState = HistoryState(histories: []);

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyProvider.overrideWith(() => TestHistoryNotifier(mockState)),
          ],
          child: const MaterialApp(
            home: HistoryScreen(),
          ),
        ),
      );

      // Then
      expect(find.text('履歴がありません'), findsOneWidget);
    });
  });
}
