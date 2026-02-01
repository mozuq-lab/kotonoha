/// テストヘルパー関数
///
/// TASK-0061: 履歴一覧UI実装
library;

import 'package:kotonoha_app/features/history/domain/models/history.dart';
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart';

/// テスト用の履歴データを生成するヘルパー関数
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

/// 複数件の履歴データを生成
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

/// テスト用のHistoryNotifierを作成
/// build()で初期状態を返すことで、Riverpod 3.x互換にする
class TestHistoryNotifier extends HistoryNotifier {
  final HistoryState _initialState;
  TestHistoryNotifier(this._initialState);
  @override
  HistoryState build() => _initialState;
}

/// テスト用のhistoryProviderオーバーライドを作成
createHistoryProviderOverride(HistoryState mockState) {
  return historyProvider.overrideWith(() => TestHistoryNotifier(mockState));
}
