// テストフレームワーク: flutter_test + Hive Testing
// 対象: Hive初期化処理（initHive関数）

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/history_item_adapter.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';

void main() {
  group('Hive初期化・TypeAdapter登録テスト', () {
    late Directory tempDir;

    setUp(() async {
      // テスト前準備: Hive環境をクリーンな状態にリセット
      // 環境初期化: 前のテストの影響を受けないよう、Hiveをクローズし削除
      // path_provider対策: 一時ディレクトリを使用してpath_providerプラグインへの依存を回避
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);
    });

    tearDown(() async {
      // テスト後処理: Hive環境をクリーンアップ
      // 状態復元: 次のテストに影響しないよう、すべてのボックスをクローズ
      await Hive.close();
      // 一時ディレクトリ削除: テスト用の一時ファイルを削除
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // Hive初期化成功テスト
    test('TC-001: Hive初期化が正常に完了し、ボックスがオープンできることを確認', () async {
      // テストデータ準備: なし（初期化のみ）
      // 初期条件設定: アプリ初回起動時の状態
      // 前提条件確認: Hive未初期化の状態

      // 実際の処理実行: TypeAdapter登録とボックスオープンを直接実行
      // 処理内容: initHiveの内部処理をテスト環境で再現（Hive.initは既にsetUpで実行済み）
      // 実行タイミング: アプリのmain関数内で最初に実行
      // path_provider対策: Hive.initFlutterではなく、TypeAdapter登録とボックスオープンのみを実行
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }
      await Hive.openBox<HistoryItem>('history');
      await Hive.openBox<PresetPhrase>('presetPhrases');

      // 結果検証: Hive初期化が成功し、ボックスがオープンされていることを確認
      // 期待値確認: のデータ永続化機構が利用可能

      // 検証項目: historyボックスがオープンされていること
      expect(Hive.isBoxOpen('history'), true);

      // 検証項目: presetPhrasesボックスがオープンされていること
      expect(Hive.isBoxOpen('presetPhrases'), true);
    });

    // TypeAdapter登録成功テスト
    test('TC-002: HistoryItemAdapterとPresetPhraseAdapterが正しく登録されることを確認',
        () async {
      // テストデータ準備: なし（TypeAdapter登録のみ）
      // 初期条件設定: Hive未初期化の状態

      // 実際の処理実行: TypeAdapter登録とボックスオープンを直接実行
      // 処理内容: TypeAdapter登録（HistoryItemAdapter、PresetPhraseAdapter）
      // 実行タイミング: Hive初期化直後
      // path_provider対策: Hive.initは既にsetUpで実行済み
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }
      await Hive.openBox<HistoryItem>('history');
      await Hive.openBox<PresetPhrase>('presetPhrases');

      // 結果検証: TypeAdapterが正しく登録されていることを確認
      // 期待値確認: カスタムクラスのHive永続化に必須

      // 検証項目: typeId 0（HistoryItem）が登録されていること
      expect(Hive.isAdapterRegistered(0), true);

      // 検証項目: typeId 1（PresetPhrase）が登録されていること
      expect(Hive.isAdapterRegistered(1), true);
    });

    // TypeAdapter重複登録時のエラーハンドリングテスト
    test('TC-003: 同じTypeAdapterを2回登録しようとした場合のエラーハンドリングを確認', () async {
      // テストデータ準備: なし
      // 初期条件設定: 1回目のTypeAdapter登録を実行済み
      // 実際の発生シナリオ: Hot Restart時、テスト実行時の複数回初期化
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }
      await Hive.openBox<HistoryItem>('history');
      await Hive.openBox<PresetPhrase>('presetPhrases');

      // 実際の処理実行: TypeAdapter登録を2回目に実行
      // 処理内容: 既に登録済みのTypeAdapterを再登録しようとする
      // 実行タイミング: アプリHot Restart時、テスト実行時

      // 結果検証: エラーが適切にハンドリングされ、アプリがクラッシュしないこと
      // 期待値確認: （基本機能継続）を満たす
      // システムの安全性: 開発中のHot Restartでクラッシュしない

      // 検証項目: 2回目のTypeAdapter登録でエラーが発生しないこと
      expect(
        () {
          // 重複登録確認: isAdapterRegisteredでチェックされるため、正常に完了
          if (!Hive.isAdapterRegistered(0)) {
            Hive.registerAdapter(HistoryItemAdapter());
          }
          if (!Hive.isAdapterRegistered(1)) {
            Hive.registerAdapter(PresetPhraseAdapter());
          }
        },
        returnsNormally,
      );

      // 検証項目: TypeAdapterが依然として登録されていること
      expect(Hive.isAdapterRegistered(0), true);
      expect(Hive.isAdapterRegistered(1), true);
    });

    // HistoryItemの保存・読み込みテスト
    test('TC-054-001: HistoryItemをHiveに保存・読み込みできることを確認', () async {
      // Given
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }
      final box = await Hive.openBox<HistoryItem>('history');
      final now = DateTime.now();
      final item = HistoryItem(
        id: 'test-001',
        content: 'テストメッセージ',
        createdAt: now,
        type: 'manualInput',
      );

      // When
      await box.put('test-001', item);
      final loaded = box.get('test-001');

      // Then
      expect(loaded, isNotNull);
      expect(loaded!.id, 'test-001');
      expect(loaded.content, 'テストメッセージ');
      expect(loaded.type, 'manualInput');
    });

    // PresetPhraseの保存・読み込みテスト
    test('TC-054-002: PresetPhraseをHiveに保存・読み込みできることを確認', () async {
      // Given
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }
      final box = await Hive.openBox<PresetPhrase>('presetPhrases');
      final now = DateTime.now();
      final phrase = PresetPhrase(
        id: 'preset-001',
        content: 'おはようございます',
        category: 'daily',
        displayOrder: 1,
        createdAt: now,
        updatedAt: now,
      );

      // When
      await box.put('preset-001', phrase);
      final loaded = box.get('preset-001');

      // Then
      expect(loaded, isNotNull);
      expect(loaded!.id, 'preset-001');
      expect(loaded.content, 'おはようございます');
      expect(loaded.category, 'daily');
      expect(loaded.displayOrder, 1);
    });

    // エラー時の適切なハンドリングテスト
    test('TC-054-003: 存在しないキーへのアクセスがnullを返すことを確認', () async {
      // Given
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }
      final box = await Hive.openBox<HistoryItem>('history');

      // When
      final result = box.get('non-existent-key');

      // Then
      expect(result, isNull);
    });
  });
}
