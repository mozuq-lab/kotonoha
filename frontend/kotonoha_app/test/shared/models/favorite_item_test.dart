/// テストフレームワーク: flutter_test
/// 対象: FavoriteItem（お気に入りのHiveモデル）
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/favorite_item_adapter.dart';

void main() {
  group('FavoriteItem - Hiveモデル基本機能', () {
    late Directory tempDir;
    late Box<FavoriteItem> box;

    setUp(() async {
      // テスト前準備: Hive環境を初期化
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_favorite_model_');
      Hive.init(tempDir.path);

      // TypeAdapter登録（typeId: 2）
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(FavoriteItemAdapter());
      }

      box = await Hive.openBox<FavoriteItem>('test_favorite_item');
    });

    tearDown(() async {
      // テスト後処理: リソースクリーンアップ
      await box.close();
      await Hive.deleteBoxFromDisk('test_favorite_item');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // FavoriteItem基本フィールドの保存・読み込み
    test('TC-065-001: FavoriteItemの全フィールドが保存される', () async {
      final favorite = FavoriteItem(
        id: 'test-001',
        content: 'こんにちは',
        createdAt: DateTime(2025, 1, 15, 10, 30),
        displayOrder: 5,
      );

      await box.put(favorite.id, favorite);
      final loaded = box.get('test-001');

      expect(loaded, isNotNull);
      expect(loaded!.id, 'test-001');
      expect(loaded.content, 'こんにちは');
      expect(loaded.createdAt, DateTime(2025, 1, 15, 10, 30));
      expect(loaded.displayOrder, 5);
    });

    // FavoriteItem copyWithメソッド
    test('TC-065-002: copyWithで部分更新できる', () {
      final original = FavoriteItem(
        id: 'test-002',
        content: '元の内容',
        createdAt: DateTime.now(),
        displayOrder: 1,
      );

      final updated = original.copyWith(content: '更新後の内容');

      expect(updated.id, 'test-002'); // 変更なし
      expect(updated.content, '更新後の内容'); // 変更された
      expect(updated.displayOrder, 1); // 変更なし
      expect(original.content, '元の内容'); // 元のオブジェクトは変更されない
    });

    // FavoriteItem 等価性比較（==演算子）
    test('TC-065-003: 同じidなら等価と判定される', () {
      final fav1 = FavoriteItem(
        id: 'same-id',
        content: '内容A',
        createdAt: DateTime.now(),
        displayOrder: 1,
      );
      final fav2 = FavoriteItem(
        id: 'same-id',
        content: '内容B',
        createdAt: DateTime.now(),
        displayOrder: 2,
      );
      final fav3 = FavoriteItem(
        id: 'different-id',
        content: '内容A',
        createdAt: DateTime.now(),
        displayOrder: 1,
      );

      // When & Then（実行・検証フェーズ）
      expect(fav1, equals(fav2)); // idが同じなら等価
      expect(fav1, isNot(equals(fav3))); // idが異なるなら非等価
    });

    // FavoriteItem hashCode
    test('TC-065-004: 同じidなら同じhashCodeを返す', () {
      final fav1 = FavoriteItem(
        id: 'hash-test',
        content: 'A',
        createdAt: DateTime.now(),
        displayOrder: 1,
      );
      final fav2 = FavoriteItem(
        id: 'hash-test',
        content: 'B',
        createdAt: DateTime.now(),
        displayOrder: 2,
      );

      // When & Then（実行・検証フェーズ）
      expect(fav1.hashCode, equals(fav2.hashCode));
    });

    // FavoriteItem toStringメソッド
    test('TC-065-005: toStringでデバッグ文字列が返る', () {
      final fav = FavoriteItem(
        id: 'str-test',
        content: 'テスト',
        createdAt: DateTime(2025, 1, 1),
        displayOrder: 3,
      );

      final str = fav.toString();

      expect(str, contains('str-test'));
      expect(str, contains('テスト'));
      expect(str, contains('3'));
    });
  });
}
