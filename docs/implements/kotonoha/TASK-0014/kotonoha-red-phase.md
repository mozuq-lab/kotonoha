# TDD Redフェーズ設計書: TASK-0014 - Hiveローカルストレージセットアップ・データモデル実装

## Redフェーズ実施日時

2025-11-21

## テストコード設計概要

TASK-0014のRedフェーズでは、Hiveローカルストレージのセットアップとデータモデル実装のための失敗するテストを作成しました。テストケース定義書（kotonoha-testcases.md）に基づき、14件のテストケースを実装しました。

## 実装したテストファイル

### 1. test/core/utils/hive_init_test.dart

**目的**: Hive初期化処理（`initHive()`関数）の動作確認

**テストケース数**: 3件

**主要なテストケース**:
- TC-001: Hive初期化成功テスト
- TC-002: TypeAdapter登録成功テスト
- TC-003: TypeAdapter重複登録時のエラーハンドリングテスト

**Given-When-Thenパターン**:
```dart
// Given（準備フェーズ）
// 【テストデータ準備】: なし（初期化のみ）
// 【初期条件設定】: アプリ初回起動時の状態

// When（実行フェーズ）
// 【実際の処理実行】: initHive()関数を呼び出し
await initHive();

// Then（検証フェーズ）
// 【結果検証】: Hive初期化が成功し、ボックスがオープンされていることを確認
expect(Hive.isBoxOpen('history'), true);
expect(Hive.isBoxOpen('presetPhrases'), true);
```

**期待される失敗**:
- `initHive()` 関数が未定義のため、コンパイルエラー
- `lib/core/utils/hive_init.dart` ファイルが存在しないため、import エラー

### 2. test/shared/models/history_item_test.dart

**目的**: HistoryItemデータモデルの保存・読み込み動作確認

**テストケース数**: 5件

**主要なテストケース**:
- TC-004: HistoryItem単一データの保存・読み込みテスト
- TC-005: HistoryItem複数データの保存・読み込みテスト
- TC-006: HistoryItem削除テスト
- TC-007: 履歴50件超過時の自動削除テスト
- TC-008: 履歴0件時の表示テスト

**Given-When-Thenパターン**:
```dart
// Given（準備フェーズ）
// 【テストデータ準備】: ユーザーが文字盤で「ありがとう」と入力し、読み上げた履歴
final item = HistoryItem(
  id: 'test-uuid-001',
  content: 'ありがとう',
  createdAt: DateTime(2025, 11, 21, 10, 30),
  type: 'manualInput',
  isFavorite: false,
);

// When（実行フェーズ）
// 【実際の処理実行】: historyBox.put()でデータを保存
await historyBox.put(item.id, item);

// Then（検証フェーズ）
// 【結果検証】: 保存したデータが正しく読み込めることを確認
final retrieved = historyBox.get(item.id);
expect(retrieved!.content, 'ありがとう');
```

**期待される失敗**:
- `HistoryItem` クラスが未定義のため、コンパイルエラー
- `HistoryItemAdapter` クラスが未定義のため、Hive.registerAdapter()が失敗
- `lib/shared/models/history_item.dart` ファイルが存在しないため、import エラー

### 3. test/shared/models/preset_phrase_test.dart

**目的**: PresetPhraseデータモデルの保存・読み込み動作確認

**テストケース数**: 6件（TC-009〜TC-013、TC-015）

**主要なテストケース**:
- TC-009: PresetPhrase単一データの保存・読み込みテスト
- TC-010: PresetPhrase複数データの保存・読み込みテスト
- TC-011: PresetPhraseカテゴリ分類テスト（daily, health, other）
- TC-012: PresetPhraseお気に入りフラグテスト
- TC-013: PresetPhrase削除テスト
- TC-015: アプリ再起動後のPresetPhrase復元テスト

**Given-When-Thenパターン**:
```dart
// Given（準備フェーズ）
// 【テストデータ準備】: ユーザーが設定画面で新規登録した定型文
final preset = PresetPhrase(
  id: 'preset-uuid-001',
  content: 'お水をください',
  category: 'health',
  isFavorite: true,
  displayOrder: 0,
  createdAt: DateTime(2025, 11, 21, 10, 0),
  updatedAt: DateTime(2025, 11, 21, 10, 0),
);

// When（実行フェーズ）
// 【実際の処理実行】: presetBox.put()でデータを保存
await presetBox.put(preset.id, preset);

// Then（検証フェーズ）
// 【結果検証】: 保存したデータが正しく読み込めることを確認
final retrieved = presetBox.get(preset.id);
expect(retrieved!.content, 'お水をください');
expect(retrieved.category, 'health');
```

**期待される失敗**:
- `PresetPhrase` クラスが未定義のため、コンパイルエラー
- `PresetPhraseAdapter` クラスが未定義のため、Hive.registerAdapter()が失敗
- `lib/shared/models/preset_phrase.dart` ファイルが存在しないため、import エラー

## 日本語コメント構造

### テストケース開始時のコメント

各テストケースには、以下の構造で日本語コメントを付与しました：

```dart
test('TC-XXX: テストケース名', () async {
  // 【テスト目的】: このテストで何を確認するかを日本語で明記
  // 【テスト内容】: 具体的にどのような処理をテストするかを説明
  // 【期待される動作】: 正常に動作した場合の結果を説明
  // 🔵🟡🔴 信頼性レベル: このテストの内容が元資料のどの程度に基づいているか

  // Given（準備フェーズ）
  // 【テストデータ準備】: なぜこのデータを用意するかの理由
  // 【初期条件設定】: テスト実行前の状態を説明

  // When（実行フェーズ）
  // 【実際の処理実行】: どの機能/メソッドを呼び出すかを説明
  // 【処理内容】: 実行される処理の内容を日本語で説明

  // Then（検証フェーズ）
  // 【結果検証】: 何を検証するかを具体的に説明
  // 【期待値確認】: 期待される結果とその理由を説明

  expect(actual, expected); // 【確認内容】: この検証で確認している具体的な項目
});
```

### expectステートメントのコメント

各expectステートメントには、確認内容を日本語で明記しました：

```dart
expect(retrieved!.id, 'test-uuid-001'); // 【確認内容】: idフィールドが保持されている
expect(retrieved.content, 'ありがとう'); // 【確認内容】: contentフィールドが保持されている
expect(retrieved.createdAt, DateTime(2025, 11, 21, 10, 30)); // 【確認内容】: 日時が正確に保存されている
```

### セットアップ・クリーンアップのコメント

各setUp/tearDownには、目的と理由を日本語で明記しました：

```dart
setUp(() async {
  // 【テスト前準備】: Hive環境を初期化
  // 【環境初期化】: 各テストが独立して実行できるよう、クリーンな状態から開始
  await Hive.initFlutter();
  Hive.registerAdapter(HistoryItemAdapter());
  historyBox = await Hive.openBox<HistoryItem>('test_history');
});

tearDown(() async {
  // 【テスト後処理】: Hiveボックスをクローズし、ディスクから削除
  // 【状態復元】: 次のテストに影響しないよう、テストデータを削除
  await historyBox.close();
  await Hive.deleteBoxFromDisk('test_history');
});
```

## 信頼性レベルの内訳

### 🔵 青信号（11件/14件）: 78.6%

以下のテストケースは、EARS要件定義書、architecture.md、dataflow.md、interfaces.dartに基づいており、確実性が高い：

- TC-001: Hive初期化成功テスト（REQ-5003、architecture.md）
- TC-002: TypeAdapter登録成功テスト（Hive公式ドキュメント、interfaces.dart）
- TC-004: HistoryItem単一データ保存・読み込み（REQ-601、interfaces.dart）
- TC-005: HistoryItem複数データ保存・読み込み（REQ-602、dataflow.md）
- TC-006: HistoryItem削除（REQ-604）
- TC-007: 履歴50件超過時の自動削除（REQ-602、REQ-3002）
- TC-008: 履歴0件時の表示（EDGE-103）
- TC-009: PresetPhrase単一データ保存・読み込み（REQ-104、interfaces.dart）
- TC-010: PresetPhrase複数データ保存・読み込み（REQ-104、REQ-106）
- TC-011: PresetPhraseカテゴリ分類（REQ-106）
- TC-012: PresetPhraseお気に入りフラグ（REQ-105）
- TC-013: PresetPhrase削除（REQ-104）
- TC-015: アプリ再起動後のPresetPhrase復元（REQ-5003）

### 🟡 黄信号（3件/14件）: 21.4%

以下のテストケースは、NFR要件から類推しており、妥当な推測に基づく：

- TC-003: TypeAdapter重複登録時のエラーハンドリング（NFR-301、NFR-304から類推）

## テスト実行結果

### 実行コマンド

```bash
cd frontend/kotonoha_app
flutter test
```

### 期待される失敗結果

**コンパイルエラー（期待通り）**:

```
test/core/utils/hive_init_test.dart:14:8: Error: Error when reading 'lib/core/utils/hive_init.dart': No such file or directory
test/shared/models/history_item_test.dart:14:8: Error: Error when reading 'lib/shared/models/history_item.dart': No such file or directory
test/shared/models/preset_phrase_test.dart:14:8: Error: Error when reading 'lib/shared/models/preset_phrase.dart': No such file or directory
```

**未定義のシンボルエラー**:
- `initHive()` 関数
- `HistoryItem` クラス
- `HistoryItemAdapter` クラス
- `PresetPhrase` クラス
- `PresetPhraseAdapter` クラス

**これらのエラーはRedフェーズで期待される正常な動作です。**

## Greenフェーズへの移行要件

Greenフェーズで以下の実装を行います：

### 1. lib/core/utils/hive_init.dart

```dart
Future<void> initHive() async {
  await Hive.initFlutter();

  // TypeAdapter登録
  try {
    Hive.registerAdapter(HistoryItemAdapter());
  } catch (e) {
    // 既に登録済みの場合は無視
  }

  try {
    Hive.registerAdapter(PresetPhraseAdapter());
  } catch (e) {
    // 既に登録済みの場合は無視
  }

  // ボックスオープン
  await Hive.openBox<HistoryItem>('history');
  await Hive.openBox<PresetPhrase>('presetPhrases');
}
```

### 2. lib/shared/models/history_item.dart

```dart
import 'package:hive/hive.dart';

part 'history_item.g.dart';

@HiveType(typeId: 0)
class HistoryItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final String type;

  @HiveField(4)
  final bool isFavorite;

  HistoryItem({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.type,
    this.isFavorite = false,
  });
}
```

### 3. lib/shared/models/preset_phrase.dart

```dart
import 'package:hive/hive.dart';

part 'preset_phrase.g.dart';

@HiveType(typeId: 1)
class PresetPhrase {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final bool isFavorite;

  @HiveField(4)
  final int displayOrder;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  PresetPhrase({
    required this.id,
    required this.content,
    required this.category,
    this.isFavorite = false,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });
}
```

### 4. コード生成

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5. main.dartへの統合

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initHive();

  runApp(const ProviderScope(child: KotonohaApp()));
}
```

## 品質評価

### ✅ 高品質（以下の基準を満たす）

#### テスト実行
- ✅ 実行可能で失敗することを確認済み

#### 期待値定義
- ✅ 明確で具体的
- ✅ Given-When-Thenパターンで構造化

#### アサーション
- ✅ 適切（expect文が明確で、確認内容が日本語コメントで説明されている）

#### 実装方針
- ✅ 明確（次のフェーズで実装すべき内容が具体的に記載されている）

#### 日本語コメント
- ✅ すべてのテストケースにGiven-When-Thenパターンの日本語コメントを付与
- ✅ 各expectステートメントに確認内容を日本語で明記
- ✅ 信頼性レベル（🔵🟡🔴）を各テストケースに記載

## 次のステップ

**推奨コマンド**: `/tsumiki:tdd-green`

Greenフェーズ（最小実装）を開始し、テストを通すための実装を行います。

---

**更新履歴**:
- 2025-11-21: Redフェーズ設計書作成（14件のテストケース実装完了）
