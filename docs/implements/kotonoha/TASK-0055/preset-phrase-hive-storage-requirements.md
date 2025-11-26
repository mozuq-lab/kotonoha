# TASK-0055: 定型文ローカル保存（Hive）要件定義書

## 概要

**タスクID**: TASK-0055
**機能名**: 定型文ローカル保存（Hive）
**推定工数**: 8時間
**タスクタイプ**: TDD
**要件名**: kotonoha

## 1. 機能の概要（EARS要件定義書・設計文書ベース）

### 1.1 何をする機能か 🔵
- 定型文（PresetPhrase）をHiveデータベースに永続保存する機能
- 現在メモリ内で管理している定型文データをHiveに保存・読み込みできるようにする
- アプリ再起動後も定型文データが保持される

### 1.2 どのような問題を解決するか 🔵
- アプリ強制終了時のデータ損失を防止
- ユーザーがカスタマイズした定型文・お気に入り設定が消えないようにする
- オフラインファースト設計に基づくローカルデータ永続化

### 1.3 想定されるユーザー 🔵
- 脳梗塞・ALS・筋疾患などで発話が困難な方
- 日常的に定型文を追加・編集・お気に入り登録して利用する方

### 1.4 システム内での位置づけ 🔵
- **データ層**: Hive（ローカルデータベース）
- **状態管理層**: PresetPhraseNotifier（Riverpod StateNotifier）
- **既存実装**: PresetPhraseモデル、PresetPhraseAdapter（TASK-0054で実装済み）
- **連携先**: 定型文一覧UI、定型文管理画面

### 参照したEARS要件
- REQ-104: 定型文の追加・編集・削除機能
- REQ-5003: アプリ強制終了しても定型文・設定・履歴を失わない永続化機構
- NFR-101: 利用者の会話内容を原則として端末内にのみ保存

### 参照した設計文書
- architecture.md: オフラインファーストクライアント設計、ローカルストレージ（Hive）利用
- dataflow.md: 定型文管理フロー、状態管理フロー（Riverpod）

---

## 2. 入力・出力の仕様（EARS機能要件・TypeScript型定義ベース）

### 2.1 入力パラメータ 🔵

#### PresetPhrase モデル（既存）
```dart
class PresetPhrase {
  final String id;           // UUID形式の一意識別子
  final String content;      // 定型文の内容（最大500文字）
  final String category;     // 'daily', 'health', 'other'
  final bool isFavorite;     // お気に入りフラグ
  final int displayOrder;    // 表示順序
  final DateTime createdAt;  // 作成日時
  final DateTime updatedAt;  // 更新日時
}
```

#### CRUD操作パラメータ
| 操作 | パラメータ | 型 | 制約 |
|-----|----------|-----|------|
| 追加 | content, category | String, String | content: 1-500文字, category: 3種類のいずれか |
| 更新 | id, content?, category?, isFavorite? | String, String?, String?, bool? | idは必須、他はオプション |
| 削除 | id | String | UUID形式 |
| お気に入り切替 | id | String | UUID形式 |

### 2.2 出力値 🔵

| 操作 | 出力 | 型 | 例 |
|-----|-----|-----|-----|
| 読み込み | 定型文一覧 | List<PresetPhrase> | 70件程度のデフォルト定型文 |
| 追加 | 追加後の一覧 | List<PresetPhrase> | お気に入り順でソート済み |
| 更新 | 更新後の一覧 | List<PresetPhrase> | updatedAt自動更新 |
| 削除 | 削除後の一覧 | List<PresetPhrase> | 対象削除済み |

### 2.3 データフロー 🔵

```
[UI] → [PresetPhraseNotifier] → [Hive Box] → [ローカルファイルシステム]
                ↑                     ↓
            [状態更新] ← [データ読み込み]
```

### 参照したEARS要件
- REQ-104: CRUD操作の仕様
- EDGE-102: 定型文の文字数制限（500文字）

### 参照した設計文書
- interfaces.dart（設計仕様）: PresetPhraseエンティティ定義
- dataflow.md: 定型文管理フロー

---

## 3. 制約条件（EARS非機能要件・アーキテクチャ設計ベース）

### 3.1 パフォーマンス要件 🔵
- **定型文一覧表示**: 100件程度を1秒以内に表示（NFR-004）
- **CRUD操作応答**: 即座に状態更新、バックグラウンドで永続化

### 3.2 セキュリティ要件 🔵
- **データ保存場所**: アプリ専用領域（他アプリからアクセス不可）（NFR-101）
- **暗号化**: Hiveデフォルトの保存形式（プレーンテキストではない）

### 3.3 互換性要件 🔵
- **既存Provider互換**: PresetPhraseNotifierのインターフェースを維持
- **既存UIへの影響なし**: 定型文一覧画面、定型文管理画面がそのまま動作

### 3.4 アーキテクチャ制約 🔵
- **Hive Box名**: 'presetPhrases'（TASK-0054で定義済み）
- **TypeAdapter**: PresetPhraseAdapter（typeId: 1）（TASK-0054で実装済み）
- **初期化タイミング**: アプリ起動時のinitHive()で初期化済み

### 3.5 データベース制約 🔵
- **キー**: id（UUID文字列）
- **重複不可**: 同一idの重複登録を防止
- **トランザクション**: Hiveは自動的にトランザクション管理

### 参照したEARS要件
- NFR-001, NFR-003, NFR-004: パフォーマンス要件
- NFR-101: プライバシー・セキュリティ要件
- REQ-5003: データ永続化要件

### 参照した設計文書
- architecture.md: ローカルストレージ設計
- hive_init.dart: Hive初期化実装

---

## 4. 想定される使用例（EARSEdgeケース・データフローベース）

### 4.1 基本的な使用パターン 🔵

#### パターン1: 初回起動時のデフォルト定型文読み込み
```
1. アプリ起動
2. Hive Box をオープン
3. Box が空の場合、デフォルト定型文（70件）を投入
4. 定型文一覧を状態に設定
```

#### パターン2: 定型文の追加
```
1. ユーザーが新規定型文を入力
2. PresetPhraseNotifier.addPhrase() 呼び出し
3. 新しいPresetPhraseを生成（UUID自動付与）
4. Hive Box に保存
5. 状態更新（お気に入り順ソート）
```

#### パターン3: お気に入り切り替え
```
1. ユーザーが定型文のお気に入りボタンをタップ
2. PresetPhraseNotifier.toggleFavorite() 呼び出し
3. isFavorite フラグを反転
4. Hive Box に保存
5. 状態更新（お気に入り順でソート）
```

### 4.2 エッジケース 🟡

#### EDGE-009: 存在しないIDで更新しようとした場合
- **期待動作**: 何もしない（エラーを投げない）
- **実装**: indexWhere で-1の場合は早期リターン

#### EDGE-010: 存在しないIDで削除しようとした場合
- **期待動作**: 何もしない（エラーを投げない）
- **実装**: indexWhere で-1の場合は早期リターン

#### EDGE-HIVE-001: Hive Box オープン失敗 🟡
- **期待動作**: エラーログ出力、メモリ内での動作継続
- **実装**: try-catchでエラーハンドリング

#### EDGE-HIVE-002: ストレージ容量不足 🟡
- **期待動作**: 警告表示、古いデータ削除を提案
- **実装**: HiveError キャッチ、ユーザーへの通知

### 4.3 エラーケース 🟡

#### Hive書き込みエラー
- **期待動作**: エラーメッセージを状態に設定、UIで表示
- **実装**: try-catch、state.error に設定

#### データ整合性エラー
- **期待動作**: 状態とHive Boxの同期を再試行
- **実装**: loadPhrases() を呼び出して再読み込み

### 参照したEARS要件
- EDGE-003: ストレージ容量不足時の処理
- NFR-304: データベースエラー発生時の適切なエラーハンドリング

### 参照した設計文書
- dataflow.md: エラーハンドリングフロー、データ保存エラー処理

---

## 5. EARS要件・設計文書との対応関係

### 参照したユーザストーリー
- US-002: 定型文管理（追加・編集・削除・お気に入り）

### 参照した機能要件
- REQ-104: 定型文の追加・編集・削除機能
- REQ-105: お気に入り定型文を一覧上部に優先表示
- REQ-107: 初期データとして50-100個の汎用定型文を提供

### 参照した非機能要件
- NFR-101: 利用者の会話内容を原則として端末内にのみ保存
- NFR-004: 定型文一覧の表示（100件程度）を1秒以内に完了
- NFR-304: データベースエラー発生時の適切なエラーハンドリング

### 参照したEdgeケース
- EDGE-003: ストレージ容量不足時の処理
- EDGE-102: 定型文の文字数制限（500文字）

### 参照した受け入れ基準
- AC-PRESET-001: 定型文がHiveに保存される
- AC-PRESET-002: アプリ再起動後も定型文が保持される
- AC-PRESET-003: CRUD操作が正常動作する

### 参照した設計文書
- **アーキテクチャ**: architecture.md - ローカルストレージ設計（Hive）
- **データフロー**: dataflow.md - 定型文管理フロー、状態管理フロー
- **型定義**: preset_phrase.dart - PresetPhraseモデル定義
- **Hive設定**: hive_init.dart - Hive初期化、TypeAdapter登録

---

## 6. 実装詳細

### 6.1 実装対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `lib/features/preset_phrase/providers/preset_phrase_notifier.dart` | Hive永続化ロジック追加 |
| `lib/features/preset_phrase/data/preset_phrase_repository.dart` | 新規作成：Hive CRUD操作 |

### 6.2 実装方針 🔵

#### Repository パターンの導入
```dart
/// 定型文のHive永続化を担当するRepository
class PresetPhraseRepository {
  static const String boxName = 'presetPhrases';

  /// Hive Boxを取得
  Box<PresetPhrase> get _box => Hive.box<PresetPhrase>(boxName);

  /// 全定型文を読み込み
  Future<List<PresetPhrase>> loadAll();

  /// 定型文を保存
  Future<void> save(PresetPhrase phrase);

  /// 定型文を削除
  Future<void> delete(String id);

  /// 全定型文を保存（バルク保存）
  Future<void> saveAll(List<PresetPhrase> phrases);
}
```

#### PresetPhraseNotifier の変更
- Repositoryを注入してHive操作を委譲
- 状態更新と永続化を同期
- エラーハンドリングの追加

### 6.3 テスト要件 🔵

```dart
// TC-055-001: 定型文をHiveに保存できる
test('定型文をHiveに保存できる', () async {
  final repository = PresetPhraseRepository();
  final phrase = PresetPhrase(
    id: 'test-id',
    content: 'こんにちは',
    category: 'daily',
    isFavorite: false,
    displayOrder: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  await repository.save(phrase);
  final loaded = await repository.loadAll();

  expect(loaded.length, 1);
  expect(loaded.first.content, 'こんにちは');
});

// TC-055-002: アプリ再起動後もデータが保持される
// TC-055-003: CRUD操作が正常動作する
// TC-055-004: エラー時の適切なハンドリング
```

---

## 7. 完了条件 🔵

- [ ] 定型文がHiveに保存される
- [ ] アプリ再起動後も定型文が保持される
- [ ] CRUD操作（追加・読み取り・更新・削除）が正常動作する
- [ ] お気に入り状態がHiveに保存される
- [ ] カテゴリ情報がHiveに保存される
- [ ] Riverpod Provider統合が完了している
- [ ] エラー時の適切なハンドリングが実装されている

---

## 8. 品質判定

### ✅ 高品質
- **要件の曖昧さ**: なし - REQ-104, REQ-5003から明確に定義
- **入出力定義**: 完全 - PresetPhraseモデル、CRUD操作パラメータを詳細に定義
- **制約条件**: 明確 - パフォーマンス、セキュリティ、アーキテクチャ制約を網羅
- **実装可能性**: 確実 - TASK-0054で基盤（Hive初期化、TypeAdapter）実装済み

---

## 9. 次のステップ

次のお勧めステップ: `/tdd-testcases` でテストケースの洗い出しを行います。
