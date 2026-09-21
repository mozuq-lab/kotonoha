import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kotonoha_app/features/history/data/history_repository.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/history_item_adapter.dart';

HistoryItem item(int index, {String? id}) => HistoryItem(
      id: id ?? 'history-$index',
      content: '発話 $index',
      createdAt: DateTime(2026).add(Duration(seconds: index)),
      type: 'manualInput',
    );

void main() {
  late Directory dir;
  late Box<HistoryItem> box;

  setUp(() async {
    await Hive.close();
    dir = await Directory.systemTemp.createTemp('history_ordering_');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HistoryItemAdapter());
    }
    box = await Hive.openBox<HistoryItem>('history');
  });
  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('上限で重なる保存は最新50件を再オープン後も保持する', () async {
    final repository = HistoryRepository(box: box);
    for (var i = 0; i < 50; i++) {
      await repository.save(item(i));
    }
    await Future.wait([repository.save(item(50)), repository.save(item(51))]);
    expect(box.length, lessThanOrEqualTo(50));
    await repository.save(item(52));
    await box.close();
    box = await Hive.openBox<HistoryItem>('history');
    expect(box.length, lessThanOrEqualTo(50));
    expect(box.keys, containsAll([for (var i = 3; i <= 52; i++) 'history-$i']));
    expect(
        box.keys,
        isNot(anyOf(contains('history-0'), contains('history-1'),
            contains('history-2'))));
    expect(box.get('history-52')?.content, contains('52'));
  });

  for (final clearAll in [true, false]) {
    test('待機中の保存の後の${clearAll ? "全削除" : "個別削除"}で履歴が復活しない', () async {
      final repository = HistoryRepository(box: box);
      await Future.wait([
        repository.save(item(0)),
        repository.save(item(1)),
        clearAll ? repository.deleteAll() : repository.delete('history-1'),
      ]);
      await box.close();
      box = await Hive.openBox<HistoryItem>('history');
      expect(box.get('history-1'), isNull);
      if (clearAll) {
        expect(box.values, isEmpty);
      } else {
        expect(box.get('history-0'), isNotNull);
      }
    });
  }

  test('失敗した保存を通知し後ろの保存を実ファイルへ継続する', () async {
    final results = <bool>[];
    final repository = HistoryRepository(box: box, onWriteResult: results.add);
    // Hiveのキー長制限で書き込みを失敗させる。自前の保存関数は差し替えない。
    await Future.wait([
      repository.save(item(0, id: 'x' * 256)),
      repository.save(item(1)),
    ]);
    expect(results, contains(false));
    expect(results.last, isTrue);
    await box.close();
    box = await Hive.openBox<HistoryItem>('history');
    expect(box.get('history-1')?.content, contains('1'));
    expect(box.keys, isNot(contains('x' * 256)));
  });
}
