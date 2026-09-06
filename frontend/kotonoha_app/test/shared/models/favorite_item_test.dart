/// FavoriteItem モデルテスト（Redフェーズ）
/// TASK-0065: お気に入りHiveモデル・リポジトリ実装
///
/// テストフレームワーク: flutter_test
/// 対象: FavoriteItem（お気に入りのHiveモデル）
///
/// TDD Redフェーズ: FavoriteItemモデルが未実装のため、このテストは失敗する
///
/// 信頼性レベル凡例:
/// - 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
/// - 黄信号: 要件定義書から妥当な推測によるテスト
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

    // =========================================================================
    // TC-065-001: FavoriteItem基本フィールドの保存・読み込み
    // =========================================================================
    test('TC-065-001: FavoriteItemの全フィールドが保存される', () async {
      // テスト目的: FavoriteItemの全フィールドが正しくシリアライズ・デシリアライズされることを確認
      // テスト内容: Hive TypeAdapter経由で全フィールドが保存・復元できることを検証
      // 期待される動作: 保存したフィールドが完全に復元される
      // 青信号: FR-065-001

      // Given（準備フェーズ）
      final favorite = FavoriteItem(
        id: 'test-001',
        content: 'こんにちは',
        createdAt: DateTime(2025, 1, 15, 10, 30),
        displayOrder: 5,
      );

      // When（実行フェーズ）
      await box.put(favorite.id, favorite);
      final loaded = box.get('test-001');

      // Then（検証フェーズ）
      expect(loaded, isNotNull);
      expect(loaded!.id, 'test-001');
      expect(loaded.content, 'こんにちは');
      expect(loaded.createdAt, DateTime(2025, 1, 15, 10, 30));
      expect(loaded.displayOrder, 5);
    });

    // =========================================================================
    // TC-065-002: FavoriteItem copyWith()メソッド
    // =========================================================================
    test('TC-065-002: copyWithで部分更新できる', () {
      // テスト目的: copyWith()メソッドの不変オブジェクトパターン確認
      // テスト内容: 一部フィールドのみ変更した新しいインスタンスが作成されることを検証
      // 期待される動作: 変更していないフィールドは元の値が保持される
      // 青信号: FR-065-001

      // Given（準備フェーズ）
      final original = FavoriteItem(
        id: 'test-002',
        content: '元の内容',
        createdAt: DateTime.now(),
        displayOrder: 1,
      );

      // When（実行フェーズ）
      final updated = original.copyWith(content: '更新後の内容');

      // Then（検証フェーズ）
      expect(updated.id, 'test-002'); // 変更なし
      expect(updated.content, '更新後の内容'); // 変更された
      expect(updated.displayOrder, 1); // 変更なし
      expect(original.content, '元の内容'); // 元のオブジェクトは変更されない
    });

    // =========================================================================
    // TC-065-003: FavoriteItem 等価性比較（==演算子）
    // =========================================================================
    test('TC-065-003: 同じidなら等価と判定される', () {
      // テスト目的: idベースの等価性比較の確認
      // テスト内容: 同じidを持つFavoriteItemは等価と判定されることを検証
      // 期待される動作: idが同じなら内容が異なっても等価
      // 青信号: FR-065-001

      // Given（準備フェーズ）
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

    // =========================================================================
    // TC-065-004: FavoriteItem hashCode
    // =========================================================================
    test('TC-065-004: 同じidなら同じhashCodeを返す', () {
      // テスト目的: hashCode契約の確認
      // テスト内容: 同じidを持つFavoriteItemは同じhashCodeを返すことを検証
      // 期待される動作: hashCode契約が守られる（== trueならhashCodeも同じ）
      // 青信号: FR-065-001

      // Given（準備フェーズ）
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

    // =========================================================================
    // TC-065-005: FavoriteItem toString()メソッド
    // =========================================================================
    test('TC-065-005: toStringでデバッグ文字列が返る', () {
      // テスト目的: toString()メソッドのデバッグ出力確認
      // テスト内容: toString()が全フィールドを含む文字列を返すことを検証
      // 期待される動作: id, content, createdAt, displayOrderが文字列に含まれる
      // 青信号: FR-065-001

      // Given（準備フェーズ）
      final fav = FavoriteItem(
        id: 'str-test',
        content: 'テスト',
        createdAt: DateTime(2025, 1, 1),
        displayOrder: 3,
      );

      // When（実行フェーズ）
      final str = fav.toString();

      // Then（検証フェーズ）
      expect(str, contains('str-test'));
      expect(str, contains('テスト'));
      expect(str, contains('3'));
    });
  });
}
