/// テストデータセットアップ
///
/// TASK-0081: E2Eテスト環境構築
/// 信頼性レベル: 🟡 黄信号（テスト戦略は要件定義書から推測）
///
/// E2Eテスト用のデータ準備と初期化を提供。
library;

import 'package:hive/hive.dart';

import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/app_settings.dart';

/// テストデータセットアップ
class TestDataSetup {
  /// テスト用のHiveボックスをクリア
  static Future<void> clearAllTestData() async {
    if (Hive.isBoxOpen('history')) {
      await Hive.box<HistoryItem>('history').clear();
    }
    if (Hive.isBoxOpen('preset_phrases')) {
      await Hive.box<PresetPhrase>('preset_phrases').clear();
    }
    if (Hive.isBoxOpen('favorites')) {
      await Hive.box('favorites').clear();
    }
    if (Hive.isBoxOpen('settings')) {
      await Hive.box<AppSettings>('settings').clear();
    }
  }

  /// テスト用の履歴データをセットアップ
  static Future<void> setupTestHistory({int count = 10}) async {
    final box = Hive.box<HistoryItem>('history');
    await box.clear();

    for (var i = 0; i < count; i++) {
      // HistoryType: manualInput, preset, aiConverted, quickButton
      final typeStr = switch (i % 4) {
        0 => 'manualInput',
        1 => 'preset',
        2 => 'aiConverted',
        _ => 'quickButton',
      };

      await box.add(HistoryItem(
        id: 'test-history-$i',
        content: 'テスト履歴 $i',
        createdAt: DateTime.now().subtract(Duration(minutes: i * 5)),
        type: typeStr,
      ));
    }
  }

  /// テスト用の定型文データをセットアップ
  static Future<void> setupTestPhrases() async {
    final box = Hive.box<PresetPhrase>('preset_phrases');
    await box.clear();

    final now = DateTime.now();
    final phrases = [
      PresetPhrase(
        id: 'phrase-1',
        content: 'おはようございます',
        category: 'あいさつ',
        isFavorite: false,
        displayOrder: 0,
        createdAt: now,
        updatedAt: now,
      ),
      PresetPhrase(
        id: 'phrase-2',
        content: 'こんにちは',
        category: 'あいさつ',
        isFavorite: true,
        displayOrder: 1,
        createdAt: now,
        updatedAt: now,
      ),
      PresetPhrase(
        id: 'phrase-3',
        content: 'ありがとう',
        category: 'あいさつ',
        isFavorite: false,
        displayOrder: 2,
        createdAt: now,
        updatedAt: now,
      ),
      PresetPhrase(
        id: 'phrase-4',
        content: 'お腹が空きました',
        category: '体調',
        isFavorite: false,
        displayOrder: 3,
        createdAt: now,
        updatedAt: now,
      ),
      PresetPhrase(
        id: 'phrase-5',
        content: '喉が渇きました',
        category: '体調',
        isFavorite: false,
        displayOrder: 4,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final phrase in phrases) {
      await box.add(phrase);
    }
  }

  /// デフォルト設定をセットアップ
  static Future<void> setupDefaultSettings() async {
    final box = Hive.box<AppSettings>('settings');
    await box.clear();

    await box.put('app_settings', AppSettings.defaults());
  }

  /// 50件の履歴を生成（上限テスト用）
  static Future<void> setupMaxHistory() async {
    await setupTestHistory(count: 50);
  }

  /// パフォーマンステスト用の大量データをセットアップ
  static Future<void> setupPerformanceTestData() async {
    // 100件の定型文
    final phrasesBox = Hive.box<PresetPhrase>('preset_phrases');
    await phrasesBox.clear();

    final now = DateTime.now();
    for (var i = 0; i < 100; i++) {
      await phrasesBox.add(PresetPhrase(
        id: 'perf-phrase-$i',
        content: 'パフォーマンステスト用定型文 $i',
        category: '${i % 5}カテゴリ',
        isFavorite: i % 10 == 0,
        displayOrder: i,
        createdAt: now,
        updatedAt: now,
      ));
    }

    // 50件の履歴
    await setupMaxHistory();
  }

  /// テスト用のお気に入りデータをセットアップ
  static Future<void> setupTestFavorites({int count = 5}) async {
    final box = Hive.box('favorites');
    await box.clear();

    for (var i = 0; i < count; i++) {
      await box.put('favorite-$i', {
        'id': 'favorite-$i',
        'content': 'お気に入り $i',
        'displayOrder': i,
        'createdAt': DateTime.now().subtract(Duration(days: i)).toIso8601String(),
      });
    }
  }
}
